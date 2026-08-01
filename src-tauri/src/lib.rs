mod anilist;
mod auth;
mod cache;
mod commands;
mod db;
#[cfg(desktop)]
mod discord;
mod manga_releases;
mod models;
mod notifications;
mod settings;
mod themes;
mod updater;

#[cfg(desktop)]
use std::sync::atomic::{AtomicBool, Ordering};
#[cfg(desktop)]
use std::time::{SystemTime, UNIX_EPOCH};

#[cfg(desktop)]
use tauri::menu::{MenuBuilder, MenuItemBuilder};
#[cfg(desktop)]
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent};
#[cfg(desktop)]
use tauri::{Manager, WindowEvent};
#[cfg(desktop)]
use tauri_plugin_notification::NotificationExt;

#[cfg(desktop)]
const TRAY_ID: &str = "main-tray";
#[cfg(desktop)]
const TRAY_MENU_OPEN: &str = "tray_open";
#[cfg(desktop)]
const TRAY_MENU_SYNC: &str = "tray_quick_sync";
#[cfg(desktop)]
const TRAY_MENU_NEXT_AIRING: &str = "tray_next_airing";
#[cfg(desktop)]
const TRAY_MENU_QUIT: &str = "tray_quit";
#[cfg(desktop)]
const TRAY_NOTICE_SHOWN_KEY: &str = "tray_notice_shown";

#[cfg(desktop)]
static EXITING_FROM_TRAY: AtomicBool = AtomicBool::new(false);

/// Debounce guard so rapid-fire resize/move events don't hammer the DB with
/// one write per event while the user is dragging the window.
#[cfg(desktop)]
static WINDOW_BOUNDS_SAVE_PENDING: AtomicBool = AtomicBool::new(false);

/// Restore the main window's persisted bounds and always-on-top preference.
/// Called once at startup, before the frontend loads.
#[cfg(desktop)]
fn restore_window_state(app: &tauri::AppHandle) {
    // Ensure the settings tables exist — `setup` runs before the frontend has
    // had a chance to call `initialize_database`.
    let _ = crate::db::initialize_database(app);

    let Some(window) = app.get_webview_window("main") else {
        return;
    };

    let settings = crate::db::get_app_settings(app).unwrap_or_default();
    if settings.always_on_top {
        let _ = window.set_always_on_top(true);
    }

    if let Ok(Some((x, y, width, height))) = crate::db::get_window_bounds(app) {
        let _ = window.unmaximize();
        let _ = window.set_position(tauri::PhysicalPosition::new(x, y));
        let _ = window.set_size(tauri::PhysicalSize::new(width, height));
    }
}

/// Debounced saver for window geometry: coalesces the burst of Resized/Moved
/// events into a single DB write shortly after the last one.
#[cfg(desktop)]
fn schedule_window_bounds_save(app: &tauri::AppHandle) {
    if WINDOW_BOUNDS_SAVE_PENDING
        .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
        .is_err()
    {
        return;
    }
    let app = app.clone();
    std::thread::spawn(move || {
        // Let the burst of events settle before reading the final geometry.
        std::thread::sleep(std::time::Duration::from_millis(500));
        WINDOW_BOUNDS_SAVE_PENDING.store(false, Ordering::SeqCst);

        if let Some(window) = app.get_webview_window("main") {
            // Skip while maximized — the bounds would capture the maximized
            // size, not the user's preferred restore size.
            if window.is_maximized().unwrap_or(false) {
                return;
            }
            if let (Ok(pos), Ok(size)) = (window.outer_position(), window.outer_size()) {
                let _ = crate::db::save_window_bounds(&app, pos.x, pos.y, size.width, size.height);
            }
        }
    });
}

#[cfg(desktop)]
fn next_airing_label(app: &tauri::AppHandle) -> String {
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);

    let next = crate::db::get_airing_schedule(app)
        .ok()
        .and_then(|entries| entries.into_iter().find(|e| e.airing_at >= now));

    match next {
        Some(entry) => format!("Next airing: {} Ep {}", entry.title, entry.episode),
        None => "Next airing: no upcoming episodes".to_string(),
    }
}

