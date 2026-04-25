pub mod remote_types;
use remote_types::*;

use std::{
    collections::{HashSet, VecDeque},
    env,
    sync::{Mutex, OnceLock},
    time::{Duration, Instant},
};

use reqwest::blocking::Client;
use rusqlite::{Connection, OptionalExtension};
use serde_json::{json, Value};
use tauri::AppHandle;

use crate::models::{
    ActivityReplyItem, AniListConfigStatus, AniListNotificationItem, AniListViewer,
    AuthSessionStatus, CharacterDetails, CharacterMedia, FavoriteMedia, FavoritePerson,
    FavoriteStudio, FollowingActivityItem, FoundationModule, GlobalAiringEntry, PersonSearchResult,
    SocialUser, StaffCharacter, StaffDetails, StudioDetails, StudioMedia, StudioSearchResult,
    SyncProgress, SyncSummary, UserFavorites, UserMediaListItem, UserProfile, UserProfileStats,
    UserSearchResult,
};

const DEFAULT_AUTH_URL: &str = "https://anilist.co/api/v2/oauth/authorize";
const DEFAULT_TOKEN_URL: &str = "https://anilist.co/api/v2/oauth/token";
const DEFAULT_GRAPHQL_URL: &str = "https://graphql.anilist.co";

const VAR_CLIENT_ID: &str = "ANILIST_CLIENT_ID";
const VAR_CLIENT_SECRET: &str = "ANILIST_CLIENT_SECRET";
const VAR_AUTH_URL: &str = "ANILIST_AUTH_URL";
const VAR_TOKEN_URL: &str = "ANILIST_TOKEN_URL";
const VAR_GRAPHQL_URL: &str = "ANILIST_GRAPHQL_URL";

// Compile-time fallbacks for release builds produced in CI.
// If runtime env/.env is missing on an end-user machine, these values allow
// the app to keep working with the configuration baked into the binary.
const BUILD_CLIENT_ID: Option<&str> = option_env!("ANILIST_CLIENT_ID");
const BUILD_CLIENT_SECRET: Option<&str> = option_env!("ANILIST_CLIENT_SECRET");
const BUILD_AUTH_URL: Option<&str> = option_env!("ANILIST_AUTH_URL");
const BUILD_TOKEN_URL: Option<&str> = option_env!("ANILIST_TOKEN_URL");
const BUILD_GRAPHQL_URL: Option<&str> = option_env!("ANILIST_GRAPHQL_URL");

/// AniList currently throttles clients to 30 requests per minute (down from
/// the historical 90).  We cap our local sliding window a few requests below
/// that to leave headroom for in-flight requests that haven't yet been counted
/// by the server, plus any concurrent calls from background sync.
const RATE_LIMIT_MAX: usize = 28;
const RATE_LIMIT_WINDOW: Duration = Duration::from_secs(60);
/// Max retries on 429 / 5xx responses (in addition to the first attempt).
const MAX_RETRIES: u32 = 3;
/// Hard ceiling on how long a single 429 back-off may sleep, so a hostile or
/// buggy `Retry-After` value can't wedge a request for hours.
const MAX_RETRY_AFTER_SECS: u64 = 120;

// ─── OS keyring ───────────────────────────────────────────────────────────────

const KEYRING_SERVICE: &str = "miyolist";
const KEYRING_ACCOUNT: &str = "anilist_access_token";

/// Store the token in the OS credential store (Windows Credential Manager,
/// macOS Keychain, libsecret on Linux).  A failure is non-fatal; the caller
/// should fall back to SQLite storage so auth still completes.
fn keyring_store(token: &str) -> Result<(), String> {
    keyring::Entry::new(KEYRING_SERVICE, KEYRING_ACCOUNT)
        .map_err(|e| format!("[STORAGE_ERROR] OS keyring unavailable: {e}"))?
        .set_password(token)
        .map_err(|e| format!("[STORAGE_ERROR] Failed to write token to OS keyring: {e}"))
}

/// Read the token from the OS credential store.  Returns `None` if the entry
/// does not exist or the keyring is unavailable (e.g. headless CI).
fn keyring_read() -> Option<String> {
    keyring::Entry::new(KEYRING_SERVICE, KEYRING_ACCOUNT)
        .ok()
        .and_then(|entry| entry.get_password().ok())
        .filter(|t| !t.is_empty())
}

/// Remove the token from the OS credential store.  Failures are silently
/// ignored because the DB clear that follows is the authoritative step.
fn keyring_delete() {
    if let Ok(entry) = keyring::Entry::new(KEYRING_SERVICE, KEYRING_ACCOUNT) {
        let _ = entry.delete_credential();
    }
}

// ─── Shared HTTP client ───────────────────────────────────────────────────────

static HTTP_CLIENT: OnceLock<Client> = OnceLock::new();
static ONLINE_PROBE_CLIENT: OnceLock<Client> = OnceLock::new();

fn http_client() -> &'static Client {
    HTTP_CLIENT.get_or_init(Client::new)
}

fn online_probe_client() -> &'static Client {
    ONLINE_PROBE_CLIENT.get_or_init(|| {
        Client::builder()
            .timeout(Duration::from_secs(3))
            .build()
            .unwrap_or_else(|_| Client::new())
    })
}

pub fn is_online() -> bool {
    match online_probe_client().head("https://anilist.co").send() {
        Ok(response) => {
            response.status().is_success()
                || response.status().is_redirection()
                || response.status().as_u16() == 405
        }
        Err(_) => false,
    }
}

// ─── Sync progress (UI feedback for long syncs) ──────────────────────────────

static SYNC_PROGRESS: OnceLock<Mutex<SyncProgress>> = OnceLock::new();

fn sync_progress_cell() -> &'static Mutex<SyncProgress> {
    SYNC_PROGRESS.get_or_init(|| Mutex::new(SyncProgress::default()))
}

/// Snapshot the current sync progress for the frontend.  Cheap; safe to poll
/// from a setInterval while a sync command is awaiting.
pub fn get_sync_progress() -> SyncProgress {
    sync_progress_cell()
        .lock()
        .map(|g| g.clone())
        .unwrap_or_default()
}

fn update_sync_progress<F: FnOnce(&mut SyncProgress)>(mutate: F) {
    if let Ok(mut g) = sync_progress_cell().lock() {
        mutate(&mut *g);
    }
}

fn begin_sync_progress(initial_phase: &str) {
    update_sync_progress(|p| {
        *p = SyncProgress {
            active: true,
            phase: initial_phase.to_string(),
            page: 0,
            entries: 0,
            total_entries: 0,
            message: format!("Starting sync · {initial_phase}"),
        };
    });
}

fn end_sync_progress() {
    update_sync_progress(|p| {
        p.active = false;
        p.message = String::new();
    });
}

/// RAII guard that flips `SyncProgress.active = false` when dropped, so the
/// frontend's poll always sees an inactive state once `sync_lists_smart`
/// returns — including on the early-return path that propagates a pull
/// error.
struct SyncProgressGuard;

impl Drop for SyncProgressGuard {
    fn drop(&mut self) {
        end_sync_progress();
    }
}

// ─── Rate limiter ─────────────────────────────────────────────────────────────

static RATE_LIMITER: OnceLock<Mutex<VecDeque<Instant>>> = OnceLock::new();

fn rate_limiter() -> &'static Mutex<VecDeque<Instant>> {
    RATE_LIMITER.get_or_init(|| Mutex::new(VecDeque::new()))
}

/// Acquire a rate-limit slot before issuing a GraphQL request.
/// Blocks if the sliding-window bucket is full.
fn rate_limit_acquire() {
    let mut q = rate_limiter().lock().unwrap_or_else(|p| p.into_inner());
    let now = Instant::now();

    // Evict timestamps older than the window.
    while q
        .front()
        .map(|t: &Instant| now.duration_since(*t) >= RATE_LIMIT_WINDOW)
        .unwrap_or(false)
    {
        q.pop_front();
    }

    // If the bucket is full, sleep until the oldest slot expires.
    if q.len() >= RATE_LIMIT_MAX {
        if let Some(&oldest) = q.front() {
            let wake_at = oldest + RATE_LIMIT_WINDOW + Duration::from_millis(50);
            let wait = wake_at.saturating_duration_since(Instant::now());
            drop(q); // Release lock while sleeping.
            std::thread::sleep(wait);
            q = rate_limiter().lock().unwrap_or_else(|p| p.into_inner());
            let now2 = Instant::now();
            while q
                .front()
                .map(|t: &Instant| now2.duration_since(*t) >= RATE_LIMIT_WINDOW)
                .unwrap_or(false)
            {
                q.pop_front();
            }
        }
    }

    q.push_back(Instant::now());
}

// ─── Central GraphQL transport ───────────────────────────────────────────────

/// Execute a single GraphQL request with rate limiting and automatic retry on
/// transient errors (429 Too Many Requests, 5xx server errors).
///
/// Returns the `data` field of the GQL envelope on success, or a prefixed
/// error string that the frontend can inspect to distinguish failure modes.
fn graphql_post<T: serde::de::DeserializeOwned>(
    graphql_url: &str,
    access_token: &str,
    body: &serde_json::Value,
) -> Result<T, String> {
    let mut last_err = String::new();

    for attempt in 0..=MAX_RETRIES {
        rate_limit_acquire();

        let response = http_client()
            .post(graphql_url)
            .bearer_auth(access_token)
            .json(body)
            .send()
            .map_err(|e| format!("[NETWORK_ERROR] AniList request failed: {e}"))?;

        let status = response.status();

        if status.as_u16() == 429 {
            // Honour AniList's `Retry-After` header (seconds) when present,
            // falling back to a 60s sleep — the documented window for the
            // 30 req/min bucket.  Cap to MAX_RETRY_AFTER_SECS so a malformed
            // header can't stall the app indefinitely.
            let retry_after = response
                .headers()
                .get(reqwest::header::RETRY_AFTER)
                .and_then(|v| v.to_str().ok())
                .and_then(|s| s.trim().parse::<u64>().ok())
                .map(|s| s.clamp(1, MAX_RETRY_AFTER_SECS))
                .unwrap_or(60);
            last_err = format!(
                "[RATE_LIMITED] AniList rate limit reached (attempt {})",
                attempt + 1
            );
            eprintln!("{last_err} — waiting {retry_after}s");
            // Penalise our local sliding window so subsequent calls in this
            // process also back off, not just the retry of *this* request.
            // We mark the queue as "full of recent timestamps" by pushing
            // RATE_LIMIT_MAX entries dated `now`, which forces the next
            // `rate_limit_acquire` to wait the full window.
            {
                let mut q = rate_limiter().lock().unwrap_or_else(|p| p.into_inner());
                q.clear();
                let stamp = Instant::now();
                for _ in 0..RATE_LIMIT_MAX {
                    q.push_back(stamp);
                }
            }
            std::thread::sleep(Duration::from_secs(retry_after));
            continue;
        }

        if status.is_server_error() && attempt < MAX_RETRIES {
            last_err = format!(
                "[SERVER_ERROR] AniList returned HTTP {status} (attempt {})",
                attempt + 1
            );
            eprintln!("{last_err} — retrying in {}s", 2u64.pow(attempt));
            std::thread::sleep(Duration::from_secs(2u64.pow(attempt)));
            continue;
        }

        if !status.is_success() {
            let body_text = response.text().unwrap_or_default();
            return Err(format!(
                "[HTTP_ERROR] AniList returned HTTP {status}: {body_text}"
            ));
        }

        // Read body as text first so a parse failure can include a snippet of
        // the actual response — invaluable when AniList changes a field shape.
        let body_text = response
            .text()
            .map_err(|e| format!("[NETWORK_ERROR] Failed to read AniList response body: {e}"))?;
        let parsed: GraphQlResponse<T> = serde_json::from_str(&body_text).map_err(|e| {
            let snippet: String = body_text.chars().take(500).collect();
            format!("[PARSE_ERROR] Failed to decode AniList response: {e} | body: {snippet}")
        })?;

        if let Some(errors) = parsed.errors {
            let msg = errors
                .into_iter()
                .map(|e| e.message)
                .collect::<Vec<_>>()
                .join("; ");
            return Err(format!("[GRAPHQL_ERROR] {msg}"));
        }

        return parsed
            .data
            .ok_or_else(|| "[EMPTY_RESPONSE] AniList returned no data".to_string());
    }

    Err(last_err)
}

#[derive(Clone)]
pub struct AniListConfig {
    pub client_id: String,
    pub client_secret: Option<String>,
    pub auth_url: String,
    pub token_url: String,
    pub graphql_url: String,
    pub uses_env_file: bool,
}

#[derive(Clone)]
pub struct AniListPublicConfig {
    pub client_id: String,
    pub auth_url: String,
}

pub fn foundation_summary() -> FoundationModule {
    FoundationModule {
        name: "AniList API".into(),
        summary: "Env-backed AniList config, GraphQL transport foundation, and viewer query bootstrap are in place.".into(),
        status: "ready".into(),
    }
}

pub fn config_status() -> AniListConfigStatus {
    let config = load_config().ok();
    let mut missing_vars = Vec::new();

    let client_id_configured = config
        .as_ref()
        .map(|value| !value.client_id.trim().is_empty())
        .unwrap_or(false);
    if !client_id_configured {
        missing_vars.push(VAR_CLIENT_ID.into());
    }

    let client_secret_configured = config
        .as_ref()
        .and_then(|value| value.client_secret.clone())
        .map(|value| !value.trim().is_empty())
        .unwrap_or(false);
    if !client_secret_configured {
        missing_vars.push(VAR_CLIENT_SECRET.into());
    }

    AniListConfigStatus {
        client_id_configured,
        client_secret_configured,
        auth_url: config
            .as_ref()
            .map(|value| value.auth_url.clone())
            .unwrap_or_else(|| DEFAULT_AUTH_URL.into()),
        token_url: config
            .as_ref()
            .map(|value| value.token_url.clone())
            .unwrap_or_else(|| DEFAULT_TOKEN_URL.into()),
        graphql_url: config
            .as_ref()
            .map(|value| value.graphql_url.clone())
            .unwrap_or_else(|| DEFAULT_GRAPHQL_URL.into()),
        uses_env_file: config
            .as_ref()
            .map(|value| value.uses_env_file)
            .unwrap_or(false),
        missing_vars,
    }
}

