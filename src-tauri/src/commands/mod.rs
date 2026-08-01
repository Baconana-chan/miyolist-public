use tauri::AppHandle;
#[cfg(desktop)]
use tauri::Manager;

use crate::models::{
    ActivityEntry, AiringEntry, AniListConfigStatus, AniListNotificationItem, AniListViewer,
    AnnualWrapUp, AppSettings, AuthRequestPlan, AuthSessionStatus, BootstrapPayload, CacheStats,
    CharacterDetails, DatabaseInitResult, DatabaseOverview, ExportResult, FollowingActivityItem,
    GlobalAiringEntry, HeatmapDay, ImportResult, LibrarySnapshot, LibraryStats, ListEntry,
    MangaReleaseMapping, MangaUpdatesSeries, MediaDetails, MediaSearchResult,
    MonthlyActivityCount, NotificationOverride, NotificationSettings, PendingConflict,
    PersonSearchResult, SocialUser, StaffDetails, StudioDetails, StudioSearchResult, SyncLogEntry,
    SyncSummary, UpdateInfo, UserFavorites, UserMediaListItem, UserProfile, UserSearchResult,
};

#[tauri::command]
pub fn get_bootstrap() -> BootstrapPayload {
    BootstrapPayload {
        product_name: "MiyoList".into(),
        app_version: env!("CARGO_PKG_VERSION").into(),
        primary_platform: crate::auth::primary_platform(),
        supported_targets: vec!["desktop".into(), "mobile-ready layout".into()],
        guarantees: vec![
            "local-first runtime".into(),
            "no Supabase".into(),
            "responsive shell".into(),
            "explicit auth recovery".into(),
        ],
        auth_strategy: crate::auth::auth_strategy(),
        foundation_modules: vec![
            crate::auth::foundation_summary(),
            crate::db::foundation_summary(),
            crate::anilist::foundation_summary(),
            crate::notifications::foundation_summary(),
            crate::cache::foundation_summary(),
            crate::settings::foundation_summary(),
        ],
    }
}

#[tauri::command]
pub fn initialize_database(app: AppHandle) -> Result<DatabaseInitResult, String> {
    crate::db::initialize_database(&app)
}

#[tauri::command]
pub fn get_database_overview(app: AppHandle) -> Result<DatabaseOverview, String> {
    crate::db::get_database_overview(&app)
}

#[tauri::command]
pub fn prepare_auth_request(app: AppHandle) -> Result<AuthRequestPlan, String> {
    crate::auth::prepare_auth_request(&app)
}

#[tauri::command]
pub fn get_anilist_config_status() -> AniListConfigStatus {
    crate::anilist::config_status()
}

#[tauri::command]
pub fn get_online_status() -> bool {
    crate::anilist::is_online()
}

#[tauri::command]
pub fn get_viewer(app: AppHandle) -> Result<AniListViewer, String> {
    crate::anilist::fetch_viewer(&app)
}

#[tauri::command]
pub fn toggle_media_favorite(
    app: AppHandle,
    media_id: i64,
    media_type: String,
) -> Result<bool, String> {
    crate::anilist::toggle_media_favorite(&app, media_id, &media_type)
}

#[tauri::command]
pub fn toggle_favorite(
    app: AppHandle,
    target_id: i64,
    target_type: String,
) -> Result<bool, String> {
    crate::anilist::toggle_favorite(&app, target_id, &target_type)
}

#[tauri::command]
pub fn get_auth_session_status(app: AppHandle) -> Result<AuthSessionStatus, String> {
    crate::anilist::get_auth_session_status(&app)
}

#[tauri::command]
pub fn store_access_token(
    app: AppHandle,
    access_token: String,
) -> Result<AuthSessionStatus, String> {
    crate::anilist::store_access_token(&app, &access_token)
}

#[tauri::command]
pub fn clear_access_token(app: AppHandle) -> Result<AuthSessionStatus, String> {
    crate::anilist::clear_access_token(&app)
}

