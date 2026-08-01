//! MangaUpdates release tracking (new-chapter notifications).
//!
//! MangaUpdates (mangaupdates.com) is a *release indexer* — it does not host
//! chapters, it merely records who released what and when.  That makes it a
//! great notification source: unlike MangaDex (which became a company and
//! mass-removed titles), MangaUpdates coverage is driven by scanlator groups
//! and its API is public, no auth, with a per-series RSS feed.
//!
//! Verified live against api.mangaupdates.com:
//! - `POST /v1/series/search`  `{"search": "<title>", "perpage": N}` → series
//!   records with `series_id`, `title`, `url`, `type`, `year`.
//! - `GET  /v1/series/{id}/rss` → RSS 2.0, newest first, `<item><title>Title
//!   c.147</title><description>Group name</description></item>`.
//!
//! # Tracking model
//!
//! The user's manga entries with `CURRENT`/`REPEATING` status are polled on a
//! timer.  Each entry is linked to a MangaUpdates series id either
//! automatically (`resolve_series`, best-effort title matching that skips
//! doujinshi/anthology noise) or manually by the user from Settings.  The link
//! plus a high-water mark (last notified RSS item title) live in the
//! `manga_release_cache` table.

use std::sync::{Mutex, OnceLock};

use reqwest::blocking::Client;
use serde::Deserialize;
use tauri::AppHandle;
use tauri_plugin_notification::NotificationExt;

use crate::models::MangaUpdatesSeries;

const API_BASE: &str = "https://api.mangaupdates.com/v1";
const USER_AGENT: &str = concat!(
    "miyolist/",
    env!("CARGO_PKG_VERSION"),
    " (+https://github.com/baconana/miyolist)"
);

/// Conservative pacing between per-series requests to stay well inside
/// MangaUpdates' undocumented rate limits (the site 429s quickly when scraped
/// directly; the API is friendlier but should still be treated gently).
const REQUEST_PACING_MS: u64 = 600;

static MU_CLIENT: OnceLock<Client> = OnceLock::new();

/// Serialises polls.  Polling is fired from several independent entry points
/// (the startup thread, the AppShell boot/reconnect hooks, the background
/// auto-sync timer, and the Settings "check now" button), and a poll for many
/// tracked series takes tens of seconds — two overlapping polls would both
/// read the same high-water mark and fire duplicate notifications.
static POLL_LOCK: Mutex<()> = Mutex::new(());

fn client() -> &'static Client {
    MU_CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(std::time::Duration::from_secs(15))
            .user_agent(USER_AGENT)
            .build()
            .unwrap_or_else(|_| Client::new())
    })
}

// ─── Remote types ────────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct SearchEnvelope {
    results: Vec<SearchHit>,
}

#[derive(Deserialize)]
struct SearchHit {
    record: ApiSeriesRecord,
}

#[derive(Deserialize)]
struct ApiSeriesRecord {
    series_id: i64,
    title: String,
    url: String,
    #[serde(rename = "type")]
    series_type: Option<String>,
    year: Option<String>,
}

/// One release entry parsed from the per-series RSS feed.
#[derive(Debug, Clone, Default)]
struct RssItem {
    title: String,
    group: String,
}

// ─── Series search & resolution ──────────────────────────────────────────────

/// Search MangaUpdates by title (public API, no auth).  Returns the raw
/// matches, best guess first — used by both auto-resolution and the manual
/// "replace link" UI in Settings.
pub fn search_series(query: &str) -> Result<Vec<MangaUpdatesSeries>, String> {
    let trimmed = query.trim();
    if trimmed.is_empty() {
        return Ok(Vec::new());
    }

    let response = client()
        .post(format!("{API_BASE}/series/search"))
        .json(&serde_json::json!({ "search": trimmed, "perpage": 12 }))
        .send()
        .map_err(|e| format!("[MU_NETWORK_ERROR] MangaUpdates search failed: {e}"))?;

    if !response.status().is_success() {
        let status = response.status();
        return Err(format!("[MU_HTTP_ERROR] MangaUpdates returned HTTP {status}"));
    }

    let parsed: SearchEnvelope = response
        .json()
        .map_err(|e| format!("[MU_PARSE_ERROR] Failed to decode MangaUpdates search: {e}"))?;

    Ok(parsed
        .results
        .into_iter()
        .map(|hit| MangaUpdatesSeries {
            series_id: hit.record.series_id,
            title: hit.record.title,
            url: hit.record.url,
            series_type: hit.record.series_type,
            year: hit.record.year,
        })
        .collect())
}