pub fn load_config() -> Result<AniListConfig, String> {
    let uses_env_file = dotenvy::dotenv().is_ok();
    let client_id =
        env_or_build(VAR_CLIENT_ID, BUILD_CLIENT_ID).ok_or_else(|| missing_var(VAR_CLIENT_ID))?;
    let client_secret = env_or_build(VAR_CLIENT_SECRET, BUILD_CLIENT_SECRET);

    Ok(AniListConfig {
        client_id,
        client_secret,
        auth_url: env_or_build(VAR_AUTH_URL, BUILD_AUTH_URL)
            .unwrap_or_else(|| DEFAULT_AUTH_URL.into()),
        token_url: env_or_build(VAR_TOKEN_URL, BUILD_TOKEN_URL)
            .unwrap_or_else(|| DEFAULT_TOKEN_URL.into()),
        graphql_url: env_or_build(VAR_GRAPHQL_URL, BUILD_GRAPHQL_URL)
            .unwrap_or_else(|| DEFAULT_GRAPHQL_URL.into()),
        uses_env_file,
    })
}

pub fn load_public_config() -> Result<AniListPublicConfig, String> {
    Ok(AniListPublicConfig {
        client_id: env_or_build(VAR_CLIENT_ID, BUILD_CLIENT_ID)
            .ok_or_else(|| missing_var(VAR_CLIENT_ID))?,
        auth_url: env_or_build(VAR_AUTH_URL, BUILD_AUTH_URL)
            .unwrap_or_else(|| DEFAULT_AUTH_URL.into()),
    })
}

pub fn fetch_viewer(app: &AppHandle) -> Result<AniListViewer, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    let payload: ViewerPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": "query Viewer { Viewer { id name avatar { large } mediaListOptions { scoreFormat animeList { customLists } mangaList { customLists } } } }" }),
    ).map_err(|e| format!("[VIEWER_FETCH_FAILED] {e}"))?;

    let v = payload.viewer;
    let options = v.media_list_options;
    let result = AniListViewer {
        id: v.id,
        name: v.name,
        avatar_url: v.avatar.and_then(|a| a.large),
        score_format: options
            .as_ref()
            .and_then(|o| o.score_format.clone())
            .unwrap_or_else(|| "POINT_10_DECIMAL".to_string()),
        anime_custom_lists: options
            .as_ref()
            .and_then(|o| o.anime_list.as_ref())
            .and_then(|o| o.custom_lists.clone())
            .unwrap_or_default(),
        manga_custom_lists: options
            .as_ref()
            .and_then(|o| o.manga_list.as_ref())
            .and_then(|o| o.custom_lists.clone())
            .unwrap_or_default(),
    };
    persist_viewer_profile(app, &result)?;
    Ok(result)
}

pub fn fetch_favorites(app: &AppHandle) -> Result<UserFavorites, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
    query Favorites($page: Int, $perPage: Int) {
      Viewer {
        favourites {
          anime(page: $page, perPage: $perPage) {
            nodes { id title { romaji english } coverImage { large } }
            pageInfo { hasNextPage }
          }
          manga(page: $page, perPage: $perPage) {
            nodes { id title { romaji english } coverImage { large } }
            pageInfo { hasNextPage }
          }
          characters(page: $page, perPage: $perPage) {
            nodes { id name { full } image { large } }
            pageInfo { hasNextPage }
          }
          staff(page: $page, perPage: $perPage) {
            nodes { id name { full } image { large } }
            pageInfo { hasNextPage }
          }
          studios(page: $page, perPage: $perPage) {
            nodes { id name isAnimationStudio }
            pageInfo { hasNextPage }
          }
        }
      }
    }"#;

    let per_page = 50i64;
    let mut all_anime: Vec<FavoriteMedia> = Vec::new();
    let mut all_manga: Vec<FavoriteMedia> = Vec::new();
    let mut all_chars: Vec<FavoritePerson> = Vec::new();
    let mut all_staff: Vec<FavoritePerson> = Vec::new();
    let mut all_studios: Vec<FavoriteStudio> = Vec::new();

    let mut anime_done = false;
    let mut manga_done = false;
    let mut chars_done = false;
    let mut staff_done = false;
    let mut studios_done = false;

    for page in 1i64..=20 {
        if anime_done && manga_done && chars_done && staff_done && studios_done {
            break;
        }

        let payload: FavouritesPayload = graphql_post(
            &config.graphql_url,
            &access_token,
            &json!({ "query": QUERY, "variables": { "page": page, "perPage": per_page } }),
        )
        .map_err(|e| format!("[FAVORITES_FETCH_FAILED] {e}"))?;

        let fav = payload.viewer.favourites;

        if !anime_done {
            let pi = fav.anime.page_info.has_next_page;
            all_anime.extend(fav.anime.nodes.into_iter().map(|n| FavoriteMedia {
                id: n.id,
                title: n.title.english.or(n.title.romaji).unwrap_or_default(),
                cover_image: n.cover_image.and_then(|c| c.large),
            }));
            if !pi {
                anime_done = true;
            }
        }
        if !manga_done {
            let pi = fav.manga.page_info.has_next_page;
            all_manga.extend(fav.manga.nodes.into_iter().map(|n| FavoriteMedia {
                id: n.id,
                title: n.title.english.or(n.title.romaji).unwrap_or_default(),
                cover_image: n.cover_image.and_then(|c| c.large),
            }));
            if !pi {
                manga_done = true;
            }
        }
        if !chars_done {
            let pi = fav.characters.page_info.has_next_page;
            all_chars.extend(fav.characters.nodes.into_iter().map(|n| FavoritePerson {
                id: n.id,
                name: n.name.full.unwrap_or_default(),
                image: n.image.and_then(|i| i.large),
            }));
            if !pi {
                chars_done = true;
            }
        }
        if !staff_done {
            let pi = fav.staff.page_info.has_next_page;
            all_staff.extend(fav.staff.nodes.into_iter().map(|n| FavoritePerson {
                id: n.id,
                name: n.name.full.unwrap_or_default(),
                image: n.image.and_then(|i| i.large),
            }));
            if !pi {
                staff_done = true;
            }
        }
        if !studios_done {
            let pi = fav.studios.page_info.has_next_page;
            all_studios.extend(fav.studios.nodes.into_iter().map(|n| FavoriteStudio {
                id: n.id,
                name: n.name,
                is_animation_studio: n.is_animation_studio,
            }));
            if !pi {
                studios_done = true;
            }
        }
    }

    Ok(UserFavorites {
        anime: all_anime,
        manga: all_manga,
        characters: all_chars,
        staff: all_staff,
        studios: all_studios,
    })
}

pub fn toggle_media_favorite(
    app: &AppHandle,
    media_id: i64,
    media_type: &str,
) -> Result<bool, String> {
    toggle_favorite(app, media_id, media_type)
}

pub fn toggle_favorite(app: &AppHandle, target_id: i64, target_type: &str) -> Result<bool, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const MUTATION: &str = r#"
    mutation ToggleFavourite($animeId: Int, $mangaId: Int, $characterId: Int, $staffId: Int, $studioId: Int) {
      ToggleFavourite(animeId: $animeId, mangaId: $mangaId, characterId: $characterId, staffId: $staffId, studioId: $studioId) {
        anime { nodes { id } }
        manga { nodes { id } }
        characters { nodes { id } }
        staff { nodes { id } }
        studios { nodes { id } }
      }
    }"#;

    let target_type_upper = target_type.to_uppercase();
    let mut variables = json!({
        "animeId": Value::Null,
        "mangaId": Value::Null,
        "characterId": Value::Null,
        "staffId": Value::Null,
        "studioId": Value::Null,
    });

    match target_type_upper.as_str() {
        "ANIME" => variables["animeId"] = json!(target_id),
        "MANGA" | "NOVEL" => variables["mangaId"] = json!(target_id),
        "CHARACTER" => variables["characterId"] = json!(target_id),
        "STAFF" => variables["staffId"] = json!(target_id),
        "STUDIO" => variables["studioId"] = json!(target_id),
        other => {
            return Err(format!(
                "[TOGGLE_FAVORITE_INVALID_TYPE] Unsupported favorite type: {other}"
            ))
        }
    }

    let payload: ToggleFavouritePayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": MUTATION, "variables": variables }),
    )
    .map_err(|e| format!("[TOGGLE_FAVORITE_FAILED] {e}"))?;

    let ids = match target_type_upper.as_str() {
        "ANIME" => payload.toggle_favourite.anime,
        "MANGA" | "NOVEL" => payload.toggle_favourite.manga,
        "CHARACTER" => payload.toggle_favourite.characters,
        "STAFF" => payload.toggle_favourite.staff,
        "STUDIO" => payload.toggle_favourite.studios,
        _ => None,
    }
    .and_then(|connection| connection.nodes)
    .unwrap_or_default()
    .into_iter()
    .map(|node| node.id)
    .collect::<Vec<_>>();

    Ok(ids.contains(&target_id))
}

pub fn fetch_character_details(app: &AppHandle, id: i64) -> Result<CharacterDetails, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
    query Character($id: Int) {
      Character(id: $id) {
        id name { full native }
        image { large }
        description gender age
        dateOfBirth { year month day }
        favourites
        media(page: 1, perPage: 12) {
          nodes { id title { romaji english } coverImage { large } format }
        }
      }
    }"#;

    let payload: CharacterDetailsPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "id": id } }),
    )
    .map_err(|e| format!("[CHARACTER_FETCH_FAILED] {e}"))?;

    let c = payload.character;
    Ok(CharacterDetails {
        id: c.id,
        name_full: c.name.full,
        name_native: c.name.native,
        image: c.image.and_then(|i| i.large),
        description: c.description,
        gender: c.gender,
        age: c.age,
        date_of_birth: c.date_of_birth.and_then(|d| d.to_iso_date()),
        favourites: c.favourites,
        media: c
            .media
            .map(|m| {
                m.nodes
                    .into_iter()
                    .map(|n| CharacterMedia {
                        id: n.id,
                        title: n.title.english.or(n.title.romaji).unwrap_or_default(),
                        cover_image: n.cover_image.and_then(|ci| ci.large),
                        format: n.format,
                    })
                    .collect()
            })
            .unwrap_or_default(),
    })
}

pub fn fetch_staff_details(app: &AppHandle, id: i64) -> Result<StaffDetails, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
    query Staff($id: Int) {
      Staff(id: $id) {
        id name { full native }
        image { large }
        description primaryOccupations gender age
        dateOfBirth { year month day }
        dateOfDeath { year month day }
        favourites
        characters(page: 1, perPage: 12) {
          nodes { id name { full } image { large } }
        }
      }
    }"#;

    let payload: StaffDetailsPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "id": id } }),
    )
    .map_err(|e| format!("[STAFF_FETCH_FAILED] {e}"))?;

    let s = payload.staff;
    Ok(StaffDetails {
        id: s.id,
        name_full: s.name.full,
        name_native: s.name.native,
        image: s.image.and_then(|i| i.large),
        description: s.description,
        primary_occupations: s.primary_occupations.unwrap_or_default(),
        gender: s.gender,
        age: s.age,
        date_of_birth: s.date_of_birth.and_then(|d| d.to_iso_date()),
        date_of_death: s.date_of_death.and_then(|d| d.to_iso_date()),
        favourites: s.favourites,
        characters: s
            .characters
            .map(|conn| {
                conn.nodes
                    .into_iter()
                    .map(|n| StaffCharacter {
                        id: n.id,
                        name: n.name.full.unwrap_or_default(),
                        image: n.image.and_then(|i| i.large),
                    })
                    .collect()
            })
            .unwrap_or_default(),
    })
}

pub fn fetch_studio_details(app: &AppHandle, id: i64) -> Result<StudioDetails, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
    query Studio($id: Int) {
      Studio(id: $id) {
        id name isAnimationStudio favourites siteUrl
        media(page: 1, perPage: 20, sort: [START_DATE_DESC]) {
          nodes { id title { romaji english } coverImage { large } format status }
        }
      }
    }"#;

    let payload: StudioDetailsPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "id": id } }),
    )
    .map_err(|e| format!("[STUDIO_FETCH_FAILED] {e}"))?;

    let st = payload.studio;
    Ok(StudioDetails {
        id: st.id,
        name: st.name,
        is_animation_studio: st.is_animation_studio,
        favourites: st.favourites,
        site_url: st.site_url,
        media: st
            .media
            .map(|m| {
                m.nodes
                    .into_iter()
                    .map(|n| StudioMedia {
                        id: n.id,
                        title: n.title.english.or(n.title.romaji).unwrap_or_default(),
                        cover_image: n.cover_image.and_then(|ci| ci.large),
                        format: n.format,
                        status: n.status,
                    })
                    .collect()
            })
            .unwrap_or_default(),
    })
}

pub fn fetch_user_profile(app: &AppHandle, name: &str) -> Result<UserProfile, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
    query UserProfile($name: String) {
      User(name: $name) {
        id name avatar { large } bannerImage about
        isFollowing
        isFollower
        statistics {
          anime { count episodesWatched minutesWatched meanScore }
          manga { count chaptersRead volumesRead meanScore }
        }
      }
    }"#;

    let payload: UserProfilePayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "name": name } }),
    )
    .map_err(|e| format!("[USER_PROFILE_FETCH_FAILED] {e}"))?;

    let u = payload.user;
    let stats = u.statistics.map(|s| UserProfileStats {
        anime_count: s.anime.as_ref().map(|a| a.count).unwrap_or(0),
        episodes_watched: s
            .anime
            .as_ref()
            .and_then(|a| a.episodes_watched)
            .unwrap_or(0),
        anime_mean_score: s.anime.as_ref().and_then(|a| a.mean_score),
        manga_count: s.manga.as_ref().map(|m| m.count).unwrap_or(0),
        chapters_read: s.manga.as_ref().and_then(|m| m.chapters_read).unwrap_or(0),
        manga_mean_score: s.manga.as_ref().and_then(|m| m.mean_score),
    });

    let following_count =
        fetch_social_count(&config.graphql_url, &access_token, u.id, true).unwrap_or(0);
    let followers_count =
        fetch_social_count(&config.graphql_url, &access_token, u.id, false).unwrap_or(0);

    Ok(UserProfile {
        id: u.id,
        name: u.name,
        avatar_url: u.avatar.and_then(|a| a.large),
        banner_url: u.banner_image,
        about: u.about,
        is_following: u.is_following.unwrap_or(false),
        is_follower: u.is_follower.unwrap_or(false),
        following_count,
        followers_count,
        stats,
    })
}