#[tauri::command]
pub fn get_library_snapshot(app: AppHandle) -> Result<LibrarySnapshot, String> {
    crate::db::get_library_snapshot(&app)
}
#[tauri::command]
pub fn sync_user_lists(app: AppHandle) -> Result<SyncSummary, String> {
    if !crate::anilist::is_online() {
        return Ok(SyncSummary {
            synced: 0,
            pushed: 0,
            failed: 0,
            conflicts: 0,
            is_delta: false,
            last_synced_at: String::new(),
        });
    }
    crate::anilist::fetch_viewer(&app)?;
    crate::anilist::sync_lists_smart(&app)
}

#[tauri::command]
pub fn get_sync_progress() -> crate::models::SyncProgress {
    crate::anilist::get_sync_progress()
}

#[tauri::command]
pub fn get_sync_log(app: AppHandle, limit: Option<i64>) -> Result<Vec<SyncLogEntry>, String> {
    crate::db::get_sync_log(&app, limit.unwrap_or(100))
}

#[tauri::command]
pub fn get_pending_conflicts(app: AppHandle) -> Result<Vec<PendingConflict>, String> {
    crate::db::get_pending_conflicts(&app)
}

#[tauri::command]
pub fn resolve_conflict(app: AppHandle, media_id: i64, use_remote: bool) -> Result<(), String> {
    crate::db::apply_conflict_resolution(&app, media_id, use_remote)
}

#[tauri::command]
pub fn push_dirty_entries(app: AppHandle) -> Result<SyncSummary, String> {
    if !crate::anilist::is_online() {
        return Ok(SyncSummary {
            synced: 0,
            pushed: 0,
            failed: 0,
            conflicts: 0,
            is_delta: false,
            last_synced_at: String::new(),
        });
    }
    crate::anilist::push_dirty_entries(&app)
}

#[tauri::command]
pub fn get_list_entries(
    app: AppHandle,
    media_type: Option<String>,
    status: Option<String>,
) -> Result<Vec<ListEntry>, String> {
    crate::db::get_list_entries(&app, media_type, status)
}

#[tauri::command]
pub fn get_list_entry_by_media_id(
    app: AppHandle,
    media_id: i64,
) -> Result<Option<ListEntry>, String> {
    crate::db::get_list_entry_by_media_id(&app, media_id)
}

#[tauri::command]
#[allow(clippy::too_many_arguments)]
pub fn update_list_entry(
    app: AppHandle,
    local_id: i64,
    media_id: i64,
    status: String,
    score: Option<f64>,
    progress: i64,
    progress_volumes: i64,
    repeat_count: i64,
    start_date: Option<String>,
    completed_date: Option<String>,
    notes: Option<String>,
    custom_lists: Option<Vec<String>>,
) -> Result<Option<String>, String> {
    crate::db::update_list_entry_local(
        &app,
        local_id,
        &status,
        score,
        progress,
        progress_volumes,
        repeat_count,
        start_date.clone(),
        completed_date.clone(),
        notes.clone(),
        custom_lists.clone(),
    )?;
    // Reflect the new progress/status in the Discord Rich Presence (desktop).
    #[cfg(desktop)]
    crate::discord::update_for_media(&app, media_id);
    match crate::anilist::save_media_list_entry(
        &app,
        media_id,
        &status,
        score,
        progress,
        progress_volumes,
        repeat_count,
        start_date,
        completed_date,
        notes,
        custom_lists,
    ) {
        Ok(()) => {
            let _ = crate::db::clear_entry_dirty(&app, local_id);
            Ok(None)
        }
        Err(e) => {
            eprintln!("AniList sync failed for local entry {local_id}: {e}");
            // Local save succeeded; the dirty flag will retry on next sync.
            Ok(Some(format!(
                "Saved locally, but AniList sync failed: {e}"
            )))
        }
    }
}

#[tauri::command]
pub fn delete_list_entry(
    app: AppHandle,
    local_id: i64,
    anilist_entry_id: Option<i64>,
) -> Result<Option<String>, String> {
    crate::db::delete_list_entry_local(&app, local_id)?;
    if let Some(anilist_id) = anilist_entry_id {
        match crate::anilist::delete_media_list_entry(&app, anilist_id) {
            Ok(()) => {}
            Err(e) => {
                eprintln!("AniList delete failed for entry {anilist_id}: {e}");
                return Ok(Some(format!(
                    "Removed locally, but AniList delete failed: {e}"
                )));
            }
        }
    }
    Ok(None)
}