/// Titles that are almost never the actual series the user means when we look
/// up a manga by its AniList title: doujinshi spin-offs, anthologies, etc.
fn is_noise_title(title: &str) -> bool {
    let lower = title.to_lowercase();
    lower.contains("dj -")
        || lower.contains("dj-")
        || lower.contains("anthology")
        || lower.contains("doujinshi")
        || lower.contains("he no nawa")
}

/// Best-effort mapping from an AniList manga title to a MangaUpdates series.
/// Exact title match wins; then case-insensitive contains; then first result.
/// Doujinshi/anthology noise is filtered out entirely.  Returns
/// `(series_id, series_title)` when something usable is found.
pub fn resolve_series(title: &str) -> Option<(i64, String)> {
    let results = search_series(title).ok()?;
    if results.is_empty() {
        return None;
    }

    let lower = title.to_lowercase();
    let clean: Vec<&MangaUpdatesSeries> = results
        .iter()
        .filter(|s| !is_noise_title(&s.title))
        .collect();

    let exact = clean
        .iter()
        .find(|s| s.title.to_lowercase() == lower);
    if let Some(series) = exact {
        return Some((series.series_id, series.title.clone()));
    }

    let contains = clean
        .iter()
        .find(|s| s.title.to_lowercase().contains(&lower) || lower.contains(&s.title.to_lowercase()));
    if let Some(series) = contains {
        return Some((series.series_id, series.title.clone()));
    }

    // Last resort: first clean result (search relevance ordering).
    clean.first().map(|s| (s.series_id, s.title.clone()))
}

// ─── RSS feed ────────────────────────────────────────────────────────────────

/// Fetches and parses the per-series RSS feed (newest first).
fn fetch_series_releases(series_id: i64) -> Result<Vec<RssItem>, String> {
    let response = client()
        .get(format!("{API_BASE}/series/{series_id}/rss"))
        .send()
        .map_err(|e| format!("[MU_NETWORK_ERROR] MangaUpdates RSS failed: {e}"))?;

    if !response.status().is_success() {
        let status = response.status();
        return Err(format!("[MU_HTTP_ERROR] MangaUpdates RSS returned HTTP {status}"));
    }

    let xml = response
        .text()
        .map_err(|e| format!("[MU_PARSE_ERROR] Failed to read RSS body: {e}"))?;
    Ok(parse_rss(&xml))
}

