use tauri::AppHandle;
use tauri_plugin_notification::NotificationExt;

pub fn foundation_summary() -> crate::models::FoundationModule {
    crate::models::FoundationModule {
        name: "Notifications".into(),
        summary: "Native OS notifications for airing episodes, with per-category toggles and desktop-compatible scheduling.".into(),
        status: "ready".into(),
    }
}

/// Checks `airing_cache` for episodes that have aired but not yet been
/// notified.  If airing notifications are enabled in settings, sends one OS
/// notification per episode and marks each as notified.
///
/// Designed to be called on app startup and after a schedule refresh — no
/// daemon or background task required.
pub fn check_and_send_pending(app: &AppHandle) -> Result<i64, String> {
    let settings = crate::db::get_notification_settings(app)?;
    if !settings.airing_enabled {
        return Ok(0);
    }

    let pending = crate::db::get_unnotified_aired(app)?;
    let mut sent = 0i64;

    for entry in &pending {
        let title = format!("{} — Episode {} aired", entry.title, entry.episode);
        let body = if entry.user_progress < entry.episode {
            format!(
                "You're on episode {}. Time to catch up!",
                entry.user_progress
            )
        } else {
            "You're up to date.".to_string()
        };

        let icon_path = entry
            .cover_image
            .as_deref()
            .and_then(|url| crate::cache::get_cached_image_path(app, url).ok().flatten());

        let mut builder = app
            .notification()
            .builder()
            .title(&title)
            .body(&body);
        if let Some(icon) = icon_path.as_deref() {
            builder = builder.icon(icon);
        }

        // tauri-plugin-notification: send synchronously — no daemon needed.
        if builder.show().is_ok() {
            let _ = crate::db::mark_airing_notified(app, entry.media_id, entry.episode);
            sent += 1;
        }
    }

    Ok(sent)
}