fn fetch_social_count(
    graphql_url: &str,
    access_token: &str,
    user_id: i64,
    following: bool,
) -> Result<i64, String> {
    const FOLLOWING_QUERY: &str = r#"
    query FollowingCountPage($userId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo { hasNextPage total }
        following(userId: $userId) { id }
      }
    }"#;

    const FOLLOWERS_QUERY: &str = r#"
    query FollowersCountPage($userId: Int!, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        pageInfo { hasNextPage total }
        followers(userId: $userId) { id }
      }
    }"#;

    let mut page = 1;
    let mut count: i64 = 0;

    loop {
        let query = if following {
            FOLLOWING_QUERY
        } else {
            FOLLOWERS_QUERY
        };
        let payload: FollowUsersPayload = graphql_post(
            graphql_url,
            access_token,
            &json!({ "query": query, "variables": { "userId": user_id, "page": page, "perPage": 50 } }),
        )?;

        if let Some(total) = payload.page.page_info.as_ref().and_then(|pi| pi.total) {
            return Ok(total);
        }

        let page_count = if following {
            payload
                .page
                .following
                .as_ref()
                .map(|items| items.len() as i64)
                .unwrap_or(0)
        } else {
            payload
                .page
                .followers
                .as_ref()
                .map(|items| items.len() as i64)
                .unwrap_or(0)
        };
        count += page_count;

        let has_next = payload
            .page
            .page_info
            .as_ref()
            .map(|pi| pi.has_next_page)
            .unwrap_or(false);
        if !has_next {
            break;
        }
        page += 1;

        if page > 200 {
            break;
        }
    }

    Ok(count)
}

pub fn search_characters(app: &AppHandle, query: &str) -> Result<Vec<PersonSearchResult>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const GQL: &str = r#"
    query SearchCharacters($search: String, $perPage: Int) {
      Page(perPage: $perPage) {
        characters(search: $search) {
          id name { full } image { large }
          media(perPage: 1) { nodes { title { romaji } } }
        }
      }
    }"#;

    let payload: CharacterSearchPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": GQL, "variables": { "search": query, "perPage": 25 } }),
    )
    .map_err(|e| format!("[CHAR_SEARCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .characters
        .into_iter()
        .map(|c| PersonSearchResult {
            id: c.id,
            kind: "CHARACTER".into(),
            name: c.name.full.unwrap_or_default(),
            image: c.image.and_then(|i| i.large),
            sub: c
                .media
                .and_then(|m| m.nodes.into_iter().next())
                .and_then(|m| m.title.english.or(m.title.romaji)),
        })
        .collect())
}

pub fn search_staff(app: &AppHandle, query: &str) -> Result<Vec<PersonSearchResult>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const GQL: &str = r#"
    query SearchStaff($search: String, $perPage: Int) {
      Page(perPage: $perPage) {
        staff(search: $search) {
          id name { full } image { large }
          primaryOccupations
        }
      }
    }"#;

    let payload: StaffSearchPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": GQL, "variables": { "search": query, "perPage": 25 } }),
    )
    .map_err(|e| format!("[STAFF_SEARCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .staff
        .into_iter()
        .map(|s| PersonSearchResult {
            id: s.id,
            kind: "STAFF".into(),
            name: s.name.full.unwrap_or_default(),
            image: s.image.and_then(|i| i.large),
            sub: s.primary_occupations.and_then(|o| o.into_iter().next()),
        })
        .collect())
}

pub fn search_studios(app: &AppHandle, query: &str) -> Result<Vec<StudioSearchResult>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const GQL: &str = r#"
    query SearchStudios($search: String, $perPage: Int) {
      Page(perPage: $perPage) {
        studios(search: $search) {
          id name isAnimationStudio
          media(perPage: 1, sort: [POPULARITY_DESC]) { nodes { title { romaji english } } }
        }
      }
    }"#;

    let payload: StudioSearchPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": GQL, "variables": { "search": query, "perPage": 25 } }),
    )
    .map_err(|e| format!("[STUDIO_SEARCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .studios
        .into_iter()
        .map(|s| StudioSearchResult {
            id: s.id,
            name: s.name,
            is_animation_studio: s.is_animation_studio,
            recent_title: s
                .media
                .and_then(|m| m.nodes.into_iter().next())
                .and_then(|m| m.title.english.or(m.title.romaji)),
        })
        .collect())
}

pub fn search_users(app: &AppHandle, query: &str) -> Result<Vec<UserSearchResult>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const GQL: &str = r#"
    query SearchUsers($search: String, $perPage: Int) {
      Page(perPage: $perPage) {
        users(search: $search) {
          id name avatar { large }
        }
      }
    }"#;

    let payload: UserSearchPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": GQL, "variables": { "search": query, "perPage": 25 } }),
    )
    .map_err(|e| format!("[USER_SEARCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .users
        .into_iter()
        .map(|u| UserSearchResult {
            id: u.id,
            name: u.name,
            avatar_url: u.avatar.and_then(|a| a.large),
        })
        .collect())
}

pub fn toggle_follow(app: &AppHandle, user_id: i64, follow: bool) -> Result<bool, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    // Avoid accidental state flips: only call ToggleFollow when a transition is needed.
    const STATE_QUERY: &str = r#"
        query FollowState($userId: Int!) {
            User(id: $userId) { isFollowing }
        }"#;
    let state_payload: UserProfilePayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": STATE_QUERY, "variables": { "userId": user_id } }),
    )
    .map_err(|e| format!("[FOLLOW_STATE_FETCH_FAILED] {e}"))?;

    let is_following_now = state_payload.user.is_following.unwrap_or(false);
    if is_following_now == follow {
        return Ok(is_following_now);
    }

    const MUTATION: &str = r#"
        mutation ToggleFollow($userId: Int!) {
            ToggleFollow(userId: $userId) { isFollowing }
        }"#;

    let payload: ToggleFollowPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": MUTATION, "variables": { "userId": user_id } }),
    )
    .map_err(|e| format!("[TOGGLE_FOLLOW_FAILED] {e}"))?;

    Ok(payload
        .toggle_follow
        .and_then(|t| t.is_following)
        .unwrap_or(follow))
}

pub fn get_following(app: &AppHandle, user_id: i64, page: i64) -> Result<Vec<SocialUser>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
        query GetFollowing($userId: Int!, $page: Int, $perPage: Int) {
            Page(page: $page, perPage: $perPage) {
                following(userId: $userId) {
                    id
                    name
                    avatar { large }
                    isFollowing
                    isFollower
                }
            }
        }"#;

    let payload: FollowUsersPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "userId": user_id, "page": page, "perPage": 50 } }),
    )
    .map_err(|e| format!("[FOLLOWING_FETCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .following
        .unwrap_or_default()
        .into_iter()
        .map(|u| SocialUser {
            id: u.id,
            name: u.name,
            avatar_url: u.avatar.and_then(|a| a.large),
            is_following: u.is_following.unwrap_or(false),
            is_follower: u.is_follower.unwrap_or(false),
        })
        .collect())
}

pub fn get_followers(app: &AppHandle, user_id: i64, page: i64) -> Result<Vec<SocialUser>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
        query GetFollowers($userId: Int!, $page: Int, $perPage: Int) {
            Page(page: $page, perPage: $perPage) {
                followers(userId: $userId) {
                    id
                    name
                    avatar { large }
                    isFollowing
                    isFollower
                }
            }
        }"#;

    let payload: FollowUsersPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "userId": user_id, "page": page, "perPage": 50 } }),
    )
    .map_err(|e| format!("[FOLLOWERS_FETCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .followers
        .unwrap_or_default()
        .into_iter()
        .map(|u| SocialUser {
            id: u.id,
            name: u.name,
            avatar_url: u.avatar.and_then(|a| a.large),
            is_following: u.is_following.unwrap_or(false),
            is_follower: u.is_follower.unwrap_or(false),
        })
        .collect())
}

fn map_activity_node(a: FollowingActivityNode) -> FollowingActivityItem {
    let user = a.user.or(a.messenger).unwrap_or(ActivityUserNode {
        id: 0,
        name: "Unknown".to_string(),
        avatar: None,
    });
    let (media_id, media_title, media_cover_image, activity_type) = if let Some(m) = a.media {
        (
            Some(m.id),
            m.title.english.or(m.title.romaji),
            m.cover_image.and_then(|ci| ci.large),
            if a.typename == "ListActivity" {
                if m.media_type.as_deref() == Some("MANGA") {
                    "MANGA_LIST".to_string()
                } else {
                    "ANIME_LIST".to_string()
                }
            } else {
                "TEXT".to_string()
            },
        )
    } else {
        (
            None,
            None,
            None,
            if a.typename == "TextActivity" || a.typename == "MessageActivity" {
                "TEXT".to_string()
            } else {
                "ANIME_LIST".to_string()
            },
        )
    };

    let replies = a
        .replies
        .unwrap_or_default()
        .into_iter()
        .map(|reply| {
            let user = reply.user.unwrap_or(ActivityUserNode {
                id: 0,
                name: "Unknown".to_string(),
                avatar: None,
            });
            ActivityReplyItem {
                id: reply.id,
                created_at: reply.created_at.unwrap_or(0),
                like_count: reply.like_count.unwrap_or(0),
                is_liked: reply.is_liked.unwrap_or(false),
                user_id: user.id,
                user_name: user.name,
                user_avatar: user.avatar.and_then(|a| a.large),
                text: reply.text,
            }
        })
        .collect();

    FollowingActivityItem {
        id: a.id,
        activity_type,
        created_at: a.created_at,
        like_count: a.like_count.unwrap_or(0),
        reply_count: a.reply_count.unwrap_or(0),
        is_liked: a.is_liked.unwrap_or(false),
        is_message: a.typename == "MessageActivity",
        user_id: user.id,
        user_name: user.name,
        user_avatar: user.avatar.and_then(|av| av.large),
        text: a.text.or(a.message),
        status: a.status,
        progress: a.progress,
        media_id,
        media_title,
        media_cover_image,
        replies,
    }
}

pub fn get_following_activity(
    app: &AppHandle,
    page: i64,
    per_page: i64,
) -> Result<Vec<FollowingActivityItem>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
        query FollowingActivity($page: Int, $perPage: Int) {
            Page(page: $page, perPage: $perPage) {
                activities(isFollowing: true, sort: ID_DESC, type_in: [TEXT, ANIME_LIST, MANGA_LIST, MESSAGE]) {
                    ... on TextActivity {
                        __typename
                        id
                        createdAt
                        likeCount
                        isLiked
                        replyCount
                        text
                        replies {
                            id
                            createdAt
                            likeCount
                            isLiked
                            text(asHtml: false)
                            user { id name avatar { large } }
                        }
                        user { id name avatar { large } }
                    }
                    ... on MessageActivity {
                        __typename
                        id
                        createdAt
                        likeCount
                        isLiked
                        replyCount
                        message(asHtml: false)
                        recipient { id name avatar { large } }
                        replies {
                            id
                            createdAt
                            likeCount
                            isLiked
                            text(asHtml: false)
                            user { id name avatar { large } }
                        }
                        messenger { id name avatar { large } }
                    }
                    ... on ListActivity {
                        __typename
                        id
                        createdAt
                        likeCount
                        isLiked
                        replyCount
                        status
                        progress
                        replies {
                            id
                            createdAt
                            likeCount
                            isLiked
                            text(asHtml: false)
                            user { id name avatar { large } }
                        }
                        user { id name avatar { large } }
                        media { id type title { romaji english } coverImage { large } }
                    }
                }
            }
        }"#;

    let payload: FollowingActivityPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "page": page, "perPage": per_page } }),
    )
    .map_err(|e| format!("[FOLLOWING_ACTIVITY_FETCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .activities
        .into_iter()
        .map(map_activity_node)
        .collect())
}

pub fn get_global_activity(
    app: &AppHandle,
    page: i64,
    per_page: i64,
) -> Result<Vec<FollowingActivityItem>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
        query GlobalActivity($page: Int, $perPage: Int) {
            Page(page: $page, perPage: $perPage) {
                activities(sort: ID_DESC, type_in: [TEXT, ANIME_LIST, MANGA_LIST, MESSAGE]) {
                    ... on TextActivity {
                        __typename
                        id
                        createdAt
                        likeCount
                        isLiked
                        replyCount
                        text
                        replies {
                            id
                            createdAt
                            likeCount
                            isLiked
                            text(asHtml: false)
                            user { id name avatar { large } }
                        }
                        user { id name avatar { large } }
                    }
                    ... on MessageActivity {
                        __typename
                        id
                        createdAt
                        likeCount
                        isLiked
                        replyCount
                        message(asHtml: false)
                        recipient { id name avatar { large } }
                        replies {
                            id
                            createdAt
                            likeCount
                            isLiked
                            text(asHtml: false)
                            user { id name avatar { large } }
                        }
                        messenger { id name avatar { large } }
                    }
                    ... on ListActivity {
                        __typename
                        id
                        createdAt
                        likeCount
                        isLiked
                        replyCount
                        status
                        progress
                        replies {
                            id
                            createdAt
                            likeCount
                            isLiked
                            text(asHtml: false)
                            user { id name avatar { large } }
                        }
                        user { id name avatar { large } }
                        media { id type title { romaji english } coverImage { large } }
                    }
                }
            }
        }"#;

    let payload: FollowingActivityPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "page": page, "perPage": per_page } }),
    )
    .map_err(|e| format!("[GLOBAL_ACTIVITY_FETCH_FAILED] {e}"))?;

    Ok(payload
        .page
        .activities
        .into_iter()
        .map(map_activity_node)
        .collect())
}

