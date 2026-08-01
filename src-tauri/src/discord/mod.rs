//! Discord Rich Presence (desktop only).
//!
//! Shows what you're currently watching (anime) or reading (manga/novel) in
//! your Discord status. The presence updates whenever a list entry's progress
//! changes, and is cleared when the feature is toggled off.
//!
//! # Discord Application ID
//!
//! Rich Presence is authorised with a Discord *Application ID*:
//!
//! 1. Create an application at <https://discord.com/developers/applications>.
//! 2. Provide its numeric ID at build time:
//!
//! ```text
//! MIYOLIST_DISCORD_APP_ID=123456789012345678 cargo build
//! ```
//!
//! When no ID is configured the module silently disables itself (the toggle in
//! Settings still round-trips, but no activity is ever sent).

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use discord_presence::models::ActivityType;
use discord_presence::Client;
use tauri::AppHandle;

/// Application ID used to authorise the Rich Presence session.  Read from the
/// `MIYOLIST_DISCORD_APP_ID` build-time env var; `0` means "not configured".
fn app_id() -> u64 {
    match option_env!("MIYOLIST_DISCORD_APP_ID") {
        Some(raw) => raw.trim().parse().unwrap_or(0),
        None => 0,
    }
}

/// Lazily-created client.  `Client::start()` spawns the crate's internal
/// connection thread, which reconnects automatically (5 s sleep, unlimited
/// retries), so a client that fails to connect at launch will come up as soon
/// as Discord is running.
static CLIENT: Mutex<Option<Client>> = Mutex::new(None);

/// Logged the "no App ID configured" hint at least once (avoids spamming
/// stderr on every progress update while the feature is enabled but unset).
static HINT_LOGGED: AtomicBool = AtomicBool::new(false);

fn now_unix() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn is_enabled(app: &AppHandle) -> bool {
    crate::db::get_app_settings(app)
        .map(|s| s.discord_rpc_enabled)
        .unwrap_or(false)
}

/// Makes sure the client exists and its connection thread is running.
/// Returns `false` (and logs a hint) when no real Application ID is set.
fn ensure_client() -> bool {
    let id = app_id();
    if id == 0 {
        if !HINT_LOGGED.swap(true, Ordering::Relaxed) {
            eprintln!(
                "[DISCORD_RPC] No MIYOLIST_DISCORD_APP_ID configured; Rich Presence is off. \
                 Create an app at https://discord.com/developers/applications and set the env var."
            );
        }
        return false;
    }
    let mut guard = CLIENT
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    if guard.is_none() {
        let mut client = Client::new(id);
        client.start();
        *guard = Some(client);
    }
    true
}

/// Default "browsing" activity, shown on startup and when the toggle is
/// switched on.  Best-effort: swallows IPC errors (e.g. Discord not running).
pub fn show_browsing(app: &AppHandle) {
    if !is_enabled(app) || !ensure_client() {
        return;
    }
    let mut guard = CLIENT
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    if let Some(client) = guard.as_mut() {
        let _ = client.set_activity(|act| {
            act.details("Browsing their anime list")
                .state("MiyoList")
                .activity_type(ActivityType::Playing)
        });
    }
}

/// Reflect the current state of `media_id` in the Discord presence:
/// - Anime   → "Watching <title>" · "Episode X of Y"
/// - Manga   → "Playing <title>"  · "Reading chapter X of Y"
///
/// Discord has no dedicated "Reading" activity type (only Playing/Streaming/
/// Listening/Watching/Competing), so manga uses Playing with reading wording
/// in the state line.  No-ops when the feature is disabled.
pub fn update_for_media(app: &AppHandle, media_id: i64) {
    if !is_enabled(app) || !ensure_client() {
        return;
    }
    // Per-media privacy override: the user asked to keep this title out of
    // their Discord status.  Fall back to the generic browsing activity so
    // the presence stays visible but leaks nothing about what they're on.
    if crate::db::is_discord_hidden(app, media_id).unwrap_or(false) {
        show_browsing(app);
        return;
    }
    let Ok(Some(entry)) = crate::db::get_list_entry_by_media_id(app, media_id) else {
        return;
    };

    let title = if entry.title.trim().is_empty() {
        format!("Media #{}", entry.media_id)
    } else {
        entry.title.clone()
    };
    let progress = entry.progress.max(0);
    let is_anime = entry.media_type.eq_ignore_ascii_case("ANIME");

    let (activity_type, state) = if is_anime {
        (
            ActivityType::Watching,
            match entry.episodes_or_chapters {
                Some(total) if total > 0 => format!("Episode {progress} of {total}"),
                _ => format!("Episode {progress}"),
            },
        )
    } else {
        (
            ActivityType::Playing,
            match entry.episodes_or_chapters {
                Some(total) if total > 0 => format!("Reading chapter {progress} of {total}"),
                _ => format!("Reading chapter {progress}"),
            },
        )
    };

    let cover = entry.cover_image;
    let large_text = title.clone();

    let mut guard = CLIENT
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    if let Some(client) = guard.as_mut() {
        let _ = client.set_activity(|act| {
            let act = act
                .details(title)
                .state(state)
                .activity_type(activity_type)
                .timestamps(|ts| ts.start(now_unix()));
            if let Some(url) = cover {
                act.assets(|assets| assets.large_image(url).large_text(large_text))
            } else {
                act
            }
        });
    }
}

/// Clear the current activity (used when the toggle is switched off).
/// The client itself stays alive and reconnects in the background.
pub fn clear_presence(_app: &AppHandle) {
    let mut guard = CLIENT
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner());
    if let Some(client) = guard.as_mut() {
        let _ = client.clear_activity();
    }
}