/// Minimal RSS 2.0 parser — pulls `title` and `description` (scanlator group)
/// out of each `<item>`.  Uses quick-xml so self-closing tags, CDATA and
/// entity escapes are handled properly.
fn parse_rss(xml: &str) -> Vec<RssItem> {
    let mut items = Vec::new();
    let mut current: RssItem = RssItem { title: String::new(), group: String::new() };
    let mut in_item = false;
    let mut in_title = false;
    let mut in_desc = false;

    let mut reader = quick_xml::Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    loop {
        match reader.read_event() {
            Ok(quick_xml::events::Event::Start(e)) | Ok(quick_xml::events::Event::Empty(e)) => {
                match e.name().as_ref() {
                    b"item" => {
                        in_item = true;
                        current = RssItem { title: String::new(), group: String::new() };
                    }
                    b"title" if in_item => in_title = true,
                    b"description" if in_item => in_desc = true,
                    _ => {}
                }
            }
            Ok(quick_xml::events::Event::Text(t)) => {
                // BytesText and BytesCData are different types, so the arms
                // cannot share an OR-pattern binding.  Text is entity-escaped
                // (unescape), CDATA is already raw (decode).
                let text = t.unescape().unwrap_or_default().to_string();
                if in_item && !text.is_empty() {
                    if in_title {
                        current.title.push_str(&text);
                    } else if in_desc {
                        current.group.push_str(&text);
                    }
                }
            }
            Ok(quick_xml::events::Event::CData(t)) => {
                // CDATA content is already unescaped raw text — `decode()`
                // turns the raw bytes into a string (no entity handling).
                let text = t.decode().unwrap_or_default().to_string();
                if in_item && !text.is_empty() {
                    if in_title {
                        current.title.push_str(&text);
                    } else if in_desc {
                        current.group.push_str(&text);
                    }
                }
            }
            Ok(quick_xml::events::Event::End(e)) => match e.name().as_ref() {
                b"item" => {
                    in_item = false;
                    if !current.title.is_empty() {
                        items.push(std::mem::take(&mut current));
                    }
                }
                b"title" => in_title = false,
                b"description" => in_desc = false,
                _ => {}
            },
            Ok(quick_xml::events::Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
    }

    items
}

// ─── Polling ─────────────────────────────────────────────────────────────────

/// Polls every tracked manga for new releases and fires one OS notification per
/// new chapter/volume item (respecting the global toggle, per-media mutes, and
/// the high-water mark so the first poll after enabling doesn't spam history).
///
/// Returns the number of notifications sent.  Best-effort — per-series
/// network/parse errors are logged and skipped.
pub fn poll_manga_releases(app: &AppHandle) -> Result<i64, String> {
    // Skip if another poll is already in flight (e.g. the startup thread while
    // a background-sync poll is still running) — its result is identical.
    let _guard = match POLL_LOCK.try_lock() {
        Ok(guard) => guard,
        Err(_) => return Ok(0),
    };

    let settings = crate::db::get_notification_settings(app)?;
    if !settings.manga_releases_enabled {
        return Ok(0);
    }
    if !crate::anilist::is_online() {
        return Ok(0);
    }

    let tracked = crate::db::get_tracked_manga(app)?;
    let mut sent = 0i64;

    for (media_id, media_type, title, cover_url) in tracked {
        // Ensure a link exists (auto-resolve on first pass; skip failures so
        // the user can fix them manually from Settings).
        let mapping = crate::db::get_manga_release_mapping(app, media_id)?;
        let series_id = match mapping.as_ref().and_then(|m| m.mu_series_id) {
            Some(id) => id,
            None => {
                match resolve_series(&title) {
                    Some((id, mu_title)) => {
                        let _ = crate::db::set_manga_release_mapping(
                            app,
                            media_id,
                            &media_type,
                            id,
                            &mu_title,
                            false,
                        );
                        id
                    }
                    None => {
                        eprintln!("[MANGA_RELEASES] Could not auto-link \"{title}\" on MangaUpdates");
                        continue;
                    }
                }
            }
        };

        // Don't notify for entries the user manually muted.
        if crate::db::is_manga_release_muted(app, media_id)? {
            continue;
        }

        let items = match fetch_series_releases(series_id) {
            Ok(items) => items,
            Err(e) => {
                eprintln!("[MANGA_RELEASES] {e}");
                continue;
            }
        };
        if items.is_empty() {
            continue;
        }

        // High-water mark: items are newest-first, so everything before the
        // stored mark is new.  On the very first poll (no mark) we only anchor
        // the baseline and do NOT notify — otherwise enabling the feature would
        // spam the entire release history.
        let mark = mapping.as_ref().and_then(|m| m.last_item_title.clone());
        let new_items: Vec<&RssItem> = match &mark {
            Some(mark_title) => {
                if let Some(pos) = items.iter().position(|item| item.title == *mark_title) {
                    items[..pos].iter().collect()
                } else {
                    // Mark not found in the feed (release edited/removed or
                    // title format changed) — re-anchor without spamming.
                    Vec::new()
                }
            }
            None => Vec::new(),
        };

        // Always anchor the high-water mark to the newest item — on the first
        // poll this records the baseline, on later polls it advances past the
        // releases that were just notified.  Note: when more than 3 releases
        // piled up since the last poll, only the 3 newest are surfaced and the
        // mark still jumps to the newest — the rest are intentionally skipped
        // to avoid notification spam.
        let _ = crate::db::update_manga_release_mark(app, media_id, &items[0].title);

        for item in new_items.into_iter().take(3) {
            if sent >= 3 {
                break;
            }
            let icon = cover_url
                .as_deref()
                .and_then(|url| crate::cache::get_cached_image_path(app, url).ok().flatten());
            let body = if item.group.is_empty() {
                "New chapter released".to_string()
            } else {
                format!("New chapter by {}", item.group)
            };
            let mut builder = app.notification().builder().title(&item.title).body(&body);
            if let Some(icon) = icon.as_deref() {
                builder = builder.icon(icon);
            }
            if builder.show().is_ok() {
                sent += 1;
            }
        }

        // Be polite to the API between series.
        std::thread::sleep(std::time::Duration::from_millis(REQUEST_PACING_MS));
    }

    Ok(sent)
}