pub fn get_user_media_list(
    app: &AppHandle,
    user_id: i64,
    media_type: &str,
) -> Result<Vec<UserMediaListItem>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const QUERY: &str = r#"
        query UserMediaList($userId: Int, $type: MediaType) {
            MediaListCollection(userId: $userId, type: $type) {
                lists {
                    entries {
                        status
                        score
                        progress
                        progressVolumes
                        updatedAt
                        media {
                            id
                            type
                            title { romaji english }
                            coverImage { large }
                        }
                    }
                }
            }
        }"#;

    let payload: UserMediaListPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": QUERY, "variables": { "userId": user_id, "type": media_type } }),
    )
    .map_err(|e| format!("[USER_MEDIA_LIST_FETCH_FAILED] {e}"))?;

    let mut out = Vec::new();
    for list in payload
        .media_list_collection
        .map(|c| c.lists)
        .unwrap_or_default()
    {
        for entry in list.entries {
            if let Some(media) = entry.media {
                out.push(UserMediaListItem {
                    media_id: media.id,
                    media_type: media.media_type,
                    title: media
                        .title
                        .english
                        .or(media.title.romaji)
                        .unwrap_or_else(|| media.id.to_string()),
                    cover_image: media.cover_image.and_then(|ci| ci.large),
                    status: entry.status.unwrap_or_else(|| "PLANNING".to_string()),
                    score: entry.score,
                    progress: entry.progress.unwrap_or(0),
                    progress_volumes: entry.progress_volumes.unwrap_or(0),
                    updated_at: entry.updated_at.unwrap_or(0),
                });
            }
        }
    }

    out.sort_by_key(|b| std::cmp::Reverse(b.updated_at));
    Ok(out)
}

pub fn post_activity(app: &AppHandle, text: &str) -> Result<i64, String> {
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Err("Activity text cannot be empty.".into());
    }

    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const MUTATION: &str = r#"
        mutation SaveTextActivity($text: String) {
            SaveTextActivity(text: $text) { id text createdAt }
        }"#;

    let payload: SaveTextActivityPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": MUTATION, "variables": { "text": trimmed } }),
    )
    .map_err(|e| format!("[POST_ACTIVITY_FAILED] {e}"))?;

    Ok(payload.save_text_activity.id)
}

pub fn toggle_activity_like(app: &AppHandle, activity_id: i64) -> Result<bool, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const MUTATION: &str = r#"
        mutation ToggleActivityLike($activityId: Int!) {
            ToggleLikeV2(id: $activityId, type: ACTIVITY) {
            ... on ListActivity { id likeCount isLiked }
            ... on TextActivity { id likeCount isLiked }
            ... on MessageActivity { id likeCount isLiked }
            }
        }"#;

    let payload: ToggleLikePayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": MUTATION, "variables": { "activityId": activity_id } }),
    )
    .map_err(|e| format!("[TOGGLE_ACTIVITY_LIKE_FAILED] {e}"))?;

    Ok(payload.toggle_like_v2.is_liked)
}

pub fn save_activity_reply(app: &AppHandle, activity_id: i64, text: &str) -> Result<i64, String> {
    let trimmed = text.trim();
    if trimmed.is_empty() {
        return Err("Reply text cannot be empty.".into());
    }

    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const MUTATION: &str = r#"
        mutation SaveActivityReply($activityId: Int!, $text: String!) {
            SaveActivityReply(activityId: $activityId, text: $text) {
            id
            }
        }"#;

    let payload: SaveActivityReplyPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": MUTATION, "variables": { "activityId": activity_id, "text": trimmed } }),
    )
    .map_err(|e| format!("[SAVE_ACTIVITY_REPLY_FAILED] {e}"))?;

    Ok(payload.save_activity_reply.id)
}

pub fn get_auth_session_status(app: &AppHandle) -> Result<AuthSessionStatus, String> {
    crate::db::initialize_database(app)?;

    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    let session = connection
        .query_row(
            "
            SELECT
              access_token,
              viewer_id,
              expires_at,
              CASE WHEN expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP THEN 1 ELSE 0 END,
              updated_at
            FROM auth_session
            WHERE id = 1
            ",
            [],
            |row| {
                Ok((
                    row.get::<_, Option<String>>(0)?,
                    row.get::<_, Option<i64>>(1)?,
                    row.get::<_, Option<String>>(2)?,
                    row.get::<_, i64>(3)? != 0,
                    row.get::<_, Option<String>>(4)?,
                ))
            },
        )
        .optional()
        .map_err(|error| error.to_string())?;

    let (db_token, viewer_id, token_expires_at, is_token_expired, updated_at) =
        session.unwrap_or((None, None, None, false, None));

    // Token exists if it's in the keyring OR in the DB column.
    let has_access_token =
        keyring_read().is_some() || db_token.as_ref().map(|t| !t.is_empty()).unwrap_or(false);

    let profile = if let Some(id) = viewer_id {
        connection
            .query_row(
                "SELECT name, avatar_url FROM user_profile_cache WHERE user_id = ?1",
                [id],
                |row| Ok((row.get::<_, String>(0)?, row.get::<_, Option<String>>(1)?)),
            )
            .optional()
            .map_err(|error| error.to_string())?
            .map(|(name, avatar_url)| (Some(name), avatar_url))
            .unwrap_or((None, None))
    } else {
        (None, None)
    };

    Ok(AuthSessionStatus {
        has_access_token,
        viewer_id,
        viewer_name: profile.0,
        viewer_avatar_url: profile.1,
        token_expires_at,
        is_token_expired,
        updated_at,
    })
}

pub fn store_access_token(
    app: &AppHandle,
    access_token: &str,
) -> Result<AuthSessionStatus, String> {
    crate::db::initialize_database(app)?;

    let trimmed = access_token.trim();
    if trimmed.is_empty() {
        return Err("Access token cannot be empty.".into());
    }

    // Store in OS keyring; if unavailable/unreadable also write to DB fallback.
    let keyring_ok = keyring_roundtrip_ok(trimmed);

    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    // If keyring succeeded, keep DB token NULL to avoid plaintext duplication.
    let db_token: Option<&str> = if keyring_ok { None } else { Some(trimmed) };
    connection
        .execute(
            "
            INSERT INTO auth_session (
              id,
              access_token,
              acquired_at,
              updated_at
            ) VALUES (1, ?1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
              access_token = excluded.access_token,
              acquired_at = CURRENT_TIMESTAMP,
              updated_at = CURRENT_TIMESTAMP
            ",
            [db_token],
        )
        .map_err(|error| error.to_string())?;

    get_auth_session_status(app)
}

pub fn clear_access_token(app: &AppHandle) -> Result<AuthSessionStatus, String> {
    crate::db::initialize_database(app)?;

    // Remove from OS keyring first.
    keyring_delete();

    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    connection
        .execute(
            "
            INSERT INTO auth_session (id, updated_at)
            VALUES (1, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
              access_token = NULL,
              viewer_id = NULL,
              acquired_at = NULL,
              expires_at = NULL,
              auth_state = NULL,
              updated_at = CURRENT_TIMESTAMP
            ",
            [],
        )
        .map_err(|error| error.to_string())?;

    get_auth_session_status(app)
}

pub fn exchange_authorization_code(app: &AppHandle, code: &str) -> Result<(), String> {
    crate::db::initialize_database(app)?;

    let config = load_config()?;
    let client_secret = config
        .client_secret
        .clone()
        .ok_or_else(|| missing_var(VAR_CLIENT_SECRET))?;

    let response = http_client()
        .post(&config.token_url)
        .json(&json!({
            "grant_type": "authorization_code",
            "client_id": config.client_id,
            "client_secret": client_secret,
            "redirect_uri": crate::auth::redirect_uri(),
            "code": code,
        }))
        .send()
        .map_err(|e| {
            format!("[TOKEN_EXCHANGE_NETWORK_ERROR] AniList token exchange failed: {e}")
        })?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().unwrap_or_else(|_| "<unavailable>".into());
        return Err(format!(
            "[TOKEN_EXCHANGE_HTTP_ERROR] AniList token endpoint returned HTTP {status}: {body}"
        ));
    }

    let payload: TokenExchangeResponse = response.json().map_err(|e| {
        format!("[TOKEN_EXCHANGE_PARSE_ERROR] Failed to parse AniList token response: {e}")
    })?;

    persist_oauth_session(app, &payload.access_token, payload.expires_in)
        .map_err(|e| format!("[STORAGE_FAILED] {e}"))?;

    Ok(())
}

fn read_access_token(app: &AppHandle) -> Result<String, String> {
    // Check DB for expiry metadata first (keyring has no expiry info).
    let expiry_check: Option<i64> = crate::db::database_path(app)
        .ok()
        .and_then(|p| crate::db::open_connection(&p).ok())
        .and_then(|conn| {
            conn.query_row(
                "SELECT CASE WHEN expires_at IS NOT NULL AND expires_at < CURRENT_TIMESTAMP THEN 1 ELSE 0 END \
                 FROM auth_session WHERE id = 1",
                [],
                |row| row.get::<_, i64>(0),
            ).ok()
        });

    if expiry_check == Some(1) {
        return Err(
            "[AUTH_EXPIRED] Your AniList session has expired. Please sign in again.".into(),
        );
    }

    // Prefer OS keyring (no plaintext SQLite token).
    if let Some(token) = keyring_read() {
        return Ok(token);
    }

    // Fall back to DB (manual token entry or keyring unavailable).
    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    connection
        .query_row(
            "SELECT access_token FROM auth_session WHERE id = 1",
            [],
            |row| row.get::<_, Option<String>>(0),
        )
        .map_err(|e| e.to_string())?
        .filter(|t| !t.is_empty())
        .ok_or_else(|| "[NO_TOKEN] No AniList access token stored. Please sign in.".into())
}

fn env_var(name: &str) -> Option<String> {
    dotenvy::dotenv().ok();
    env::var(name).ok().filter(|value| !value.trim().is_empty())
}

fn build_var(value: Option<&str>) -> Option<String> {
    value
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(ToOwned::to_owned)
}

fn env_or_build(name: &str, build_value: Option<&str>) -> Option<String> {
    env_var(name).or_else(|| build_var(build_value))
}

fn missing_var(name: &str) -> String {
    format!("Missing required environment variable: {name}")
}

fn keyring_roundtrip_ok(token: &str) -> bool {
    if keyring_store(token).is_err() {
        return false;
    }
    matches!(keyring_read().as_deref(), Some(stored) if stored == token)
}

fn persist_oauth_session(
    app: &AppHandle,
    access_token: &str,
    expires_in: Option<i64>,
) -> Result<(), String> {
    // Store in OS keyring; fall back to DB if unavailable or unreadable.
    let keyring_ok = keyring_roundtrip_ok(access_token);
    let db_token: Option<&str> = if keyring_ok { None } else { Some(access_token) };

    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    match expires_in {
        Some(expires_in_seconds) => {
            let expires_modifier = format!("+{expires_in_seconds} seconds");
            connection
                                .execute(
                                        "
                                        INSERT INTO auth_session (
                                            id,
                                            access_token,
                                            viewer_id,
                                            acquired_at,
                                            expires_at,
                                            auth_state,
                                            updated_at
                                        ) VALUES (1, ?1, NULL, CURRENT_TIMESTAMP, datetime(CURRENT_TIMESTAMP, ?2), NULL, CURRENT_TIMESTAMP)
                                        ON CONFLICT(id) DO UPDATE SET
                                            access_token = excluded.access_token,
                                            viewer_id = NULL,
                                            acquired_at = CURRENT_TIMESTAMP,
                                            expires_at = datetime(CURRENT_TIMESTAMP, ?2),
                                            auth_state = NULL,
                                            updated_at = CURRENT_TIMESTAMP
                                        ",
                                        (db_token, expires_modifier.as_str()),
                                )
                                .map_err(|error| error.to_string())?;
        }
        None => {
            connection
                                .execute(
                                        "
                                        INSERT INTO auth_session (
                                            id,
                                            access_token,
                                            viewer_id,
                                            acquired_at,
                                            expires_at,
                                            auth_state,
                                            updated_at
                                        ) VALUES (1, ?1, NULL, CURRENT_TIMESTAMP, NULL, NULL, CURRENT_TIMESTAMP)
                                        ON CONFLICT(id) DO UPDATE SET
                                            access_token = excluded.access_token,
                                            viewer_id = NULL,
                                            acquired_at = CURRENT_TIMESTAMP,
                                            expires_at = NULL,
                                            auth_state = NULL,
                                            updated_at = CURRENT_TIMESTAMP
                                        ",
                                        [db_token],
                                )
                                .map_err(|error| error.to_string())?;
        }
    }

    Ok(())
}

// ─── User list sync ───────────────────────────────────────────────────────────

/// Perform a **full** pull of the user's list from AniList in a single
/// `MediaListCollection` query.  Returns `(synced, conflicts, max_updated_at)`.
///
/// **Currently unused** — `sync_lists_smart` always uses the paginated
/// `fetch_user_lists_delta` path because `MediaListCollection` is unreliable
/// for users with large libraries (>~1k entries it routinely 5xxs or hits
/// AniList's complexity budget).  Kept for reference / potential fallback.
#[allow(dead_code)]
pub fn fetch_user_lists(app: &AppHandle, media_type: &str) -> Result<(i64, i64, i64), String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;
    let viewer_id = read_viewer_id(app)?;

    let gql = "
        query UserLists($userId: Int, $type: MediaType) {
            MediaListCollection(userId: $userId, type: $type) {
                lists {
                    entries {
                        id
                        status
                        score(format: POINT_10_DECIMAL)
                        progress
                        progressVolumes
                        repeat
                        notes
                        customLists
                        startedAt { year month day }
                        completedAt { year month day }
                        updatedAt
                        media {
                            id
                            type
                            format
                            isAdult
                            title { romaji english native }
                            coverImage { large }
                            episodes
                            chapters
                            volumes
                        }
                    }
                }
            }
        }
    ";

    let payload: UserListsPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({
            "query": gql,
            "variables": { "userId": viewer_id, "type": media_type }
        }),
    )?;
    let collection = payload.media_list_collection;

    let local_type = media_type.to_uppercase();
    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;
    connection.execute("BEGIN", []).map_err(|e| e.to_string())?;

    let mut synced = 0i64;
    let mut conflicts = 0i64;
    let mut max_hwm = 0i64;

    for list in &collection.lists {
        for entry in &list.entries {
            let media = &entry.media;

            // Track high-water mark.
            if entry.updated_at > max_hwm {
                max_hwm = entry.updated_at;
            }

            // Conflict detection: if the local entry is dirty AND AniList has
            // a newer updatedAt than what we last pulled, both sides changed.
            #[allow(clippy::type_complexity)]
            let existing: Option<(
                i64,
                Option<i64>,
                Option<String>,
                Option<f64>,
                i64,
                Option<String>,
            )> = connection
                .query_row(
                    "SELECT is_dirty, CAST(ani_list_updated_at AS INTEGER),
                            status, score, progress, notes
                     FROM media_list_entries
                     WHERE media_id = ?1 AND UPPER(media_type) = ?2 AND UPPER(list_kind) = ?2",
                    rusqlite::params![media.id, &local_type],
                    |r| {
                        Ok((
                            r.get(0)?,
                            r.get(1)?,
                            r.get(2)?,
                            r.get(3)?,
                            r.get(4)?,
                            r.get(5)?,
                        ))
                    },
                )
                .optional()
                .map_err(|e| e.to_string())?;

            if let Some((is_dirty, prev_ani_ts, loc_status, loc_score, loc_progress, loc_notes)) =
                existing
            {
                if is_dirty == 1 {
                    let prev = prev_ani_ts.unwrap_or(0);
                    if entry.updated_at > prev {
                        conflicts += 1;
                        let _ = crate::db::log_sync_event(
                            &connection,
                            media.id,
                            "conflict",
                            Some("Remote changed while local edit pending"),
                        );
                        let _ = crate::db::store_pending_conflict(
                            &connection,
                            media.id,
                            &local_type,
                            loc_status.as_deref(),
                            loc_score,
                            loc_progress,
                            loc_notes.as_deref(),
                            &entry.status,
                            entry.score.filter(|&s| s > 0.0),
                            entry.progress,
                            entry.notes.as_deref(),
                        );
                    } else {
                        // Remote unchanged — skip overwrite, log skipped.
                        let _ = crate::db::log_sync_event(
                            &connection,
                            media.id,
                            "skipped",
                            Some("Local dirty, remote unchanged"),
                        );
                    }
                }
            }

            let cover = media.cover_image.as_ref().and_then(|c| c.large.as_deref());
            let is_adult = media.is_adult.unwrap_or(false) as i64;
            let started_iso = entry.started_at.as_ref().and_then(|d| d.to_iso_date());
            let completed_iso = entry.completed_at.as_ref().and_then(|d| d.to_iso_date());
            let cache_payload = json!({
                "id": media.id,
                "type": media.media_type,
                "format": media.format,
                "isAdult": media.is_adult,
                "title": { "romaji": media.title.romaji, "english": media.title.english, "native": media.title.native },
                "coverImage": { "large": cover },
                "episodes": media.episodes,
                "chapters": media.chapters,
                "volumes": media.volumes,
            }).to_string();

            connection.execute(
                "INSERT INTO media_cache (media_id, media_type, title_romaji, title_english, title_native, cover_image, is_adult, payload_json, fetched_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, CURRENT_TIMESTAMP)
                 ON CONFLICT(media_id) DO UPDATE SET
                   media_type    = excluded.media_type,
                   title_romaji  = excluded.title_romaji,
                   title_english = excluded.title_english,
                   title_native  = excluded.title_native,
                   cover_image   = excluded.cover_image,
                   is_adult      = excluded.is_adult,
                   payload_json  = excluded.payload_json,
                   fetched_at    = CURRENT_TIMESTAMP",
                (media.id, &local_type, &media.title.romaji, &media.title.english, &media.title.native, cover, is_adult, &cache_payload),
            ).map_err(|e| e.to_string())?;

            let status = entry.status.to_lowercase();
            let score = entry.score.filter(|&s| s > 0.0);
            let progress_vols = entry.progress_volumes.unwrap_or(0);
            let custom_lists_json =
                serde_json::to_string(&entry.custom_lists.clone().unwrap_or_default())
                    .unwrap_or_else(|_| "[]".to_string());

            connection.execute(
                "INSERT INTO media_list_entries (
                   media_id, media_type, list_kind, anilist_entry_id,
                   status, score, progress, progress_volumes,
                   repeat_count, notes, started_at, completed_at,
                                     custom_lists_json, ani_list_updated_at, is_dirty, source
                                 ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, 0, 'anilist')
                 ON CONFLICT(media_id, media_type, list_kind) DO UPDATE SET
                   anilist_entry_id    = excluded.anilist_entry_id,
                   status              = excluded.status,
                   score               = excluded.score,
                   progress            = excluded.progress,
                   progress_volumes    = excluded.progress_volumes,
                   repeat_count        = excluded.repeat_count,
                   notes               = excluded.notes,
                   started_at          = excluded.started_at,
                   completed_at        = excluded.completed_at,
                                     custom_lists_json   = excluded.custom_lists_json,
                   ani_list_updated_at = excluded.ani_list_updated_at,
                   updated_at          = CURRENT_TIMESTAMP
                 WHERE is_dirty = 0",
                (
                    media.id, &local_type, &local_type, entry.id,
                    &status, score, entry.progress, progress_vols,
                    entry.repeat, &entry.notes, &started_iso, &completed_iso,
                                        &custom_lists_json,
                                        &entry.updated_at.to_string(),
                ),
            ).map_err(|e| e.to_string())?;

            let _ = crate::db::log_sync_event(&connection, media.id, "pulled", None);
            synced += 1;
        }
    }

    connection
        .execute("COMMIT", [])
        .map_err(|e| e.to_string())?;
    Ok((synced, conflicts, max_hwm))
}

