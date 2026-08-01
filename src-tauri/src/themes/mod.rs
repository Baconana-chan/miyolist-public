// ─── AnimeThemes.moe integration ─────────────────────────────────────────────
//
// Free, no-auth REST API (JSON).  Endpoint:
//   GET https://api.animethemes.moe/anime?q={query}&include=animethemes.animethemeentries.videos,animethemes.song.artists
//
// Response shape (non-standard but stable):
//   { "anime": [ { id, name, slug, media_format, year,
//                  animethemes: [ { id, type: "OP"|"ED"|"IN", sequence,
//                                   song: { title, artists: [{ name }] },
//                                   animethemeentries: [ { id, episodes, version,
//                                                          videos: [ { id, link, resolution,
//                                                                     nc, subbed, lyrics, uncen, tags } ] } ] } ] } ] }

use std::sync::OnceLock;

use reqwest::blocking::Client;
use serde::Deserialize;
use tauri::AppHandle;

use crate::models::{MediaTheme, ThemeAnime, ThemeEntry, ThemeVideo};

const API_BASE: &str = "https://api.animethemes.moe/anime";
const USER_AGENT: &str = concat!(
    "miyolist/",
    env!("CARGO_PKG_VERSION"),
    " (+https://github.com/baconana/miyolist)"
);

static THEMES_CLIENT: OnceLock<Client> = OnceLock::new();

fn client() -> &'static Client {
    THEMES_CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .user_agent(USER_AGENT)
            .build()
            .unwrap_or_else(|_| Client::new())
    })
}

// ─── Remote types ────────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct ApiEnvelope {
    anime: Vec<ApiAnime>,
}

#[derive(Deserialize, Clone)]
struct ApiAnime {
    id: i64,
    name: String,
    slug: String,
    #[serde(rename = "media_format")]
    media_format: Option<String>,
    year: Option<i64>,
    animethemes: Option<Vec<ApiTheme>>,
}

#[derive(Deserialize, Clone)]
struct ApiTheme {
    id: i64,
    #[serde(rename = "type")]
    theme_type: String,
    sequence: Option<i64>,
    song: Option<ApiSong>,
    animethemeentries: Option<Vec<ApiThemeEntry>>,
}

#[derive(Deserialize, Clone)]
struct ApiSong {
    title: Option<String>,
    artists: Option<Vec<ApiArtist>>,
}

#[derive(Deserialize, Clone)]
struct ApiArtist {
    name: Option<String>,
}

#[derive(Deserialize, Clone)]
struct ApiThemeEntry {
    id: i64,
    episodes: Option<String>,
    version: Option<i64>,
    videos: Option<Vec<ApiVideo>>,
}

#[derive(Deserialize, Clone)]
struct ApiVideo {
    id: i64,
    link: Option<String>,
    basename: Option<String>,
    resolution: Option<i64>,
    nc: Option<bool>,
    subbed: Option<bool>,
    lyrics: Option<bool>,
    uncen: Option<bool>,
    tags: Option<String>,
}

// ─── Fetching ────────────────────────────────────────────────────────────────

fn fetch_anime(query: &str) -> Result<Vec<ApiAnime>, String> {
    let response = client()
        .get(API_BASE)
        .query(&[("q", query)])
        .query(&[
            (
                "include",
                "animethemes.animethemeentries.videos,animethemes.song.artists",
            ),
        ])
        .send()
        .map_err(|e| format!("[THEMES_NETWORK_ERROR] AnimeThemes request failed: {e}"))?;

    if !response.status().is_success() {
        let status = response.status();
        return Err(format!("[THEMES_HTTP_ERROR] AnimeThemes returned HTTP {status}"));
    }

    let parsed: ApiEnvelope = response
        .json()
        .map_err(|e| format!("[THEMES_PARSE_ERROR] Failed to decode AnimeThemes response: {e}"))?;
    Ok(parsed.anime)
}

fn api_anime_to_model(anime: ApiAnime) -> ThemeAnime {
    let themes = anime
        .animethemes
        .unwrap_or_default()
        .into_iter()
        .map(|t| {
            let entries = t
                .animethemeentries
                .unwrap_or_default()
                .into_iter()
                .map(|e| ThemeEntry {
                    id: e.id,
                    episodes: e.episodes,
                    version: e.version,
                    videos: e
                        .videos
                        .unwrap_or_default()
                        .into_iter()
                        .filter_map(|v| {
                            let link = v.link?;
                            Some(ThemeVideo {
                                id: v.id,
                                link,
                                basename: v.basename,
                                resolution: v.resolution,
                                nc: v.nc.unwrap_or(false),
                                subbed: v.subbed.unwrap_or(false),
                                lyrics: v.lyrics.unwrap_or(false),
                                uncen: v.uncen.unwrap_or(false),
                                tags: v.tags,
                            })
                        })
                        .collect(),
                })
                .collect();
            MediaTheme {
                id: t.id,
                theme_type: t.theme_type,
                sequence: t.sequence,
                song_title: t
                    .song
                    .as_ref()
                    .and_then(|s| s.title.clone())
                    .unwrap_or_else(|| "Unknown".into()),
                artists: t
                    .song
                    .as_ref()
                    .and_then(|s| {
                        s.artists.as_ref().map(|artists| {
                            artists
                                .iter()
                                .filter_map(|a| a.name.clone())
                                .collect::<Vec<_>>()
                        })
                    })
                    .unwrap_or_default(),
                entries,
            }
        })
        .collect();

    ThemeAnime {
        id: anime.id,
        name: anime.name,
        slug: anime.slug,
        media_format: anime.media_format,
        year: anime.year,
        themes,
    }
}

/// Search AnimeThemes.moe by anime title.  Returns anime matches (each with its
/// OP/ED theme list), best matches first.  An empty query returns no results.
pub fn search_themes(query: &str) -> Result<Vec<ThemeAnime>, String> {
    let trimmed = query.trim();
    if trimmed.is_empty() {
        return Ok(Vec::new());
    }
    Ok(fetch_anime(trimmed)?
        .into_iter()
        .map(api_anime_to_model)
        .collect())
}

/// Fetch themes for a media entry by its *local* title (from `media_cache`),
/// since AnimeThemes is keyed by title/slug rather than AniList id.  Picks the
/// best-matching anime (exact name hit first, then case-insensitive contains).
pub fn get_themes_for_media(app: &AppHandle, media_id: i64) -> Result<Vec<MediaTheme>, String> {
    let title = crate::db::get_cached_media_title(app, media_id)?;
    let query = title.trim();
    if query.is_empty() {
        return Ok(Vec::new());
    }

    let results = fetch_anime(query)?;
    if results.is_empty() {
        return Ok(Vec::new());
    }

    let lower = query.to_lowercase();
    // Exact match on the anime name first, then first result as fallback.
    let chosen = results
        .iter()
        .find(|a| a.name.to_lowercase() == lower)
        .or_else(|| results.first())
        .cloned();

    Ok(chosen.map(api_anime_to_model).map(|a| a.themes).unwrap_or_default())
}