#[cfg(desktop)]
fn update_tray_badge(app: &tauri::AppHandle) {
    let count = crate::db::get_unnotified_aired_count(app).unwrap_or(0);
    if let Some(tray) = app.tray_by_id(TRAY_ID) {
        let tooltip = if count > 0 {
            format!("MiyoList - {count} unnotified aired episode(s)")
        } else {
            "MiyoList".to_string()
        };
        let _ = tray.set_tooltip(Some(tooltip));

        #[cfg(not(target_os = "windows"))]
        {
            let title = if count > 0 {
                count.to_string()
            } else {
                String::new()
            };
            let _ = tray.set_title(Some(title));
        }
    }
}

#[cfg(desktop)]
fn restore_main_window(app: &tauri::AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.unminimize();
        let _ = window.set_focus();
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_notification::init())
        .plugin(
            // DEV-ONLY override: TAURI_UPDATER_PUBKEY lets a developer point the
            // updater at a locally-generated keypair without editing the config.
            // Shipped binaries embed whatever is in tauri.conf.json
            // `plugins.updater.pubkey` at build time (pubkeys are public, so the
            // real one must be committed there before the first release — the
            // matching private key goes into CI secrets, not the repo).
            {
                let mut builder = tauri_plugin_updater::Builder::new();
                if let Ok(pubkey) = std::env::var("TAURI_UPDATER_PUBKEY") {
                    if !pubkey.trim().is_empty() {
                        builder = builder.pubkey(pubkey);
                    }
                }
                builder.build()
            },
        )
        .setup(|app| {
            #[cfg(not(desktop))]
            let _ = app;
            #[cfg(desktop)]
            {
                let next_airing = next_airing_label(app.handle());

                let tray_menu = MenuBuilder::new(app)
                    .item(&MenuItemBuilder::with_id(TRAY_MENU_OPEN, "Open MiyoList").build(app)?)
                    .item(&MenuItemBuilder::with_id(TRAY_MENU_SYNC, "Quick Sync").build(app)?)
                    .item(&MenuItemBuilder::with_id(TRAY_MENU_NEXT_AIRING, next_airing).enabled(false).build(app)?)
                    .separator()
                    .item(&MenuItemBuilder::with_id(TRAY_MENU_QUIT, "Quit").build(app)?)
                    .build()?;

                restore_window_state(app.handle());

                // If Discord Rich Presence is enabled, connect and show the
                // default browsing activity right away.
                crate::discord::show_browsing(app.handle());

                // Kick off a first MangaUpdates release poll in the background
                // (respects the master toggle + online check inside).  Run it
                // off the main thread; it makes one HTTP request per tracked
                // series with pacing between them.
                let poll_app = app.handle().clone();
                std::thread::spawn(move || {
                    std::thread::sleep(std::time::Duration::from_secs(5));
                    if let Err(e) = crate::manga_releases::poll_manga_releases(&poll_app) {
                        eprintln!("[MANGA_RELEASES] initial poll failed: {e}");
                    }
                });

                TrayIconBuilder::with_id(TRAY_ID)
                    .icon(app.default_window_icon().cloned().expect("default window icon missing"))
                    .tooltip("MiyoList")
                    .menu(&tray_menu)
                    .show_menu_on_left_click(true)
                    .on_menu_event(|app, event| match event.id().as_ref() {
                        TRAY_MENU_OPEN => {
                            restore_main_window(app);
                        }
                        TRAY_MENU_SYNC => {
                            // Menu events run on the main thread, but a sync
                            // can take minutes under AniList rate limits and
                            // blocks on retries — run it off-thread so the
                            // tray and window stay responsive.
                            let app_handle = app.clone();
                            std::thread::spawn(move || {
                                let _ = crate::anilist::fetch_viewer(&app_handle);
                                let _ = crate::anilist::sync_lists_smart(&app_handle);
                                update_tray_badge(&app_handle);
                            });
                        }
                        TRAY_MENU_NEXT_AIRING => {
                            let title = next_airing_label(app);
                            let _ = app.notification().builder().title("MiyoList").body(&title).show();
                        }
                        TRAY_MENU_QUIT => {
                            EXITING_FROM_TRAY.store(true, Ordering::SeqCst);
                            app.exit(0);
                        }
                        _ => {}
                    })
                    .on_tray_icon_event(|tray, event| {
                        if let TrayIconEvent::Click {
                            button: MouseButton::Left,
                            button_state: MouseButtonState::Up,
                            ..
                        } = event
                        {
                            restore_main_window(tray.app_handle());
                        }
                    })
                    .build(app)?;

                update_tray_badge(app.handle());
            }

            Ok(())
        })
        .on_window_event(|window, event| {
            #[cfg(not(desktop))]
            let _ = (window, event);
            #[cfg(desktop)]
            {
                if let WindowEvent::Resized(_) | WindowEvent::Moved(_) = event {
                    schedule_window_bounds_save(window.app_handle());
                }

                if let WindowEvent::CloseRequested { api, .. } = event {
                    if EXITING_FROM_TRAY.load(Ordering::SeqCst) {
                        return;
                    }

                    let app = window.app_handle();
                    let should_minimize = crate::db::get_app_settings(app)
                        .map(|s| s.minimize_to_tray_on_close)
                        .unwrap_or(false);

                    if should_minimize {
                        api.prevent_close();
                        let _ = window.hide();

                        let already_shown = crate::db::get_bool_app_setting(app, TRAY_NOTICE_SHOWN_KEY)
                            .ok()
                            .flatten()
                            .unwrap_or(false);

                        if !already_shown {
                            let _ = app
                                .notification()
                                .builder()
                                .title("MiyoList is still running")
                                .body("The app was minimized to the system tray. Use the tray icon to reopen it.")
                                .show();
                            let _ = crate::db::set_bool_app_setting(app, TRAY_NOTICE_SHOWN_KEY, true);
                        }
                    }
                }
            }
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_bootstrap,
            commands::initialize_database,
            commands::get_database_overview,
            commands::prepare_auth_request,
            commands::get_anilist_config_status,
            commands::get_online_status,
            commands::get_viewer,
            commands::toggle_media_favorite,
            commands::toggle_favorite,
            commands::get_auth_session_status,
            commands::store_access_token,
            commands::clear_access_token,
            commands::get_library_snapshot,
            commands::sync_user_lists,
            commands::get_sync_progress,
            commands::get_list_entries,
            commands::get_list_entry_by_media_id,
            commands::update_list_entry,
            commands::delete_list_entry,
            commands::search_media,
            commands::get_trending_media,
            commands::add_to_library,
            commands::get_auth_callback_status,
            commands::reopen_auth_browser,
            commands::submit_auth_code_manually,
            commands::get_media_details,
            commands::search_themes,
            commands::get_themes_for_media,
            commands::get_favorite_themes,
            commands::toggle_favorite_theme,
            commands::push_dirty_entries,
            commands::get_airing_schedule,
            commands::get_global_airing_schedule,
            commands::refresh_airing_schedule,
            commands::check_notifications,
            commands::get_notification_settings,
            commands::save_notification_settings,
            commands::get_notification_overrides,
            commands::set_notification_override,
            commands::set_discord_hidden,
            commands::get_anilist_notifications,
            commands::increment_episode_progress,
            commands::get_library_stats,
            commands::get_activity_log,
            commands::get_activity_heatmap,
            commands::get_activity_log_by_date,
            commands::get_activity_monthly_totals,
            commands::get_annual_wrap_up,
            commands::get_app_settings,
            commands::save_app_settings,
            commands::check_for_updates,
            commands::install_update,
            commands::skip_update_version,
            commands::set_always_on_top,
            commands::set_discord_rpc,
            commands::search_mangaupdates_series,
            commands::get_manga_release_mappings,
            commands::set_manga_release_mapping,
            commands::clear_manga_release_mapping,
            commands::check_manga_releases,
            commands::get_sync_log,
                        commands::get_pending_conflicts,
                        commands::resolve_conflict,
            commands::get_cache_stats,
            commands::clear_search_history,
            commands::clear_orphan_media_cache,
            commands::clear_airing_cache,
            commands::clear_image_cache,
            commands::prefetch_covers,
            commands::get_cached_image_path,
            commands::export_library_json,
            commands::export_database_backup,
            commands::import_library_json,
            commands::get_favorites,
            commands::get_character_details,
            commands::get_staff_details,
            commands::get_studio_details,
            commands::get_user_profile,
            commands::search_characters,
            commands::search_staff,
            commands::search_studios,
            commands::search_users,
            commands::toggle_follow,
            commands::get_following,
            commands::get_followers,
            commands::get_following_activity,
            commands::get_global_activity,
            commands::toggle_activity_like,
            commands::save_activity_reply,
            commands::get_user_media_list,
            commands::post_activity,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