/// Pull the user's list from AniList using the paginated `Page.mediaList`
/// endpoint sorted by `UPDATED_TIME_DESC`.  When `since_ts > 0` this acts as
/// an incremental delta sync — pagination stops as soon as the first entry
/// older than `since_ts` is seen, because the rest of the list cannot have
/// updates newer than the high-water mark.  When `since_ts == 0` it pages
/// through the entire list (full sync path used on fresh login / reinstall).
///
/// AniList's GraphQL schema does **not** expose an `updatedAt_greater`
/// argument on `Page.mediaList`, so the filter is applied client-side.
///
/// Returns `(synced, conflicts, max_updated_at)`.
pub fn fetch_user_lists_delta(
    app: &AppHandle,
    media_type: &str,
    since_ts: i64,
) -> Result<(i64, i64, i64), String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;
    let viewer_id = read_viewer_id(app)?;

    // Subtract 1 from since_ts so entries updated *exactly* at the hwm are
    // included (handles the edge case where the last-synced entry has the same
    // timestamp as the filter).
    let since = (since_ts - 1).max(0);

    // NOTE: `customLists(asArray: true)` is required — without the flag
    // AniList returns a `{name: bool}` JSON object that fails to decode into
    // `Vec<String>` (manifests as `[PARSE_ERROR] error decoding response body`).
    const GQL: &str = "
        query DeltaSync($userId: Int, $type: MediaType, $page: Int) {
            Page(page: $page, perPage: 50) {
                pageInfo { hasNextPage }
                mediaList(userId: $userId, type: $type, sort: UPDATED_TIME_DESC) {
                    id
                    status
                    score(format: POINT_10_DECIMAL)
                    progress
                    progressVolumes
                    repeat
                    notes
                    customLists(asArray: true)
                    startedAt { year month day }
                    completedAt { year month day }
                    updatedAt
                    media {
                        id
                        type
                        format
                        isAdult
                        title { romaji english native }
                        coverImage { large }
                        episodes
                        chapters
                        volumes
                        genres
                        duration
                        studios(isMain: true) { nodes { name } }
                    }
                }
            }
        }
    ";

    let local_type = media_type.to_uppercase();
    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    let mut synced = 0i64;
    let mut conflicts = 0i64;
    let mut max_hwm = since_ts;

    // Stop early once we drop below `since` because the list is sorted
    // UPDATED_TIME_DESC — any subsequent page can only contain older entries.
    let mut reached_hwm = false;
    for page in 1i32..=200 {
        let payload: DeltaListPayload = graphql_post(
            &config.graphql_url,
            &access_token,
            &json!({
                "query": GQL,
                "variables": {
                    "userId": viewer_id,
                    "type": media_type,
                    "page": page
                }
            }),
        )?;

        let has_next = payload.page.page_info.has_next_page;
        let entries = payload.page.media_list;

        if entries.is_empty() && !has_next {
            break;
        }

        connection.execute("BEGIN", []).map_err(|e| e.to_string())?;

        for entry in &entries {
            // Client-side delta filter: skip entries we already have at the
            // current high-water mark or older.  `since == 0` means full sync
            // and includes everything.
            if since > 0 && entry.updated_at <= since {
                reached_hwm = true;
                continue;
            }

            let media = &entry.media;

            if entry.updated_at > max_hwm {
                max_hwm = entry.updated_at;
            }

            // Conflict detection (same as full sync).
            #[allow(clippy::type_complexity)]
            let existing: Option<(
                i64,
                Option<i64>,
                Option<String>,
                Option<f64>,
                i64,
                Option<String>,
            )> = connection
                .query_row(
                    "SELECT is_dirty, CAST(ani_list_updated_at AS INTEGER),
                            status, score, progress, notes
                     FROM media_list_entries
                     WHERE media_id = ?1 AND UPPER(media_type) = ?2 AND UPPER(list_kind) = ?2",
                    rusqlite::params![media.id, &local_type],
                    |r| {
                        Ok((
                            r.get(0)?,
                            r.get(1)?,
                            r.get(2)?,
                            r.get(3)?,
                            r.get(4)?,
                            r.get(5)?,
                        ))
                    },
                )
                .optional()
                .map_err(|e| e.to_string())?;

            if let Some((is_dirty, prev_ani_ts, loc_status, loc_score, loc_progress, loc_notes)) =
                existing
            {
                if is_dirty == 1 {
                    let prev = prev_ani_ts.unwrap_or(0);
                    if entry.updated_at > prev {
                        conflicts += 1;
                        let _ = crate::db::log_sync_event(
                            &connection,
                            media.id,
                            "conflict",
                            Some("Remote changed while local edit pending"),
                        );
                        let _ = crate::db::store_pending_conflict(
                            &connection,
                            media.id,
                            &local_type,
                            loc_status.as_deref(),
                            loc_score,
                            loc_progress,
                            loc_notes.as_deref(),
                            &entry.status,
                            entry.score.filter(|&s| s > 0.0),
                            entry.progress,
                            entry.notes.as_deref(),
                        );
                    }
                }
            }

            let cover = media.cover_image.as_ref().and_then(|c| c.large.as_deref());
            let is_adult = media.is_adult.unwrap_or(false) as i64;
            let started_iso = entry.started_at.as_ref().and_then(|d| d.to_iso_date());
            let completed_iso = entry.completed_at.as_ref().and_then(|d| d.to_iso_date());
            let studios_payload: Vec<serde_json::Value> = media
                .studios
                .as_ref()
                .map(|s| s.nodes.iter().map(|n| json!({ "name": n.name })).collect())
                .unwrap_or_default();
            let cache_payload = json!({
                "id": media.id,
                "type": media.media_type,
                "format": media.format,
                "isAdult": media.is_adult,
                "title": { "romaji": media.title.romaji, "english": media.title.english, "native": media.title.native },
                "coverImage": { "large": cover },
                "episodes": media.episodes,
                "chapters": media.chapters,
                "volumes": media.volumes,
                "genres": media.genres,
                "duration": media.duration,
                "studios": studios_payload,
            }).to_string();

            connection.execute(
                "INSERT INTO media_cache (media_id, media_type, title_romaji, title_english, title_native, cover_image, is_adult, payload_json, fetched_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, CURRENT_TIMESTAMP)
                 ON CONFLICT(media_id) DO UPDATE SET
                   media_type    = excluded.media_type,
                   title_romaji  = excluded.title_romaji,
                   title_english = excluded.title_english,
                   title_native  = excluded.title_native,
                   cover_image   = excluded.cover_image,
                   is_adult      = excluded.is_adult,
                   payload_json  = excluded.payload_json,
                   fetched_at    = CURRENT_TIMESTAMP",
                (media.id, &local_type, &media.title.romaji, &media.title.english, &media.title.native, cover, is_adult, &cache_payload),
            ).map_err(|e| e.to_string())?;

            let status = entry.status.to_lowercase();
            let score = entry.score.filter(|&s| s > 0.0);
            let progress_vols = entry.progress_volumes.unwrap_or(0);
            let custom_lists_json = serde_json::to_string(&entry.enabled_custom_list_names())
                .unwrap_or_else(|_| "[]".to_string());

            connection.execute(
                "INSERT INTO media_list_entries (
                   media_id, media_type, list_kind, anilist_entry_id,
                   status, score, progress, progress_volumes,
                   repeat_count, notes, started_at, completed_at,
                                     custom_lists_json, ani_list_updated_at, is_dirty, source
                                 ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, 0, 'anilist')
                 ON CONFLICT(media_id, media_type, list_kind) DO UPDATE SET
                   anilist_entry_id    = excluded.anilist_entry_id,
                   status              = excluded.status,
                   score               = excluded.score,
                   progress            = excluded.progress,
                   progress_volumes    = excluded.progress_volumes,
                   repeat_count        = excluded.repeat_count,
                   notes               = excluded.notes,
                   started_at          = excluded.started_at,
                   completed_at        = excluded.completed_at,
                                     custom_lists_json   = excluded.custom_lists_json,
                   ani_list_updated_at = excluded.ani_list_updated_at,
                   updated_at          = CURRENT_TIMESTAMP
                 WHERE is_dirty = 0",
                (
                    media.id, &local_type, &local_type, entry.id,
                    &status, score, entry.progress, progress_vols,
                    entry.repeat, &entry.notes, &started_iso, &completed_iso,
                                        &custom_lists_json,
                                        &entry.updated_at.to_string(),
                ),
            ).map_err(|e| e.to_string())?;

            let _ = crate::db::log_sync_event(&connection, media.id, "pulled", Some("delta"));
            synced += 1;
        }

        connection
            .execute("COMMIT", [])
            .map_err(|e| e.to_string())?;

        // Update live progress so the UI can show "Pulling anime · page N
        // (X entries)" instead of a frozen "Syncing..." button on long syncs.
        update_sync_progress(|p| {
            p.phase = media_type.to_lowercase();
            p.page = page;
            p.entries = synced;
            p.total_entries += entries.len() as i64;
            p.message = format!(
                "Pulling {} · page {page} ({synced} entries)",
                media_type.to_lowercase()
            );
        });

        // Delta short-circuit: as soon as one entry on this page was older
        // than the HWM, every following page can only be older still.
        if reached_hwm || !has_next {
            break;
        }
    }

    Ok((synced, conflicts, max_hwm))
}