#[tauri::command]
#[allow(clippy::too_many_arguments)]
pub fn search_media(
    app: AppHandle,
    query: String,
    media_type: String,
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
) -> Result<Vec<MediaSearchResult>, String> {
    crate::anilist::search_media(
        &app,
        &query,
        &media_type,
        genres_in,
        genres_not_in,
        tags_in,
        tags_not_in,
        format_in,
        status_filter,
        sort,
        year_greater,
        year_lesser,
        minimum_tag_rank,
        is_adult,
    )
}

#[tauri::command]
pub fn get_trending_media(app: AppHandle, page: i32) -> Result<Vec<MediaSearchResult>, String> {
    crate::anilist::get_trending_media(&app, page)
}

#[tauri::command]
pub fn add_to_library(
    app: AppHandle,
    media_id: i64,
    media_type: String,
    status: String,
    title: Option<String>,
    cover_image: Option<String>,
) -> Result<Option<String>, String> {
    crate::db::add_entry_to_library(
        &app,
        media_id,
        &media_type,
        &status,
        title.as_deref(),
        cover_image.as_deref(),
    )?;
    // Adding an entry is usually the "started watching/reading" moment.
    #[cfg(desktop)]
    crate::discord::update_for_media(&app, media_id);
    match crate::anilist::save_media_list_entry(
        &app, media_id, &status, None, 0, 0, 0, None, None, None, None,
    ) {
        Ok(()) => Ok(None),
        Err(e) => {
            eprintln!("AniList add failed for media {media_id}: {e}");
            // Local insert succeeded; the dirty flag will retry on next sync.
            Ok(Some(format!(
                "Added locally, but AniList sync failed: {e}"
            )))
        }
    }
}

#[tauri::command]
pub fn get_auth_callback_status() -> String {
    crate::auth::get_auth_callback_status()
}

#[tauri::command]
pub fn reopen_auth_browser(app: AppHandle, auth_url: String) -> Result<(), String> {
    crate::auth::reopen_auth_browser(&app, &auth_url)
}

#[tauri::command]
pub fn submit_auth_code_manually(
    app: AppHandle,
    code: String,
) -> Result<AuthSessionStatus, String> {
    crate::auth::submit_auth_code_manually(&app, &code)?;
    crate::anilist::get_auth_session_status(&app)
}

#[tauri::command]
pub fn get_media_details(app: AppHandle, media_id: i64) -> Result<MediaDetails, String> {
    crate::anilist::fetch_media_details(&app, media_id)
}

/// Search AnimeThemes.moe by anime title; returns matches with their OP/ED list.
#[tauri::command]
pub fn search_themes(query: String) -> Result<Vec<crate::models::ThemeAnime>, String> {
    crate::themes::search_themes(&query)
}

/// Fetch OP/ED themes for a media entry by its locally cached title.
#[tauri::command]
pub fn get_themes_for_media(
    app: AppHandle,
    media_id: i64,
) -> Result<Vec<crate::models::MediaTheme>, String> {
    crate::themes::get_themes_for_media(&app, media_id)
}

/// All OP/ED themes the user starred for a media entry (local favourites).
#[tauri::command]
pub fn get_favorite_themes(
    app: AppHandle,
    media_id: i64,
) -> Result<Vec<crate::models::FavoriteTheme>, String> {
    crate::db::get_favorite_themes(&app, media_id)
}

/// Adds or removes a theme to/from the media's favourite list.  Returns the
/// new state (`true` = now favourited).
#[tauri::command]
pub fn toggle_favorite_theme(
    app: AppHandle,
    media_id: i64,
    theme_id: i64,
    theme_type: String,
    song_title: String,
    artists: Vec<String>,
) -> Result<bool, String> {
    crate::db::toggle_favorite_theme(&app, media_id, theme_id, &theme_type, &song_title, &artists)
}

// ─── Schedule and notifications ───────────────────────────────────────────────

#[tauri::command]
pub fn get_airing_schedule(app: AppHandle) -> Result<Vec<AiringEntry>, String> {
    crate::db::get_airing_schedule(&app)
}

