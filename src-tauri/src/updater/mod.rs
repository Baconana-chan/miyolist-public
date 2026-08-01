//! In-app updates via GitHub Releases (tauri-plugin-updater).
//!
//! The desktop app checks `https://github.com/Baconana-chan/miyolist-public/releases/latest/download/latest.json`
//! (the `latest.json` manifest uploaded by `tauri-action` on release builds) for a newer
//! version.  Checks are throttled to once per day unless the user manually clicks
//! "Check for updates"; a manually-skipped version stays suppressed until a newer one
//! ships.  Download progress is forwarded to the frontend via the `updater://progress`
//! event so the About dialog can render a real progress bar.

use serde::Serialize;
use std::time::{SystemTime, UNIX_EPOCH};
use tauri::{AppHandle, Emitter};
use tauri_plugin_updater::UpdaterExt;

use crate::models::UpdateInfo;

/// App-settings key holding the unix timestamp of the last successful check.
const LAST_CHECK_KEY: &str = "updater_last_check_at";
/// App-settings key holding the version the user asked to skip ("" = none).
const SKIPPED_VERSION_KEY: &str = "updater_skipped_version";
/// Only one automatic check per 24 h — the updater hits a public endpoint, so
/// we don't want to hammer it on every launch.
const CHECK_INTERVAL_SECS: i64 = 24 * 60 * 60;
/// Frontend event for download progress.
pub const PROGRESS_EVENT: &str = "updater://progress";

fn now_ts() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

/// The updater pubkey configured in `tauri.conf.json` (`plugins.updater.pubkey`).
fn configured_pubkey(app: &AppHandle) -> Option<String> {
    app.config()
        .plugins
        .0
        .get("updater")
        .and_then(|v| v.get("pubkey"))
        .and_then(|v| v.as_str())
        .map(String::from)
}

/// True when the signing key is still the unconfigured placeholder from the
/// template config.  In that state the plugin's `download_and_install` would
/// happily download a release and only then fail signature verification — so
/// we skip checks entirely and log once instead.
///
/// The `TAURI_UPDATER_PUBKEY` dev override (see lib.rs) is consulted first,
/// so a developer who injected a real key via env still gets a working
/// updater even when the committed config holds the placeholder.
fn pubkey_unconfigured(app: &AppHandle) -> bool {
    if let Ok(pk) = std::env::var("TAURI_UPDATER_PUBKEY") {
        let pk = pk.trim();
        if !pk.is_empty() && !pk.starts_with("REPLACE_WITH") {
            return false;
        }
    }
    match configured_pubkey(app) {
        Some(pk) => pk.trim().is_empty() || pk.starts_with("REPLACE_WITH"),
        None => true,
    }
}

/// Payload emitted on `updater://progress` while an update downloads.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProgressPayload {
    pub downloaded: u64,
    pub total: Option<u64>,
}