/// Smart sync: push dirty entries first, then pull from AniList using the
/// paginated `Page.mediaList` path.  When no high-water mark exists (fresh
/// login, reinstall, or empty library) the pull starts from `since = 0`,
/// which still uses pagination — avoiding the single-request
/// `MediaListCollection` query that fails for users with large libraries
/// (complexity / timeout limits on the AniList side).
///
/// Errors from both pulls are surfaced to the caller instead of being
/// silently swallowed: if nothing was pushed *and* both pulls failed, the
/// underlying error is returned so the frontend can display a real message
/// instead of a misleading "Up to date".
pub fn sync_lists_smart(app: &AppHandle) -> Result<SyncSummary, String> {
    // Publish a live progress snapshot so the UI can show real feedback
    // ("Pulling anime · page N · X entries") on long syncs instead of a
    // frozen "Syncing..." button — particularly important on mobile, where
    // a 2.5k-entry library takes ~2 minutes under the 30 req/min rate limit.
    begin_sync_progress("pushing");
    let _progress_guard = SyncProgressGuard;

    // 1. Push all locally-dirty entries before pulling so the pull does not
    //    overwrite edits we have not uploaded yet.
    let push = push_dirty_entries(app).unwrap_or(SyncSummary {
        synced: 0,
        pushed: 0,
        failed: 0,
        conflicts: 0,
        is_delta: false,
        last_synced_at: String::new(),
    });

    // 2. Decide on `since` and whether this counts as a delta sync.
    // Force a full sync (since = 0) when the local library is empty even if a
    // HWM exists (covers reinstalls / DB resets where the settings table
    // survived but media_list_entries was cleared).
    let hwm = crate::db::get_sync_high_water(app).unwrap_or(None);
    let library_empty = crate::db::get_library_snapshot(app)
        .map(|s| s.total_entries == 0)
        .unwrap_or(true);
    let effective_hwm = hwm.filter(|_| !library_empty);
    let since = effective_hwm.unwrap_or(0);
    let is_delta = effective_hwm.is_some();

    // 3. Pull both media types using the paginated path. Track the first
    //    error so it can be surfaced if nothing else succeeded.
    update_sync_progress(|p| {
        p.phase = "anime".into();
        p.page = 0;
        p.entries = 0;
        p.message = "Pulling anime…".into();
    });
    let mut pull_error: Option<String> = None;
    let (a, ac, ah) = match fetch_user_lists_delta(app, "ANIME", since) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("[SYNC] anime pull failed: {e}");
            pull_error.get_or_insert(e);
            (0, 0, since)
        }
    };
    update_sync_progress(|p| {
        p.phase = "manga".into();
        p.page = 0;
        p.entries = 0;
        p.message = "Pulling manga…".into();
    });
    let (m, mc, mh) = match fetch_user_lists_delta(app, "MANGA", since) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("[SYNC] manga pull failed: {e}");
            pull_error.get_or_insert(e);
            (0, 0, since)
        }
    };
    let synced = a + m;
    let conflicts = ac + mc;
    let new_hwm = ah.max(mh);

    // 4. If the pull contributed nothing AND an error was captured, propagate
    //    it so the user sees the real reason (timeout / GraphQL / auth).
    //    A successful push alone is still considered a successful sync.
    if synced == 0 && push.pushed == 0 && push.failed == 0 {
        if let Some(err) = pull_error {
            return Err(err);
        }
    }

    // 5. Persist new high-water mark (only advance it, never go backwards).
    if new_hwm > hwm.unwrap_or(0) {
        let _ = crate::db::set_sync_high_water(app, new_hwm);
    }

    // 6. Record last-synced timestamp.
    let last_synced_at = crate::db::set_last_synced_at(app).unwrap_or_default();

    Ok(SyncSummary {
        synced,
        pushed: push.pushed,
        failed: push.failed,
        conflicts,
        is_delta,
        last_synced_at,
    })
}

// ─── Media search ─────────────────────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
pub fn search_media(
    app: &AppHandle,
    query: &str,
    media_type: &str,
    genres_in: Option<Vec<String>>,
    genres_not_in: Option<Vec<String>>,
    tags_in: Option<Vec<String>>,
    tags_not_in: Option<Vec<String>>,
    format_in: Option<Vec<String>>,
    status_filter: Option<String>,
    sort: Option<String>,
    year_greater: Option<i32>,
    year_lesser: Option<i32>,
    minimum_tag_rank: Option<i32>,
    is_adult: Option<bool>,
) -> Result<Vec<crate::models::MediaSearchResult>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    let gql = r#"
        query SearchMedia(
            $search: String
            $type: MediaType
            $genre_in: [String]
            $genre_not_in: [String]
            $tag_in: [String]
            $tag_not_in: [String]
            $format_in: [MediaFormat]
            $status: MediaStatus
            $sort: [MediaSort]
            $startDate_greater: FuzzyDateInt
            $startDate_lesser: FuzzyDateInt
            $minimumTagRank: Int
            $isAdult: Boolean
        ) {
            Page(page: 1, perPage: 50) {
                media(
                    search: $search
                    type: $type
                    genre_in: $genre_in
                    genre_not_in: $genre_not_in
                    tag_in: $tag_in
                    tag_not_in: $tag_not_in
                    format_in: $format_in
                    status: $status
                    sort: $sort
                    startDate_greater: $startDate_greater
                    startDate_lesser: $startDate_lesser
                    minimumTagRank: $minimumTagRank
                    isAdult: $isAdult
                ) {
                    id
                    type
                    format
                    isAdult
                    title { romaji english }
                    coverImage { large }
                    status
                    episodes
                    chapters
                    genres
                    averageScore
                }
            }
        }
    "#;

    let mut vars = serde_json::Map::new();
    if !query.is_empty() {
        vars.insert("search".to_string(), json!(query));
    }
    if !media_type.is_empty() {
        vars.insert("type".to_string(), json!(media_type));
    }
    if let Some(v) = genres_in {
        if !v.is_empty() {
            vars.insert("genre_in".to_string(), json!(v));
        }
    }
    if let Some(v) = genres_not_in {
        if !v.is_empty() {
            vars.insert("genre_not_in".to_string(), json!(v));
        }
    }
    if let Some(v) = tags_in {
        if !v.is_empty() {
            vars.insert("tag_in".to_string(), json!(v));
        }
    }
    if let Some(v) = tags_not_in {
        if !v.is_empty() {
            vars.insert("tag_not_in".to_string(), json!(v));
        }
    }
    if let Some(v) = format_in {
        if !v.is_empty() {
            vars.insert("format_in".to_string(), json!(v));
        }
    }
    if let Some(s) = status_filter {
        vars.insert("status".to_string(), json!(s));
    }
    vars.insert(
        "sort".to_string(),
        json!([sort.unwrap_or_else(|| "SEARCH_MATCH".to_string())]),
    );
    if let Some(y) = year_greater {
        vars.insert("startDate_greater".to_string(), json!(y * 10000));
    }
    if let Some(y) = year_lesser {
        vars.insert("startDate_lesser".to_string(), json!(y * 10000 + 9999));
    }
    if let Some(r) = minimum_tag_rank {
        if r > 0 {
            vars.insert("minimumTagRank".to_string(), json!(r));
        }
    }
    if let Some(a) = is_adult {
        vars.insert("isAdult".to_string(), json!(a));
    }

    let payload: SearchPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": gql, "variables": vars }),
    )?;
    let media_list = payload.page.media;

    let database_path = crate::db::database_path(app)?;
    let conn = crate::db::open_connection(&database_path)?;

    let results = media_list
        .into_iter()
        .map(|m| {
            let local_type = m.media_type.to_lowercase();
            let title = m
                .title
                .english
                .filter(|s| !s.is_empty())
                .or(m.title.romaji)
                .unwrap_or_else(|| format!("Media {}", m.id));
            let cover = m.cover_image.and_then(|c| c.large);
            let in_library = conn
                .query_row(
                    "SELECT 1 FROM media_list_entries WHERE media_id = ?1 LIMIT 1",
                    [m.id],
                    |_| Ok(true),
                )
                .optional()
                .unwrap_or(None)
                .unwrap_or(false);

            crate::models::MediaSearchResult {
                media_id: m.id,
                media_type: local_type,
                title,
                cover_image: cover,
                format: m.format,
                status: m.status,
                episodes: m.episodes,
                chapters: m.chapters,
                genres: m.genres,
                average_score: m.average_score,
                is_adult: m.is_adult.unwrap_or(false),
                in_library,
            }
        })
        .collect();

    Ok(results)
}

pub fn get_trending_media(
    app: &AppHandle,
    page: i32,
) -> Result<Vec<crate::models::MediaSearchResult>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    let gql = r#"
        query DiscoveryTrending($page: Int) {
            Page(page: $page, perPage: 10) {
                media(type: ANIME, sort: [TRENDING_DESC]) {
                    id
                    type
                    format
                    isAdult
                    title { romaji english }
                    coverImage { large }
                    status
                    episodes
                    chapters
                    genres
                    averageScore
                }
            }
        }
    "#;

    let payload: SearchPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": gql, "variables": { "page": page.max(1) } }),
    )?;

    let database_path = crate::db::database_path(app)?;
    let conn = crate::db::open_connection(&database_path)?;

    let results = payload
        .page
        .media
        .into_iter()
        .map(|m| {
            let local_type = m.media_type.to_lowercase();
            let title = m
                .title
                .english
                .filter(|s| !s.is_empty())
                .or(m.title.romaji)
                .unwrap_or_else(|| format!("Media {}", m.id));
            let cover = m.cover_image.and_then(|c| c.large);
            let in_library = conn
                .query_row(
                    "SELECT 1 FROM media_list_entries WHERE media_id = ?1 LIMIT 1",
                    [m.id],
                    |_| Ok(true),
                )
                .optional()
                .unwrap_or(None)
                .unwrap_or(false);

            crate::models::MediaSearchResult {
                media_id: m.id,
                media_type: local_type,
                title,
                cover_image: cover,
                format: m.format,
                status: m.status,
                episodes: m.episodes,
                chapters: m.chapters,
                genres: m.genres,
                average_score: m.average_score,
                is_adult: m.is_adult.unwrap_or(false),
                in_library,
            }
        })
        .collect();

    Ok(results)
}