#[tauri::command]
pub fn get_global_airing_schedule(
    app: AppHandle,
    weekday: Option<u8>,
) -> Result<Vec<GlobalAiringEntry>, String> {
    if !crate::anilist::is_online() {
        return Ok(Vec::new());
    }
    crate::anilist::get_global_airing_schedule(&app, weekday)
}

/// Fetches fresh airing data from AniList for all currently-watching anime,
/// then checks and fires OS notifications for any episodes that have aired.
#[tauri::command]
pub fn refresh_airing_schedule(app: AppHandle) -> Result<i64, String> {
    if !crate::anilist::is_online() {
        return Ok(0);
    }
    let stored = crate::anilist::fetch_airing_schedule(&app).unwrap_or_else(|e| {
        eprintln!("[AIRING_FETCH] {e}");
        0
    });
    let _ = crate::notifications::check_and_send_pending(&app);
    Ok(stored)
}

/// Called on app startup: check for aired episodes that need notifications
/// without making a network request.
#[tauri::command]
pub fn check_notifications(app: AppHandle) -> Result<i64, String> {
    crate::notifications::check_and_send_pending(&app)
}

#[tauri::command]
pub fn get_notification_settings(app: AppHandle) -> Result<NotificationSettings, String> {
    crate::db::get_notification_settings(&app)
}

#[tauri::command]
pub fn save_notification_settings(
    app: AppHandle,
    settings: NotificationSettings,
) -> Result<(), String> {
    crate::db::save_notification_settings(&app, &settings)
}

#[tauri::command]
pub fn get_notification_overrides(
    app: AppHandle,
    media_ids: Vec<i64>,
) -> Result<Vec<NotificationOverride>, String> {
    crate::db::get_notification_overrides(&app, &media_ids)
}

#[tauri::command]
pub fn set_notification_override(
    app: AppHandle,
    media_id: i64,
    enabled: bool,
) -> Result<(), String> {
    crate::db::set_notification_override(&app, media_id, enabled)
}

/// Per-media "hide from Discord Rich Presence" (desktop only).
#[tauri::command]
pub fn set_discord_hidden(app: AppHandle, media_id: i64, hidden: bool) -> Result<(), String> {
    crate::db::set_discord_hidden(&app, media_id, hidden)
}

#[tauri::command]
pub fn get_anilist_notifications(
    app: AppHandle,
    type_filter: Option<String>,
    page: Option<i32>,
    per_page: Option<i32>,
    reset_unread_count: Option<bool>,
) -> Result<Vec<AniListNotificationItem>, String> {
    if !crate::anilist::is_online() {
        return Ok(Vec::new());
    }
    crate::anilist::fetch_notifications(
        &app,
        type_filter,
        page.unwrap_or(1),
        per_page.unwrap_or(50),
        reset_unread_count.unwrap_or(false),
    )
}

/// Increment progress for an anime entry directly from the schedule screen.
/// Writes locally and attempts an immediate AniList push.
#[tauri::command]
pub fn increment_episode_progress(
    app: AppHandle,
    media_id: i64,
    delta: i64,
) -> Result<i64, String> {
    let new_progress = crate::db::increment_anime_progress(&app, media_id, delta)?;
    // Reflect the new watch progress in the Discord Rich Presence (desktop).
    #[cfg(desktop)]
    crate::discord::update_for_media(&app, media_id);
    // Best-effort push; dirty flag will catch it on next sync if this fails.
    if crate::anilist::is_online() {
        let _ = crate::anilist::push_dirty_entries(&app);
    }
    Ok(new_progress)
}

/// Derived statistics built entirely from local library data.
#[tauri::command]
pub fn get_library_stats(app: AppHandle) -> Result<LibraryStats, String> {
    crate::db::get_library_stats(&app)
}

/// Recent activity log entries (default cap: 100).
#[tauri::command]
pub fn get_activity_log(
    app: AppHandle,
    #[allow(unused)] limit: Option<i64>,
) -> Result<Vec<ActivityEntry>, String> {
    crate::db::get_activity_log(&app, limit.unwrap_or(100))
}