/// Checks for a newer release.
///
/// `force = true` (manual "Check for updates" from the About dialog) bypasses
/// the 24 h throttle but still respects a skipped version.  `force = false`
/// (startup / background) applies both the throttle and the skip.
pub async fn check_for_updates(app: &AppHandle, force: bool) -> Result<Option<UpdateInfo>, String> {
    if !force {
        let last = crate::db::get_string_app_setting(app, LAST_CHECK_KEY)?
            .and_then(|v| v.parse::<i64>().ok())
            .unwrap_or(0);
        if now_ts() - last < CHECK_INTERVAL_SECS {
            return Ok(None);
        }
    }

    // Placeholder pubkey (template default) — not a transient condition, so
    // record the check time to avoid re-logging on every launch.
    if pubkey_unconfigured(app) {
        if force {
            // Manual "Check for updates" should say *why* it can't check
            // instead of silently reporting "up to date".
            return Err(
                "[UPDATER] disabled: plugins.updater.pubkey is not configured in tauri.conf.json — commit the real public key before shipping releases."
                    .to_string(),
            );
        }
        eprintln!(
            "[UPDATER] plugins.updater.pubkey is not configured in tauri.conf.json — update checks are disabled. Commit the real public key before shipping releases."
        );
        let _ = crate::db::set_string_app_setting(app, LAST_CHECK_KEY, &now_ts().to_string());
        return Ok(None);
    }

    let updater = app
        .updater()
        .map_err(|e| format!("[UPDATER] init failed: {e}"))?;
    let update = updater
        .check()
        .await
        .map_err(|e| format!("[UPDATER] check failed: {e}"))?;

    // Record the timestamp only on a *successful* check.  A failed (offline)
    // attempt must not suppress the next one — otherwise an app that launched
    // offline would never surface an update until 24 h later, even after
    // coming back online.  Boot/reconnect are rare events, so this cannot
    // cause a retry storm against a genuinely broken endpoint.
    let _ = crate::db::set_string_app_setting(app, LAST_CHECK_KEY, &now_ts().to_string());

    let Some(update) = update else {
        return Ok(None);
    };

    // A manual "Check for updates" is an explicit re-check — reset any
    // previously skipped version so the user can change their mind
    // ("Skip this version" only suppresses *automatic* offers).  Cleared only
    // after a *successful* check: a failed manual attempt (e.g. offline) must
    // not silently discard the user's skip.
    if force {
        let _ = clear_skipped_version(app);
    }

    let skipped = crate::db::get_string_app_setting(app, SKIPPED_VERSION_KEY)?
        .unwrap_or_default()
        .to_string();
    if !skipped.is_empty() && skipped == update.version {
        return Ok(None);
    }

    Ok(Some(UpdateInfo {
        version: update.version.clone(),
        current_version: update.current_version.clone(),
        // Strict RFC 3339 so the frontend's `new Date(...)` parses reliably
        // (OffsetDateTime's Display format is not strict RFC 3339).
        date: update
            .date
            .and_then(|d| d.format(&time::format_description::well_known::Rfc3339).ok()),
        body: update.body.clone(),
    }))
}

/// Downloads and installs the newest available update, reporting progress on
/// `updater://progress`.  On success the app restarts into the new version.
/// Runs off the main thread via `spawn_blocking` in the command layer.
pub async fn install_update(app: &AppHandle) -> Result<(), String> {
    if pubkey_unconfigured(app) {
        return Err(
            "[UPDATER] signing pubkey is not configured in tauri.conf.json — cannot verify or install updates."
                .to_string(),
        );
    }

    let updater = app
        .updater()
        .map_err(|e| format!("[UPDATER] init failed: {e}"))?;
    let update = updater
        .check()
        .await
        .map_err(|e| format!("[UPDATER] check failed: {e}"))?
        .ok_or_else(|| "[UPDATER] no update available".to_string())?;

    let app_emit = app.clone();
    let mut downloaded: u64 = 0;

    update
        .download_and_install(
            |chunk_len, content_length| {
                downloaded += chunk_len as u64;
                let _ = app_emit.emit(
                    PROGRESS_EVENT,
                    ProgressPayload {
                        downloaded,
                        total: content_length,
                    },
                );
            },
            || {},
        )
        .await
        .map_err(|e| format!("[UPDATER] install failed: {e}"))?;

    // Restart into the freshly installed version.  On Windows the updater's
    // NSIS/MSI path relaunches the app itself, so this is mainly the Linux
    // AppImage / macOS path.  `restart()` never returns (the process is torn
    // down), so the `Ok` below is only a formality for the return type.
    app.restart();
    #[allow(unreachable_code)]
    Ok(())
}

/// Remembers the version the user asked to skip, so it is not offered again.
pub fn skip_update_version(app: &AppHandle, version: &str) -> Result<(), String> {
    crate::db::set_string_app_setting(app, SKIPPED_VERSION_KEY, version)
}

/// Clears the skipped version (used by "remind me later" and reset flows).
pub fn clear_skipped_version(app: &AppHandle) -> Result<(), String> {
    crate::db::set_string_app_setting(app, SKIPPED_VERSION_KEY, "")
}