pub fn fetch_notifications(
    app: &AppHandle,
    type_filter: Option<String>,
    page: i32,
    per_page: i32,
    reset_unread_count: bool,
) -> Result<Vec<AniListNotificationItem>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const GQL: &str = r#"
        query Notifications($page: Int, $perPage: Int, $typeIn: [NotificationType], $reset: Boolean) {
          Page(page: $page, perPage: $perPage) {
            notifications(type_in: $typeIn, resetNotificationCount: $reset) {
              ... on AiringNotification {
                id type episode contexts createdAt
                media { id type title { romaji english } coverImage { large } }
              }
              ... on FollowingNotification {
                id type context createdAt
                user { id name avatar { large } }
              }
              ... on ActivityMessageNotification {
                id type context createdAt activityId
                user { id name avatar { large } }
              }
              ... on ActivityMentionNotification {
                id type context createdAt activityId
                user { id name avatar { large } }
              }
              ... on ActivityReplyNotification {
                id type context createdAt activityId
                user { id name avatar { large } }
              }
              ... on ActivityReplySubscribedNotification {
                id type context createdAt activityId
                user { id name avatar { large } }
              }
              ... on ActivityLikeNotification {
                id type context createdAt activityId
                user { id name avatar { large } }
              }
              ... on ActivityReplyLikeNotification {
                id type context createdAt activityId
                user { id name avatar { large } }
              }
              ... on ThreadCommentMentionNotification {
                id type context createdAt commentId
                user { id name avatar { large } }
                thread { id title }
              }
              ... on ThreadCommentReplyNotification {
                id type context createdAt commentId
                user { id name avatar { large } }
                thread { id title }
              }
                            ... on ThreadCommentSubscribedNotification {
                id type context createdAt commentId
                user { id name avatar { large } }
                thread { id title }
              }
              ... on ThreadCommentLikeNotification {
                id type context createdAt commentId
                user { id name avatar { large } }
                thread { id title }
              }
              ... on RelatedMediaAdditionNotification {
                id type context createdAt mediaId
                media { id type title { romaji english } coverImage { large } }
              }
              ... on MediaDataChangeNotification {
                id type context reason createdAt mediaId
                media { id type title { romaji english } coverImage { large } }
              }
                            ... on MediaMergeNotification {
                                id type context reason createdAt mediaId deletedMediaTitles
                media { id type title { romaji english } coverImage { large } }
              }
              ... on MediaDeletionNotification {
                id type context reason createdAt deletedMediaTitle
              }
            }
          }
        }
    "#;

    fn str_at(node: &Value, path: &[&str]) -> Option<String> {
        let mut cur = node;
        for key in path {
            cur = cur.get(*key)?;
        }
        cur.as_str().map(|s| s.to_string())
    }

    fn i64_at(node: &Value, path: &[&str]) -> Option<i64> {
        let mut cur = node;
        for key in path {
            cur = cur.get(*key)?;
        }
        cur.as_i64()
    }

    fn media_link(media_type: Option<String>, media_id: i64) -> String {
        let kind = match media_type.as_deref() {
            Some("MANGA") => "manga",
            _ => "anime",
        };
        format!("https://anilist.co/{kind}/{media_id}")
    }

    fn category_types(category: &str) -> Vec<&'static str> {
        match category {
            "AIRING" => vec!["AIRING"],
            "ACTIVITY" => vec![
                "ACTIVITY_MESSAGE",
                "ACTIVITY_MENTION",
                "ACTIVITY_REPLY",
                "ACTIVITY_REPLY_SUBSCRIBED",
                "ACTIVITY_LIKE",
                "ACTIVITY_REPLY_LIKE",
            ],
            "FORUM" => vec![
                "THREAD_COMMENT_MENTION",
                "THREAD_COMMENT_REPLY",
                "THREAD_SUBSCRIBED",
                "THREAD_COMMENT_LIKE",
            ],
            "FOLLOWS" => vec!["FOLLOWING"],
            "MEDIA" => vec![
                "RELATED_MEDIA_ADDITION",
                "MEDIA_DATA_CHANGE",
                "MEDIA_MERGE",
                "MEDIA_DELETION",
            ],
            "SUBMISSIONS" => vec!["MEDIA_DATA_CHANGE"],
            _ => vec![],
        }
    }

    let filter = type_filter
        .as_deref()
        .map(|t| t.trim().to_uppercase())
        .unwrap_or_else(|| "ALL".to_string());

    let mut raw_nodes: Vec<Value> = Vec::new();

    let request_page = page.max(1);
    let request_per_page = per_page.clamp(1, 50);

    let fetch_batch = |types: Vec<&str>, reset: bool| -> Result<Vec<Value>, String> {
        let payload: NotificationsPayload = graphql_post(
            &config.graphql_url,
            &access_token,
            &json!({
                "query": GQL,
                "variables": {
                    "page": request_page,
                    "perPage": request_per_page,
                    "typeIn": types,
                    "reset": reset,
                }
            }),
        )?;
        Ok(payload.page.notifications)
    };

    if filter == "ALL" {
        // AniList occasionally fails with 500 on very broad notifications
        // requests. Fetch by category and merge for stability.
        for category in ["AIRING", "ACTIVITY", "FORUM", "FOLLOWS", "MEDIA"] {
            let mut batch = fetch_batch(category_types(category), reset_unread_count)?;
            raw_nodes.append(&mut batch);
        }
    } else {
        raw_nodes = fetch_batch(category_types(&filter), reset_unread_count)?;
    }

    let mut seen = HashSet::new();
    let mut items = Vec::new();
    for node in raw_nodes {
        let notification_type = str_at(&node, &["type"]).unwrap_or_else(|| "UNKNOWN".to_string());
        let id = i64_at(&node, &["id"]).unwrap_or_default();
        if id != 0 && !seen.insert(id) {
            continue;
        }

        let created_at = i64_at(&node, &["createdAt"]).unwrap_or_default();
        let context = str_at(&node, &["context"])
            .or_else(|| str_at(&node, &["contexts"]))
            .unwrap_or_else(|| "New notification".to_string());

        let media_id = i64_at(&node, &["media", "id"]).or_else(|| i64_at(&node, &["mediaId"]));
        let media_title = str_at(&node, &["media", "title", "english"])
            .or_else(|| str_at(&node, &["media", "title", "romaji"]));
        let cover_image = str_at(&node, &["media", "coverImage", "large"]);

        let user_name = str_at(&node, &["user", "name"]);
        let user_avatar = str_at(&node, &["user", "avatar", "large"]);
        let activity_id = i64_at(&node, &["activityId"]);
        let comment_id = i64_at(&node, &["commentId"]);
        let thread_id = i64_at(&node, &["thread", "id"]);

        let link = if let Some(mid) = media_id {
            Some(media_link(str_at(&node, &["media", "type"]), mid))
        } else if let Some(aid) = activity_id {
            Some(format!("https://anilist.co/activity/{aid}"))
        } else if let Some(cid) = comment_id {
            Some(format!("https://anilist.co/forum/comment/{cid}"))
        } else if let Some(tid) = thread_id {
            Some(format!("https://anilist.co/forum/thread/{tid}"))
        } else if let Some(name) = user_name.clone() {
            Some(format!("https://anilist.co/user/{name}"))
        } else {
            Some("https://anilist.co/notifications".to_string())
        };

        let episode = i64_at(&node, &["episode"]);
        let reason = str_at(&node, &["reason"]);
        let deleted_title = str_at(&node, &["deletedMediaTitle"]).or_else(|| {
            node.get("deletedMediaTitles")
                .and_then(|v| v.as_array())
                .and_then(|arr| arr.first())
                .and_then(|v| v.as_str())
                .map(|s| s.to_string())
        });

        let title = match notification_type.as_str() {
            "AIRING" => {
                let t = media_title.unwrap_or_else(|| "Unknown title".to_string());
                if let Some(ep) = episode {
                    format!("{t} — Episode {ep} aired")
                } else {
                    format!("{t} — Airing update")
                }
            }
            "FOLLOWING" => format!(
                "{} followed you",
                user_name.clone().unwrap_or_else(|| "Someone".to_string())
            ),
            "MEDIA_DATA_CHANGE" | "MEDIA_MERGE" | "MEDIA_DELETION" | "RELATED_MEDIA_ADDITION" => {
                media_title
                    .or(deleted_title)
                    .unwrap_or_else(|| "Media update".to_string())
            }
            _ => context.clone(),
        };

        let body = reason
            .or_else(|| str_at(&node, &["thread", "title"]))
            .unwrap_or(context.clone());

        let text_lower = format!("{} {}", context.to_lowercase(), body.to_lowercase());
        let is_submission_like = text_lower.contains("submission")
            || text_lower.contains("accepted")
            || text_lower.contains("rejected");

        if filter == "SUBMISSIONS" && !is_submission_like {
            continue;
        }
        if filter == "MEDIA" && is_submission_like {
            continue;
        }

        items.push(AniListNotificationItem {
            id,
            notification_type,
            created_at,
            is_read: false,
            title,
            body,
            link,
            media_id,
            cover_image,
            user_name,
            user_avatar,
        });
    }

    items.sort_by_key(|b| std::cmp::Reverse(b.created_at));
    if items.len() > request_per_page as usize {
        items.truncate(request_per_page as usize);
    }

    Ok(items)
}

// ─── Save / update list entry ────────────────────────────────────────────────

/// Push all locally-dirty entries (`is_dirty = 1`) to AniList.  Each
/// successful push clears the `is_dirty` flag so the same entry is not
/// re-sent on the next sync.  Errors are logged but do not abort the loop —
/// remaining entries are still attempted.
pub fn push_dirty_entries(app: &AppHandle) -> Result<crate::models::SyncSummary, String> {
    let dirty = crate::db::get_dirty_entries(app)?;
    let mut pushed = 0i64;
    let mut failed = 0i64;
    for (
        local_id,
        media_id,
        status,
        score,
        progress,
        progress_volumes,
        repeat_count,
        started_at,
        completed_at,
        notes,
        custom_lists,
    ) in dirty
    {
        match save_media_list_entry(
            app,
            media_id,
            &status,
            score,
            progress,
            progress_volumes,
            repeat_count,
            started_at,
            completed_at,
            notes,
            Some(custom_lists),
        ) {
            Ok(()) => {
                let _ = crate::db::clear_entry_dirty(app, local_id);
                pushed += 1;
            }
            Err(e) => {
                eprintln!("[PUSH_DIRTY] media {media_id}: {e}");
                failed += 1;
            }
        }
    }
    Ok(crate::models::SyncSummary {
        synced: 0,
        pushed,
        failed,
        conflicts: 0,
        is_delta: false,
        last_synced_at: String::new(),
    })
}

// ─── Airing schedule ─────────────────────────────────────────────────────────

/// Fetches upcoming airing episodes from AniList for all anime in the user's
/// CURRENT list and stores them in `airing_cache`.  On desktop there is no
/// background process; callers trigger this explicitly (app start / manual
/// refresh).  The `airing_cache` table then acts as the offline source of
/// truth for the Schedule screen.
///
/// Fetches up to 50 upcoming episodes across all currently-watching anime.
/// Only airing episodes that have not yet aired (`notYetAired: true`) are
/// fetched; past episodes already in the cache are preserved.
pub fn fetch_airing_schedule(app: &AppHandle) -> Result<i64, String> {
    // Collect media IDs for all CURRENT anime in the user's library.
    let database_path = crate::db::database_path(app)?;
    let conn = crate::db::open_connection(&database_path)?;

    let mut id_stmt = conn
        .prepare(
            "SELECT DISTINCT media_id FROM media_list_entries
             WHERE UPPER(media_type) = 'ANIME'
               AND status IN ('current', 'repeating')",
        )
        .map_err(|e| e.to_string())?;

    let media_ids: Vec<i64> = id_stmt
        .query_map([], |row| row.get::<_, i64>(0))
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    if media_ids.is_empty() {
        return Ok(0);
    }

    let config = load_config()?;
    let access_token = read_access_token(app)?;

    // AniList accepts mediaId_in as an array variable.
    let gql = "
        query AiringSchedule($ids: [Int], $page: Int) {
            Page(page: $page, perPage: 50) {
                airingSchedules(mediaId_in: $ids, notYetAired: true, sort: [TIME]) {
                    episode
                    airingAt
                    media {
                        id
                        title { romaji english }
                        coverImage { large }
                        episodes
                    }
                }
            }
        }
    ";

    let ids_json: Vec<serde_json::Value> = media_ids.iter().map(|id| json!(id)).collect();
    let payload: AiringSchedulePayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": gql, "variables": { "ids": ids_json, "page": 1 } }),
    )?;

    let schedules = payload.page.airing_schedules;
    let stored = schedules.len() as i64;

    conn.execute("BEGIN", []).map_err(|e| e.to_string())?;
    for s in &schedules {
        let cover = s
            .media
            .cover_image
            .as_ref()
            .and_then(|c| c.large.as_deref());
        let payload_json = json!({
            "title": { "romaji": s.media.title.romaji, "english": s.media.title.english },
            "coverImage": { "large": cover },
            "episodes": s.media.episodes,
        })
        .to_string();

        conn.execute(
            "INSERT INTO airing_cache (media_id, episode, airing_at, payload_json, notified, updated_at)
             VALUES (?1, ?2, ?3, ?4, 0, CURRENT_TIMESTAMP)
             ON CONFLICT(media_id, episode) DO UPDATE SET
               airing_at    = excluded.airing_at,
               payload_json = excluded.payload_json,
               updated_at   = CURRENT_TIMESTAMP",
            (s.media.id, s.episode, s.airing_at, &payload_json),
        )
        .map_err(|e| e.to_string())?;

        // Keep media_cache cover + title fresh so schedule joins work.
        conn.execute(
            "INSERT INTO media_cache (media_id, media_type, title_romaji, title_english, cover_image, payload_json, fetched_at)
             VALUES (?1, 'ANIME', ?2, ?3, ?4, '{}', CURRENT_TIMESTAMP)
             ON CONFLICT(media_id) DO UPDATE SET
               title_romaji  = COALESCE(excluded.title_romaji,  title_romaji),
               title_english = COALESCE(excluded.title_english, title_english),
               cover_image   = COALESCE(excluded.cover_image,   cover_image),
               fetched_at    = CURRENT_TIMESTAMP",
            (s.media.id, &s.media.title.romaji, &s.media.title.english, cover),
        )
        .map_err(|e| e.to_string())?;
    }
    conn.execute("COMMIT", []).map_err(|e| e.to_string())?;

    Ok(stored)
}

/// Fetch a global AniChart-like schedule for all not-yet-aired anime in the
/// next few days. If `weekday` is provided, it is interpreted as 1=Mon..7=Sun
/// and only entries for that weekday are returned.
pub fn get_global_airing_schedule(
    app: &AppHandle,
    weekday: Option<u8>,
) -> Result<Vec<GlobalAiringEntry>, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    const GQL: &str = r#"
        query GlobalAiring($page: Int, $from: Int, $to: Int) {
            Page(page: $page, perPage: 50) {
                pageInfo { hasNextPage }
                airingSchedules(notYetAired: true, airingAt_greater: $from, airingAt_lesser: $to, sort: [TIME]) {
                    episode
                    airingAt
                    media {
                        id
                        title { romaji english }
                        coverImage { large }
                        episodes
                        format
                        popularity
                    }
                }
            }
        }
    "#;

    let now_secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_err(|e| e.to_string())?
        .as_secs() as i64;
    let horizon_secs = now_secs + 7 * 24 * 60 * 60;

    let mut result: Vec<GlobalAiringEntry> = Vec::new();
    for page in 1..=6 {
        let data: AiringSchedulePayload = graphql_post(
            &config.graphql_url,
            &access_token,
            &json!({
                "query": GQL,
                "variables": {
                    "page": page,
                    "from": now_secs,
                    "to": horizon_secs,
                }
            }),
        )?;

        for entry in data.page.airing_schedules {
            if let Some(target_day) = weekday {
                let days = entry.airing_at.div_euclid(86_400);
                let weekday_num = ((days + 3).rem_euclid(7) + 1) as u8;
                if weekday_num != target_day {
                    continue;
                }
            }

            result.push(GlobalAiringEntry {
                media_id: entry.media.id,
                title: entry
                    .media
                    .title
                    .english
                    .clone()
                    .or(entry.media.title.romaji.clone())
                    .unwrap_or_else(|| format!("Media {}", entry.media.id)),
                cover_image: entry.media.cover_image.and_then(|c| c.large),
                episode: entry.episode,
                airing_at: entry.airing_at,
                format: entry.media.format,
                popularity: entry.media.popularity,
            });
        }

        if !data
            .page
            .page_info
            .as_ref()
            .map(|p| p.has_next_page)
            .unwrap_or(false)
        {
            break;
        }
    }

    Ok(result)
}

#[allow(clippy::too_many_arguments)]
pub fn save_media_list_entry(
    app: &AppHandle,
    media_id: i64,
    status: &str,
    score: Option<f64>,
    progress: i64,
    progress_volumes: i64,
    repeat: i64,
    start_date: Option<String>,
    completed_date: Option<String>,
    notes: Option<String>,
    custom_lists: Option<Vec<String>>,
) -> Result<(), String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    let ani_status = match status {
        "current" => "CURRENT",
        "planning" => "PLANNING",
        "completed" => "COMPLETED",
        "dropped" => "DROPPED",
        "paused" => "PAUSED",
        "repeating" => "REPEATING",
        other => return Err(format!("Unknown list status: {other}")),
    };

    fn parse_fuzzy_date(date_str: &str) -> serde_json::Value {
        let parts: Vec<&str> = date_str.split('-').collect();
        json!({
            "year":  parts.first().and_then(|s| s.parse::<i64>().ok()),
            "month": parts.get(1).and_then(|s| s.parse::<i64>().ok()),
            "day":   parts.get(2).and_then(|s| s.parse::<i64>().ok()),
        })
    }

    let gql = "
        mutation SaveEntry(
            $mediaId: Int, $status: MediaListStatus, $score: Float,
            $progress: Int, $progressVolumes: Int, $repeat: Int,
            $startedAt: FuzzyDateInput, $completedAt: FuzzyDateInput,
            $notes: String, $customLists: [String]
        ) {
            SaveMediaListEntry(
                mediaId: $mediaId, status: $status, score: $score,
                progress: $progress, progressVolumes: $progressVolumes, repeat: $repeat,
                startedAt: $startedAt, completedAt: $completedAt,
                notes: $notes, customLists: $customLists
            ) {
                id
            }
        }
    ";

    let payload: SaveEntryPayload = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({
            "query": gql,
            "variables": {
                "mediaId": media_id,
                "status": ani_status,
                "score": score.unwrap_or(0.0),
                "progress": progress,
                "progressVolumes": progress_volumes,
                "repeat": repeat,
                "startedAt": start_date.as_deref().map(parse_fuzzy_date),
                "completedAt": completed_date.as_deref().map(parse_fuzzy_date),
                "notes": notes,
                "customLists": custom_lists.filter(|v| !v.is_empty()),
            }
        }),
    )?;

    // Store the server-assigned anilist_entry_id so future mutations can
    // reference it directly instead of relying only on media_id.
    let anilist_id = payload.save_media_list_entry.id;
    let database_path = crate::db::database_path(app)?;
    let conn = crate::db::open_connection(&database_path)?;
    conn.execute(
        "UPDATE media_list_entries SET anilist_entry_id = ?1
         WHERE media_id = ?2 AND anilist_entry_id IS NULL",
        (anilist_id, media_id),
    )
    .map_err(|e| e.to_string())?;

    Ok(())
}