/// Per-day activity counts for a selected year.
#[tauri::command]
pub fn get_activity_heatmap(app: AppHandle, year: Option<i32>) -> Result<Vec<HeatmapDay>, String> {
    crate::db::get_activity_heatmap(&app, year)
}

/// Activity log entries for a specific date (`YYYY-MM-DD`).
#[tauri::command]
pub fn get_activity_log_by_date(
    app: AppHandle,
    date: String,
    #[allow(unused)] limit: Option<i64>,
) -> Result<Vec<ActivityEntry>, String> {
    crate::db::get_activity_log_by_date(&app, &date, limit.unwrap_or(200))
}

/// Monthly episode/chapter totals for progress updates in a selected year.
#[tauri::command]
pub fn get_activity_monthly_totals(
    app: AppHandle,
    year: i32,
) -> Result<Vec<MonthlyActivityCount>, String> {
    crate::db::get_activity_monthly_totals(&app, year)
}

/// Year-in-review aggregate metrics for the selected year.
#[tauri::command]
pub fn get_annual_wrap_up(app: AppHandle, year: i32) -> Result<AnnualWrapUp, String> {
    crate::db::get_annual_wrap_up(&app, year)
}

// ─── App settings ─────────────────────────────────────────────────────────────

#[tauri::command]
pub fn get_app_settings(app: AppHandle) -> Result<AppSettings, String> {
    crate::db::get_app_settings(&app)
}

#[tauri::command]
pub fn save_app_settings(app: AppHandle, settings: AppSettings) -> Result<(), String> {
    crate::db::save_app_settings(&app, &settings)
}

// ─── Auto-updater ─────────────────────────────────────────────────────────────

/// Checks GitHub Releases for a newer version.  `force` bypasses the 24 h
/// throttle (manual "Check for updates" from About); a user-skipped version is
/// still respected.
#[tauri::command]
pub async fn check_for_updates(app: AppHandle, force: bool) -> Result<Option<UpdateInfo>, String> {
    crate::updater::check_for_updates(&app, force).await
}

/// Downloads + installs the latest release, then restarts the app.  Runs on
/// the Tauri async runtime (never the main thread) and streams progress to
/// the `updater://progress` event.
#[tauri::command]
pub async fn install_update(app: AppHandle) -> Result<(), String> {
    crate::updater::install_update(&app).await
}

/// Remembers a version the user asked to skip so it stops being offered.
/// A manual "Check for updates" (force) resets it, so a skipped version can
/// always be reconsidered.
#[tauri::command]
pub fn skip_update_version(app: AppHandle, version: String) -> Result<(), String> {
    crate::updater::skip_update_version(&app, &version)
}

// ─── MangaUpdates release tracking ──────────────────────────────────────────

/// Search MangaUpdates by title (public API, no auth) — used by the manual
/// "replace link" UI in Settings.  Runs off the main thread: the call hits the
/// network with a 15s timeout, and sync commands would freeze the UI.
#[tauri::command]
pub async fn search_mangaupdates_series(
    query: String,
) -> Result<Vec<MangaUpdatesSeries>, String> {
    tauri::async_runtime::spawn_blocking(move || {
        crate::manga_releases::search_series(&query)
    })
    .await
    .map_err(|e| format!("[MANGA_RELEASES] search task failed: {e}"))?
}

/// All stored AniList→MangaUpdates links (for the Settings UI).
#[tauri::command]
pub fn get_manga_release_mappings(app: AppHandle) -> Result<Vec<MangaReleaseMapping>, String> {
    crate::db::get_manga_release_mappings(&app)
}

/// Manually (re)link a manga entry to a MangaUpdates series — used when the
/// auto-resolution picked the wrong title.  Marks the link as manual so auto-
/// resolution never overrides it.
#[tauri::command]
pub fn set_manga_release_mapping(
    app: AppHandle,
    media_id: i64,
    mu_series_id: i64,
    mu_title: String,
) -> Result<(), String> {
    // Look up the entry's media type; default to MANGA for entries that only
    // exist in the cache.
    let media_type = crate::db::get_list_entry_by_media_id(&app, media_id)?
        .map(|e| e.media_type)
        .unwrap_or_else(|| "MANGA".to_string());
    crate::db::set_manga_release_mapping(&app, media_id, &media_type, mu_series_id, &mu_title, true)
}