pub fn delete_media_list_entry(app: &AppHandle, anilist_entry_id: i64) -> Result<(), String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    let gql = "
        mutation DeleteEntry($id: Int) {
            DeleteMediaListEntry(id: $id) {
                deleted
            }
        }
    ";

    let _: serde_json::Value = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({
            "query": gql,
            "variables": { "id": anilist_entry_id }
        }),
    )?;

    Ok(())
}

fn read_viewer_id(app: &AppHandle) -> Result<i64, String> {
    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;
    connection
        .query_row(
            "SELECT viewer_id FROM auth_session WHERE id = 1",
            [],
            |row| row.get::<_, Option<i64>>(0),
        )
        .map_err(|e| e.to_string())?
        .ok_or_else(|| "[NO_VIEWER_ID] No viewer ID stored. Please sign in first.".to_string())
}

// ─── Media details ────────────────────────────────────────────────────────────

/// Fetch full media details from AniList, serve from local cache if fetched
/// within the last hour. Caches the full payload JSON in `media_cache`.
pub fn fetch_media_details(
    app: &AppHandle,
    media_id: i64,
) -> Result<crate::models::MediaDetails, String> {
    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;

    let parse_cached = |payload: &str, fetched_at: &str| -> Option<crate::models::MediaDetails> {
        let mut model = serde_json::from_str::<crate::models::MediaDetails>(payload).ok()?;
        model.cached_at = fetched_at.to_string();
        model.in_library = connection
            .query_row(
                "SELECT 1 FROM media_list_entries WHERE media_id = ?1 LIMIT 1",
                [media_id],
                |_| Ok(true),
            )
            .optional()
            .ok()
            .flatten()
            .unwrap_or(false);
        Some(model)
    };

    // Check for a recent cache entry that is parseable as the app model.
    let cached: Option<(String, String)> = connection
        .query_row(
            "SELECT payload_json, fetched_at FROM media_cache
         WHERE media_id = ?1 AND datetime(fetched_at, '+1 hour') > CURRENT_TIMESTAMP",
            [media_id],
            |row| Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?)),
        )
        .optional()
        .map_err(|e| e.to_string())?;

    if let Some((ps, fa)) = cached {
        // Older entries (minimal sync payloads without genres/tags, or legacy
        // detail payloads with wrong studios shape) won't parse as MediaDetails.
        // Silently fall through to a fresh AniList fetch in those cases.
        if let Some(model) = parse_cached(&ps, &fa) {
            return Ok(model);
        }
    }

    // Keep stale cache around as an offline fallback if live fetch fails.
    let stale_cached: Option<(String, String)> = connection
        .query_row(
            "SELECT payload_json, fetched_at FROM media_cache WHERE media_id = ?1",
            [media_id],
            |row| Ok((row.get::<_, String>(0)?, row.get::<_, String>(1)?)),
        )
        .optional()
        .map_err(|e| e.to_string())?;

    // Cache miss, stale, or unparseable → fetch fresh from AniList.
    match fetch_and_cache_media_details(app, media_id, &connection) {
        Ok(details) => Ok(details),
        Err(error) => {
            if let Some((payload, fetched_at)) = stale_cached {
                if let Some(model) = parse_cached(&payload, &fetched_at) {
                    return Ok(model);
                }
            }
            Err(error)
        }
    }
}

fn fetch_and_cache_media_details(
    app: &AppHandle,
    media_id: i64,
    connection: &Connection,
) -> Result<crate::models::MediaDetails, String> {
    let config = load_config()?;
    let access_token = read_access_token(app)?;

    let gql = "
        query MediaDetails($id: Int) {
            Media(id: $id) {
                id type format status
                isAdult
                title { romaji english native }
                description(asHtml: false)
                coverImage { extraLarge large }
                bannerImage
                episodes chapters volumes duration
                season seasonYear source
                genres averageScore popularity favourites
                tags { name category rank isGeneralSpoiler }
                studios { nodes { id name isAnimationStudio } }
                nextAiringEpisode { episode airingAt }
                startDate { year month day }
                endDate { year month day }
                relations {
                    edges {
                        relationType
                        node {
                            id type format status
                            title { romaji english }
                            coverImage { large }
                        }
                    }
                }
                characters(perPage: 25, sort: ROLE) {
                    edges {
                        role
                        node {
                            id
                            name { full }
                            image { large }
                        }
                    }
                }
                staff(perPage: 25) {
                    edges {
                        role
                        node {
                            id
                            name { full }
                            image { large }
                        }
                    }
                }
                recommendations(perPage: 10, sort: RATING_DESC) {
                    nodes {
                        rating
                        mediaRecommendation {
                            id format meanScore
                            title { romaji english }
                            coverImage { large }
                        }
                    }
                }
                externalLinks { url site type }
            }
        }
    ";

    let node: MediaDetailsNode = graphql_post(
        &config.graphql_url,
        &access_token,
        &json!({ "query": gql, "variables": { "id": media_id } }),
    )
    .map(|p: MediaDetailsPayload| p.media)
    .map_err(|e| format!("[MEDIA_DETAILS_FETCH_FAILED] {e}"))?;

    // Convert to the app model immediately.  Storing the model JSON (rather
    // than a hand-rolled json! blob) guarantees that re-parsing on the next
    // cache read will always succeed — no structural mismatch possible.
    let model = media_details_node_to_model(node, String::new(), false);

    // Serialize the model as the cache payload.
    let payload_str = serde_json::to_string(&model)
        .map_err(|e| format!("[MEDIA_DETAILS_CACHE_SERIALIZE] {e}"))?;

    let is_adult = model.is_adult as i64;

    connection.execute(
        "INSERT INTO media_cache (media_id, media_type, title_romaji, title_english, title_native, cover_image, is_adult, payload_json, fetched_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, CURRENT_TIMESTAMP)
         ON CONFLICT(media_id) DO UPDATE SET
           media_type = excluded.media_type,
           title_romaji = excluded.title_romaji,
           title_english = excluded.title_english,
           title_native = excluded.title_native,
           cover_image = excluded.cover_image,
           is_adult = excluded.is_adult,
           payload_json = excluded.payload_json,
           fetched_at = CURRENT_TIMESTAMP",
        (media_id, model.media_type.as_str(), model.title_romaji.as_deref(), model.title_english.as_deref(), model.title_native.as_deref(), model.cover_image.as_deref(), is_adult, &payload_str),
    ).map_err(|e| e.to_string())?;

    let fetched_at = connection
        .query_row(
            "SELECT fetched_at FROM media_cache WHERE media_id = ?1",
            [media_id],
            |row| row.get::<_, String>(0),
        )
        .unwrap_or_else(|_| String::new());

    let in_library: bool = connection
        .query_row(
            "SELECT 1 FROM media_list_entries WHERE media_id = ?1 LIMIT 1",
            [media_id],
            |_| Ok(true),
        )
        .optional()
        .map_err(|e| e.to_string())?
        .unwrap_or(false);

    let mut result = model;
    result.cached_at = fetched_at;
    result.in_library = in_library;
    Ok(result)
}

fn media_details_node_to_model(
    node: MediaDetailsNode,
    cached_at: String,
    in_library: bool,
) -> crate::models::MediaDetails {
    let cover = node
        .cover_image
        .as_ref()
        .and_then(|c| c.extra_large.clone().or_else(|| c.large.clone()));
    crate::models::MediaDetails {
        media_id: node.id,
        media_type: node.media_type,
        format: node.format,
        status: node.status,
        title_romaji: node.title.romaji,
        title_english: node.title.english,
        title_native: node.title.native,
        description: node.description,
        cover_image: cover,
        banner_image: node.banner_image,
        episodes: node.episodes,
        chapters: node.chapters,
        volumes: node.volumes,
        duration: node.duration,
        season: node.season,
        season_year: node.season_year,
        source: node.source,
        genres: node.genres,
        tags: node
            .tags
            .into_iter()
            .map(|t| crate::models::MediaTag {
                name: t.name,
                category: t.category,
                rank: t.rank,
                is_spoiler: t.is_spoiler.unwrap_or(false),
            })
            .collect(),
        average_score: node.average_score,
        popularity: node.popularity,
        favourites: node.favourites,
        is_adult: node.is_adult.unwrap_or(false),
        studios: node
            .studios
            .map(|s| {
                s.nodes
                    .into_iter()
                    .map(|n| crate::models::MediaStudio {
                        id: n.id,
                        name: n.name,
                        is_animation_studio: n.is_animation_studio,
                    })
                    .collect()
            })
            .unwrap_or_default(),
        next_airing_episode: node.next_airing_episode.map(|a| crate::models::AiringInfo {
            episode: a.episode,
            airing_at: a.airing_at,
        }),
        start_date: node.start_date.and_then(|d| d.to_iso_date()),
        end_date: node.end_date.and_then(|d| d.to_iso_date()),
        cached_at,
        in_library,
        relations: node
            .relations
            .map(|r| {
                r.edges
                    .into_iter()
                    .filter_map(|e| {
                        let rt = e.relation_type?;
                        // Only expose relation types relevant to media browsing.
                        match rt.as_str() {
                            "PREQUEL" | "SEQUEL" | "ALTERNATIVE" | "SPIN_OFF" | "ADAPTATION"
                            | "SIDE_STORY" | "SUMMARY" | "COMPILATION" | "PARENT" => {}
                            _ => return None,
                        }
                        Some(crate::models::MediaRelation {
                            media_id: e.node.id,
                            media_type: e.node.media_type,
                            format: e.node.format,
                            title: e
                                .node
                                .title
                                .english
                                .or(e.node.title.romaji)
                                .unwrap_or_else(|| e.node.id.to_string()),
                            cover_image: e.node.cover_image.and_then(|c| c.large),
                            status: e.node.status,
                            relation_type: rt,
                        })
                    })
                    .collect()
            })
            .unwrap_or_default(),
        characters: node
            .characters
            .map(|c| {
                c.edges
                    .into_iter()
                    .map(|e| crate::models::MediaCharacterEdge {
                        character_id: e.node.id,
                        name: e
                            .node
                            .name
                            .and_then(|n| n.full)
                            .unwrap_or_else(|| e.node.id.to_string()),
                        image: e.node.image.and_then(|i| i.large),
                        role: e.role.unwrap_or_else(|| "SUPPORTING".to_string()),
                    })
                    .collect()
            })
            .unwrap_or_default(),
        staff: node
            .staff
            .map(|s| {
                s.edges
                    .into_iter()
                    .map(|e| crate::models::MediaStaffEdge {
                        staff_id: e.node.id,
                        name: e
                            .node
                            .name
                            .and_then(|n| n.full)
                            .unwrap_or_else(|| e.node.id.to_string()),
                        image: e.node.image.and_then(|i| i.large),
                        role: e.role.unwrap_or_default(),
                    })
                    .collect()
            })
            .unwrap_or_default(),
        recommendations: node
            .recommendations
            .map(|r| {
                r.nodes
                    .into_iter()
                    .filter_map(|n| {
                        let m = n.media_recommendation?;
                        Some(crate::models::MediaRecommendation {
                            media_id: m.id,
                            format: m.format,
                            title: m
                                .title
                                .english
                                .or(m.title.romaji)
                                .unwrap_or_else(|| m.id.to_string()),
                            cover_image: m.cover_image.and_then(|c| c.large),
                            mean_score: m.mean_score,
                            rating: n.rating.unwrap_or(0),
                        })
                    })
                    .collect()
            })
            .unwrap_or_default(),
        external_links: node
            .external_links
            .map(|links| {
                links
                    .into_iter()
                    .map(|l| crate::models::ExternalLink {
                        url: l.url,
                        site: l.site,
                        link_type: l.link_type.unwrap_or_else(|| "INFO".to_string()),
                    })
                    .collect()
            })
            .unwrap_or_default(),
    }
}

// ─── Persist viewer profile ───────────────────────────────────────────────────

fn persist_viewer_profile(
    app: &AppHandle,
    viewer: &crate::models::AniListViewer,
) -> Result<(), String> {
    let database_path = crate::db::database_path(app)?;
    let connection = crate::db::open_connection(&database_path)?;
    let payload = serde_json::json!({
        "id": viewer.id,
        "name": viewer.name,
        "avatarUrl": viewer.avatar_url,
        "scoreFormat": viewer.score_format,
        "animeCustomLists": viewer.anime_custom_lists,
        "mangaCustomLists": viewer.manga_custom_lists,
    })
    .to_string();

    connection
        .execute(
            "
            INSERT INTO user_profile_cache (
                user_id, name, avatar_url, payload_json, fetched_at
            ) VALUES (?1, ?2, ?3, ?4, CURRENT_TIMESTAMP)
            ON CONFLICT(user_id) DO UPDATE SET
                name = excluded.name,
                avatar_url = excluded.avatar_url,
                payload_json = excluded.payload_json,
                fetched_at = CURRENT_TIMESTAMP
            ",
            (&viewer.id, &viewer.name, &viewer.avatar_url, &payload),
        )
        .map_err(|error| error.to_string())?;

    connection
        .execute(
            "
            INSERT INTO auth_session (id, viewer_id, updated_at)
            VALUES (1, ?1, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
                viewer_id = excluded.viewer_id,
                updated_at = CURRENT_TIMESTAMP
            ",
            [viewer.id],
        )
        .map_err(|error| error.to_string())?;

    // Keep the frontend-consumed score format in app_settings.
    connection
        .execute(
            "INSERT INTO app_settings(key, value) VALUES('score_format', ?1)
             ON CONFLICT(key) DO NOTHING",
            [viewer.score_format.as_str()],
        )
        .map_err(|error| error.to_string())?;

    Ok(())
}