/// Remove a MangaUpdates link (stops tracking that entry).
#[tauri::command]
pub fn clear_manga_release_mapping(app: AppHandle, media_id: i64) -> Result<(), String> {
    crate::db::clear_manga_release_mapping(&app, media_id)
}

/// Poll tracked manga right now and return how many notifications were sent.
/// Runs off the main thread — the poll can take tens of seconds with one
/// paced request per tracked series, and sync commands would block the UI.
#[tauri::command]
pub async fn check_manga_releases(app: AppHandle) -> Result<i64, String> {
    tauri::async_runtime::spawn_blocking(move || {
        crate::manga_releases::poll_manga_releases(&app)
    })
    .await
    .map_err(|e| format!("[MANGA_RELEASES] poll task failed: {e}"))?
}

/// Toggle Discord Rich Presence and persist the preference.  On desktop,
/// enabling connects the RPC client and shows a browsing activity; disabling
/// clears whatever activity is currently shown.
#[tauri::command]
pub fn set_discord_rpc(app: AppHandle, enabled: bool) -> Result<(), String> {
    let mut settings = crate::db::get_app_settings(&app)?;
    settings.discord_rpc_enabled = enabled;
    crate::db::save_app_settings(&app, &settings)?;

    #[cfg(desktop)]
    if enabled {
        crate::discord::show_browsing(&app);
    } else {
        crate::discord::clear_presence(&app);
    }
    Ok(())
}

/// Toggle the main window's "always on top" state (desktop only) and persist
/// the preference so it's restored on the next launch.  A no-op on mobile,
/// where there is no desktop window to float.
#[tauri::command]
pub fn set_always_on_top(app: AppHandle, enabled: bool) -> Result<(), String> {
    #[cfg(desktop)]
    {
        if let Some(window) = app.get_webview_window("main") {
            window
                .set_always_on_top(enabled)
                .map_err(|e| format!("Failed to set always-on-top: {e}"))?;
        }
    }

    // Persist regardless of platform so the setting round-trips cleanly.
    let mut settings = crate::db::get_app_settings(&app)?;
    settings.always_on_top = enabled;
    crate::db::save_app_settings(&app, &settings)
}

// ─── Cache management ─────────────────────────────────────────────────────────

#[tauri::command]
pub fn get_cache_stats(app: AppHandle) -> Result<CacheStats, String> {
    crate::db::get_cache_stats(&app)
}

#[tauri::command]
pub fn clear_search_history(app: AppHandle) -> Result<(), String> {
    crate::db::clear_search_history(&app)
}

#[tauri::command]
pub fn clear_orphan_media_cache(app: AppHandle) -> Result<i64, String> {
    crate::db::clear_orphan_media_cache(&app)
}

#[tauri::command]
pub fn clear_airing_cache(app: AppHandle) -> Result<(), String> {
    crate::db::clear_airing_cache(&app)
}

#[tauri::command]
pub fn clear_image_cache(app: AppHandle) -> Result<i64, String> {
    crate::cache::clear_image_cache(&app)
}

/// Pre-fetch all library cover images in a background thread.
/// Returns immediately; the download happens asynchronously.
#[tauri::command]
pub fn prefetch_covers(app: AppHandle) -> Result<(), String> {
    if !crate::anilist::is_online() {
        return Ok(());
    }
    let app2 = app.clone();
    std::thread::spawn(move || {
        let _ = crate::cache::prefetch_library_covers(&app2);
    });
    Ok(())
}

/// Return the local cached path for a single image URL, or null.
#[tauri::command]
pub fn get_cached_image_path(app: AppHandle, url: String) -> Result<Option<String>, String> {
    crate::cache::get_cached_image_path(&app, &url)
}

// ─── Backup / export / import ─────────────────────────────────────────────────

#[tauri::command]
pub fn export_library_json(app: AppHandle) -> Result<ExportResult, String> {
    crate::db::export_library_json(&app)
}

#[tauri::command]
pub fn export_database_backup(app: AppHandle) -> Result<ExportResult, String> {
    crate::db::export_database_backup(&app)
}

#[tauri::command]
pub fn import_library_json(app: AppHandle, path: String) -> Result<ImportResult, String> {
    crate::db::import_library_json(&app, path)
}

#[tauri::command]
pub fn get_favorites(app: AppHandle) -> Result<UserFavorites, String> {
    crate::anilist::fetch_favorites(&app)
}

// ─── Public detail pages ──────────────────────────────────────────────────────

#[tauri::command]
pub fn get_character_details(app: AppHandle, id: i64) -> Result<CharacterDetails, String> {
    crate::anilist::fetch_character_details(&app, id)
}

#[tauri::command]
pub fn get_staff_details(app: AppHandle, id: i64) -> Result<StaffDetails, String> {
    crate::anilist::fetch_staff_details(&app, id)
}

#[tauri::command]
pub fn get_studio_details(app: AppHandle, id: i64) -> Result<StudioDetails, String> {
    crate::anilist::fetch_studio_details(&app, id)
}

#[tauri::command]
pub fn get_user_profile(app: AppHandle, name: String) -> Result<UserProfile, String> {
    crate::anilist::fetch_user_profile(&app, &name)
}

// ─── People / search ──────────────────────────────────────────────────────────

#[tauri::command]
pub fn search_characters(app: AppHandle, query: String) -> Result<Vec<PersonSearchResult>, String> {
    crate::anilist::search_characters(&app, &query)
}

#[tauri::command]
pub fn search_staff(app: AppHandle, query: String) -> Result<Vec<PersonSearchResult>, String> {
    crate::anilist::search_staff(&app, &query)
}

#[tauri::command]
pub fn search_studios(app: AppHandle, query: String) -> Result<Vec<StudioSearchResult>, String> {
    crate::anilist::search_studios(&app, &query)
}

#[tauri::command]
pub fn search_users(app: AppHandle, query: String) -> Result<Vec<UserSearchResult>, String> {
    crate::anilist::search_users(&app, &query)
}

// ─── Social features ─────────────────────────────────────────────────────────

#[tauri::command]
pub fn toggle_follow(app: AppHandle, user_id: i64, follow: bool) -> Result<bool, String> {
    crate::anilist::toggle_follow(&app, user_id, follow)
}

#[tauri::command]
pub fn get_following(
    app: AppHandle,
    user_id: i64,
    page: Option<i64>,
) -> Result<Vec<SocialUser>, String> {
    crate::anilist::get_following(&app, user_id, page.unwrap_or(1))
}

#[tauri::command]
pub fn get_followers(
    app: AppHandle,
    user_id: i64,
    page: Option<i64>,
) -> Result<Vec<SocialUser>, String> {
    crate::anilist::get_followers(&app, user_id, page.unwrap_or(1))
}

#[tauri::command]
pub fn get_following_activity(
    app: AppHandle,
    page: Option<i64>,
    per_page: Option<i64>,
) -> Result<Vec<FollowingActivityItem>, String> {
    crate::anilist::get_following_activity(&app, page.unwrap_or(1), per_page.unwrap_or(25))
}

#[tauri::command]
pub fn get_global_activity(
    app: AppHandle,
    page: Option<i64>,
    per_page: Option<i64>,
) -> Result<Vec<FollowingActivityItem>, String> {
    crate::anilist::get_global_activity(&app, page.unwrap_or(1), per_page.unwrap_or(25))
}

#[tauri::command]
pub fn toggle_activity_like(app: AppHandle, activity_id: i64) -> Result<bool, String> {
    crate::anilist::toggle_activity_like(&app, activity_id)
}

#[tauri::command]
pub fn save_activity_reply(app: AppHandle, activity_id: i64, text: String) -> Result<i64, String> {
    crate::anilist::save_activity_reply(&app, activity_id, &text)
}

#[tauri::command]
pub fn get_user_media_list(
    app: AppHandle,
    user_id: i64,
    media_type: String,
) -> Result<Vec<UserMediaListItem>, String> {
    crate::anilist::get_user_media_list(&app, user_id, &media_type)
}

#[tauri::command]
pub fn post_activity(app: AppHandle, text: String) -> Result<i64, String> {
    crate::anilist::post_activity(&app, &text)
}
