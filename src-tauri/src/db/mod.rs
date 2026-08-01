use std::collections::HashMap;
use std::fs;
use std::ops::{Deref, DerefMut};
use std::path::PathBuf;
use std::sync::{Mutex, OnceLock};

use rusqlite::{Connection, OptionalExtension};
use tauri::{AppHandle, Manager};

use crate::models::{
    ActivityEntry, AppSettings, BreakdownItem, CacheStats, DatabaseInitResult, DatabaseOverview,
    DatabaseTableInfo, ExportResult, FavoriteTheme, FoundationModule, HeatmapDay, ImportResult,
    LibrarySnapshot, LibraryStats, MangaReleaseMapping, MonthlyActivityCount, NotificationOverride,
    NotificationSettings, PendingConflict, ScoreBucket, SyncLogEntry,
};

const DATABASE_FILE_NAME: &str = "miyolist.sqlite3";
const SCHEMA_VERSION: i64 = 10;
const PRODUCT_TABLES: [&str; 16] = [
    "app_settings",
    "auth_session",
    "media_cache",
    "media_list_entries",
    "user_profile_cache",
    "search_history",
    "notification_settings",
    "notification_overrides",
    "airing_cache",
    "statistics_snapshots",
    "activity_log",
    "favorites",
    "sync_log",
    "pending_conflicts",
    "manga_release_cache",
    "favorite_themes",
];

pub fn foundation_summary() -> FoundationModule {
    FoundationModule {
        name: "SQLite".into(),
        summary: "Initial local schema, versioned migrations, and table inspection are wired into the app shell.".into(),
        status: "ready".into(),
    }
}

pub fn initialize_database(app: &AppHandle) -> Result<DatabaseInitResult, String> {
    let database_path = database_path(app)?;
    let created_now = !database_path.exists();

    if let Some(parent) = database_path.parent() {
        fs::create_dir_all(parent).map_err(|error| error.to_string())?;
    }

    let connection = open_connection(&database_path)?;
    let migration_applied = apply_migrations(&connection)?;

    Ok(DatabaseInitResult {
        database_path: database_path.display().to_string(),
        schema_version: current_schema_version(&connection)?,
        created_now,
        migration_applied,
    })
}

pub fn get_database_overview(app: &AppHandle) -> Result<DatabaseOverview, String> {
    let database_path = database_path(app)?;

    if !database_path.exists() {
        return Err("Database has not been initialized yet.".into());
    }

    let connection = open_connection(&database_path)?;
    let tables = PRODUCT_TABLES
        .iter()
        .map(|table_name| table_info(&connection, table_name))
        .collect::<Result<Vec<_>, _>>()?;

    Ok(DatabaseOverview {
        database_path: database_path.display().to_string(),
        schema_version: current_schema_version(&connection)?,
        table_count: tables.len(),
        tables,
    })
}

pub(crate) fn database_path(app: &AppHandle) -> Result<PathBuf, String> {
    let app_data_dir = app
        .path()
        .app_data_dir()
        .map_err(|error| error.to_string())?;
    Ok(app_data_dir.join(DATABASE_FILE_NAME))
}

/// Idle SQLite connections keyed by database path.  Reusing connections avoids
/// re-running the per-connection PRAGMA setup on every command call, which
/// used to add overhead to each of the ~60 call sites.
static CONNECTION_POOL: OnceLock<Mutex<HashMap<PathBuf, Vec<Connection>>>> = OnceLock::new();

/// Upper bound on idle connections kept per database path.  Connections beyond
/// this are simply closed when returned (they are never shared concurrently).
const MAX_IDLE_CONNECTIONS: usize = 8;

/// A checked-out connection that returns itself to `CONNECTION_POOL` on drop.
/// Derefs to `rusqlite::Connection`, so existing call sites keep working.
pub(crate) struct PooledConnection {
    path: PathBuf,
    conn: Option<Connection>,
}

impl PooledConnection {
    fn new(path: PathBuf, conn: Connection) -> Self {
        Self {
            path,
            conn: Some(conn),
        }
    }
}

impl Deref for PooledConnection {
    type Target = Connection;
    fn deref(&self) -> &Self::Target {
        self.conn.as_ref().expect("pooled connection present")
    }
}

impl DerefMut for PooledConnection {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.conn.as_mut().expect("pooled connection present")
    }
}

impl Drop for PooledConnection {
    fn drop(&mut self) {
        let conn = match self.conn.take() {
            Some(conn) => conn,
            None => return,
        };
        // Never hand a connection with an open transaction to the next user:
        // roll it back first, otherwise the pooled connection inherits a stale
        // BEGIN from a caller that errored out mid-transaction.
        if !conn.is_autocommit() {
            let _ = conn.execute_batch("ROLLBACK");
        }
        if let Some(pool) = CONNECTION_POOL.get() {
            if let Ok(mut guard) = pool.lock() {
                let idle = guard.entry(self.path.clone()).or_default();
                if idle.len() < MAX_IDLE_CONNECTIONS {
                    // conn is moved into the pool here; dropping out of the
                    // block is equivalent to returning early.
                    idle.push(conn);
                }
            }
        }
        // Pool full or lock poisoned — the connection closes here.
    }
}

/// Opens a SQLite connection (reusing one from the pool when available) and
/// applies session-scoped PRAGMAs on newly created connections.
///
/// `journal_mode = WAL` is persistent on the file so it only takes effect the
/// first time.  The other PRAGMAs are session-scoped, so they are set only on
/// brand-new connections; pooled connections keep their settings.
pub(crate) fn open_connection(path: &PathBuf) -> Result<PooledConnection, String> {
    let pool = CONNECTION_POOL.get_or_init(|| Mutex::new(HashMap::new()));

    // Reuse an idle connection if one is parked for this path.
    let idle = match pool.lock() {
        Ok(mut guard) => guard.get_mut(path).and_then(|list| list.pop()),
        Err(_) => None,
    };
    if let Some(conn) = idle {
        return Ok(PooledConnection::new(path.clone(), conn));
    }

    let conn = Connection::open(path).map_err(|e| e.to_string())?;
    conn.execute_batch(
        "
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous  = NORMAL;
        PRAGMA foreign_keys = ON;
        PRAGMA cache_size   = -8000;
        ",
    )
    .map_err(|e| e.to_string())?;
    Ok(PooledConnection::new(path.clone(), conn))
}

// ─── Migration helpers ───────────────────────────────────────────────────────

/// Returns true when `column` already exists in `table`.
fn column_exists(conn: &Connection, table: &str, column: &str) -> bool {
    conn.prepare(&format!("PRAGMA table_info(\"{table}\")"))
        .ok()
        .and_then(|mut stmt| {
            stmt.query_map([], |row| row.get::<_, String>(1))
                .ok()
                .and_then(|rows| rows.collect::<Result<Vec<_>, _>>().ok())
        })
        .map(|cols| cols.iter().any(|c| c.eq_ignore_ascii_case(column)))
        .unwrap_or(false)
}

/// Adds `column` to `table` only when it does not already exist.
/// `definition` is everything after the column name, e.g. `"INTEGER NOT NULL DEFAULT 0"`.
fn add_column_if_missing(
    conn: &Connection,
    table: &str,
    column: &str,
    definition: &str,
) -> Result<(), String> {
    if !column_exists(conn, table, column) {
        conn.execute_batch(&format!(
            "ALTER TABLE \"{table}\" ADD COLUMN {column} {definition};"
        ))
        .map_err(|e| format!("Failed to add {table}.{column}: {e}"))?;
    }
    Ok(())
}

fn apply_migrations(connection: &Connection) -> Result<bool, String> {
    // PRAGMAs are set by open_connection(); here we only ensure the migration
    // tracking table exists.
    connection
        .execute_batch(
            "
            CREATE TABLE IF NOT EXISTS schema_migrations (
              version    INTEGER PRIMARY KEY,
              applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );
            ",
        )
        .map_err(|error| error.to_string())?;

    let current_version: i64 = connection
        .query_row(
            "SELECT COALESCE(MAX(version), 0) FROM schema_migrations",
            [],
            |row| row.get(0),
        )
        .map_err(|error| error.to_string())?;

    if current_version >= SCHEMA_VERSION {
        return Ok(false);
    }

    for v in (current_version + 1)..=SCHEMA_VERSION {
        match v {
            1 => apply_v1(connection)?,
            2 => apply_v2(connection)?,
            3 => apply_v3(connection)?,
            4 => apply_v4(connection)?,
            5 => apply_v5(connection)?,
            6 => apply_v6(connection)?,
            7 => apply_v7(connection)?,
            8 => apply_v8(connection)?,
            9 => apply_v9(connection)?,
            10 => apply_v10(connection)?,
            _ => {}
        }
    }

    Ok(true)
}

fn apply_v1(connection: &Connection) -> Result<(), String> {
    connection
        .execute_batch(
            "
            BEGIN;

            CREATE TABLE IF NOT EXISTS app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS auth_session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              access_token TEXT,
              viewer_id INTEGER,
              acquired_at TEXT,
              expires_at TEXT,
              auth_state TEXT,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS media_cache (
              media_id INTEGER PRIMARY KEY,
              media_type TEXT NOT NULL,
              title_romaji TEXT,
              title_english TEXT,
              cover_image TEXT,
              banner_image TEXT,
              payload_json TEXT NOT NULL,
              fetched_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS media_list_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_id INTEGER NOT NULL,
              media_type TEXT NOT NULL,
              list_kind TEXT NOT NULL,
              status TEXT NOT NULL,
              score REAL,
              progress INTEGER NOT NULL DEFAULT 0,
              repeat_count INTEGER NOT NULL DEFAULT 0,
              notes TEXT,
              started_at TEXT,
              completed_at TEXT,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              ani_list_updated_at TEXT,
              is_dirty INTEGER NOT NULL DEFAULT 0,
              source TEXT NOT NULL DEFAULT 'local',
              UNIQUE(media_id, media_type, list_kind)
            );

            CREATE INDEX IF NOT EXISTS idx_media_list_entries_status
              ON media_list_entries(status);
            CREATE INDEX IF NOT EXISTS idx_media_list_entries_type
              ON media_list_entries(media_type, list_kind);

            CREATE TABLE IF NOT EXISTS user_profile_cache (
              user_id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              avatar_url TEXT,
              banner_image TEXT,
              about TEXT,
              payload_json TEXT NOT NULL,
              fetched_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS search_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              query TEXT NOT NULL,
              media_type TEXT,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_search_history_created_at
              ON search_history(created_at DESC);

            CREATE TABLE IF NOT EXISTS notification_settings (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              airing_enabled INTEGER NOT NULL DEFAULT 1,
              activity_enabled INTEGER NOT NULL DEFAULT 1,
              forum_enabled INTEGER NOT NULL DEFAULT 1,
              follows_enabled INTEGER NOT NULL DEFAULT 1,
              media_enabled INTEGER NOT NULL DEFAULT 1,
                            submissions_enabled INTEGER NOT NULL DEFAULT 1,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

                        CREATE TABLE IF NOT EXISTS notification_overrides (
                            media_id INTEGER PRIMARY KEY,
                            enabled INTEGER NOT NULL DEFAULT 1,
                            updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                        );

            CREATE TABLE IF NOT EXISTS airing_cache (
              media_id INTEGER NOT NULL,
              episode INTEGER NOT NULL,
              airing_at INTEGER NOT NULL,
              payload_json TEXT NOT NULL,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY(media_id, episode)
            );

            CREATE TABLE IF NOT EXISTS statistics_snapshots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              snapshot_kind TEXT NOT NULL,
              payload_json TEXT NOT NULL,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            INSERT INTO schema_migrations(version) VALUES (1);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v2 — explicit columns derived from the Flutter Hive model audit.
///
/// # Canonical data ownership
///
/// ## AniList-canonical (remote wins on sync; local copy is a working draft)
/// - `media_list_entries`: `anilist_entry_id`, `status`, `score`, `progress`,
///   `progress_volumes`, `repeat_count`, `notes`, `started_at`, `completed_at`
/// - `media_cache`: all columns (title, cover, format, is_adult, …)
/// - `user_profile_cache`: all columns
///
/// ## Locally-canonical (never overwritten by a remote sync)
/// - `media_list_entries`: `is_dirty`, `source`, `custom_lists_json`
/// - `app_settings`: all rows
/// - `activity_log`: all rows
/// - `search_history`: all rows
///
/// ## Mixed (local write, authoritative after successful sync)
/// - `media_list_entries.updated_at` — set on local edit, then confirmed by
///   `ani_list_updated_at` after a successful save mutation.
///
/// # Idempotency
///
/// `ALTER TABLE … ADD COLUMN` statements are wrapped in `add_column_if_missing`
/// so that a previously-interrupted migration (crash, forced kill, etc.) does
/// not cause the next startup to fail and leave the schema version unrecorded.
fn apply_v2(connection: &Connection) -> Result<(), String> {
    // ALTER TABLE statements run *outside* a wrapping transaction so that a
    // partial run (app killed mid-migration) leaves whatever columns were
    // already added in place rather than rolling them back.  Each helper is a
    // no-op when the column already exists.
    add_column_if_missing(
        connection,
        "media_list_entries",
        "anilist_entry_id",
        "INTEGER",
    )?;
    add_column_if_missing(
        connection,
        "media_list_entries",
        "progress_volumes",
        "INTEGER NOT NULL DEFAULT 0",
    )?;
    add_column_if_missing(
        connection,
        "media_list_entries",
        "custom_lists_json",
        "TEXT",
    )?;
    add_column_if_missing(
        connection,
        "media_cache",
        "is_adult",
        "INTEGER NOT NULL DEFAULT 0",
    )?;
    add_column_if_missing(connection, "media_cache", "title_native", "TEXT")?;

    // Everything else (indexes, new tables) is safely idempotent via IF NOT
    // EXISTS.  Use INSERT OR IGNORE so re-running after a partial migration
    // does not fail on a duplicate version row.
    connection
        .execute_batch(
            "
            BEGIN;

            CREATE INDEX IF NOT EXISTS idx_media_list_entries_anilist_id
              ON media_list_entries(anilist_entry_id);

            -- activity_log: derived from Flutter ActivityEntry (typeId: 22)
            -- Purely local; never pushed to AniList.
            CREATE TABLE IF NOT EXISTS activity_log (
              id            INTEGER PRIMARY KEY AUTOINCREMENT,
              media_id      INTEGER NOT NULL,
              media_type    TEXT NOT NULL,
              activity_type TEXT NOT NULL,
              old_value     TEXT,
              new_value     TEXT,
              note          TEXT,
              created_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_activity_log_media
              ON activity_log(media_id, created_at DESC);
            CREATE INDEX IF NOT EXISTS idx_activity_log_created
              ON activity_log(created_at DESC);

            -- favorites: local bookmark layer; AniList favorites fetched
            -- separately and overlaid on top of this table.
            CREATE TABLE IF NOT EXISTS favorites (
              media_id   INTEGER NOT NULL,
              media_type TEXT NOT NULL,
              added_at   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              source     TEXT NOT NULL DEFAULT 'local',
              PRIMARY KEY (media_id, media_type)
            );

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (2);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v3 — normalise `media_type` / `list_kind` case to UPPERCASE and
/// remove duplicate rows that were created when v1 sync stored lowercase
/// ('anime') and v2 sync stored uppercase ('ANIME') for the same entry.
///
/// Deduplication keeps the row with the highest `id` (most-recently inserted)
/// for each logical key `(media_id, UPPER(media_type), UPPER(list_kind))`.
/// After removing duplicates the case normalisation cannot violate the UNIQUE
/// constraint because every logical key is represented exactly once.
fn apply_v3(connection: &Connection) -> Result<(), String> {
    connection
        .execute_batch(
            "
            BEGIN;

            -- Remove duplicate entries, keeping the latest insert per logical key.
            DELETE FROM media_list_entries
            WHERE id NOT IN (
                SELECT MAX(id)
                FROM media_list_entries
                GROUP BY media_id, UPPER(media_type), UPPER(list_kind)
            );

            -- Normalise to UPPERCASE so future ON CONFLICT clauses always match.
            UPDATE media_list_entries
            SET media_type = UPPER(media_type),
                list_kind  = UPPER(list_kind);

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (3);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v4 — airing schedule support.
///
/// Adds `notified` flag to `airing_cache` so the notification system can
/// track which episodes have already generated a desktop alert.
fn apply_v4(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(
        connection,
        "airing_cache",
        "notified",
        "INTEGER NOT NULL DEFAULT 0",
    )?;

    connection
        .execute_batch(
            "
            BEGIN;

            CREATE INDEX IF NOT EXISTS idx_airing_cache_airing_at
              ON airing_cache(airing_at);

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (4);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v5 — no structural changes; just seeds the migrations table so
/// that the statistics queries work against the existing tables.
fn apply_v5(connection: &Connection) -> Result<(), String> {
    connection
        .execute_batch(
            "
            BEGIN;
            INSERT OR IGNORE INTO schema_migrations(version) VALUES (5);
            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v6 — sync infrastructure.
///
/// Adds `sync_log` for per-entry sync audit trail, and the two new
/// `app_settings` keys (`auto_sync_interval`, `sync_high_water`) are stored as
/// regular key-value rows — no DDL change needed for those.
fn apply_v6(connection: &Connection) -> Result<(), String> {
    connection
        .execute_batch(
            "
            BEGIN;

            CREATE TABLE IF NOT EXISTS sync_log (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              media_id    INTEGER NOT NULL,
              sync_type   TEXT NOT NULL,
              detail      TEXT,
              created_at  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_sync_log_created
              ON sync_log(created_at DESC);
            CREATE INDEX IF NOT EXISTS idx_sync_log_media
              ON sync_log(media_id, created_at DESC);

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (6);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

fn apply_v7(connection: &Connection) -> Result<(), String> {
    connection
        .execute_batch(
            "
            BEGIN;

            CREATE TABLE IF NOT EXISTS pending_conflicts (
              media_id          INTEGER PRIMARY KEY,
              media_type        TEXT NOT NULL DEFAULT 'ANIME',
              local_status      TEXT,
              local_score       REAL,
              local_progress    INTEGER NOT NULL DEFAULT 0,
              local_notes       TEXT,
              remote_status     TEXT,
              remote_score      REAL,
              remote_progress   INTEGER NOT NULL DEFAULT 0,
              remote_notes      TEXT,
              detected_at       TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (7);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

fn apply_v8(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(
        connection,
        "notification_settings",
        "submissions_enabled",
        "INTEGER NOT NULL DEFAULT 1",
    )?;

    connection
        .execute_batch(
            "
            BEGIN;

            CREATE TABLE IF NOT EXISTS notification_overrides (
              media_id INTEGER PRIMARY KEY,
              enabled INTEGER NOT NULL DEFAULT 1,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (8);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v9 — MangaUpdates release tracking.
///
/// Adds the `manga_release_cache` table (AniList media → MangaUpdates series
/// link + notification high-water mark) and a `manga_releases_enabled` toggle
/// on `notification_settings`.  No existing rows are touched.
fn apply_v9(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(
        connection,
        "notification_settings",
        "manga_releases_enabled",
        "INTEGER NOT NULL DEFAULT 0",
    )?;

    connection
        .execute_batch(
            "
            BEGIN;

            CREATE TABLE IF NOT EXISTS manga_release_cache (
              media_id       INTEGER PRIMARY KEY,
              media_type     TEXT NOT NULL DEFAULT 'MANGA',
              mu_series_id   INTEGER,
              mu_title       TEXT,
              last_item_title TEXT,
              manual         INTEGER NOT NULL DEFAULT 0,
              updated_at     TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (9);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

/// Schema v10 — per-media Discord privacy + favourite OP/ED themes.
///
/// Adds `discord_hidden` to `notification_overrides` so a title can stay
/// visible in notifications but be excluded from the Discord Rich Presence
/// (desktop only).  Creates `favorite_themes` (media → starred theme) for the
/// OP/ED star button in the media details panel.  No existing rows are touched.
fn apply_v10(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(
        connection,
        "notification_overrides",
        "discord_hidden",
        "INTEGER NOT NULL DEFAULT 0",
    )?;

    connection
        .execute_batch(
            "
            BEGIN;

            CREATE TABLE IF NOT EXISTS favorite_themes (
              media_id    INTEGER NOT NULL,
              theme_id    INTEGER NOT NULL,
              theme_type  TEXT NOT NULL DEFAULT '',
              song_title  TEXT NOT NULL DEFAULT '',
              artists     TEXT NOT NULL DEFAULT '[]',
              added_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (media_id, theme_id)
            );

            INSERT OR IGNORE INTO schema_migrations(version) VALUES (10);

            COMMIT;
            ",
        )
        .map_err(|error| error.to_string())
}

fn current_schema_version(connection: &Connection) -> Result<i64, String> {
    connection
        .query_row(
            "SELECT COALESCE(MAX(version), 0) FROM schema_migrations",
            [],
            |row| row.get(0),
        )
        .map_err(|error| error.to_string())
}

fn table_info(connection: &Connection, table_name: &str) -> Result<DatabaseTableInfo, String> {
    let exists = connection
        .query_row(
            "SELECT EXISTS(SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?1)",
            [table_name],
            |row| row.get::<_, i64>(0),
        )
        .map_err(|error| error.to_string())?
        == 1;

    let row_count = if exists {
        let query = format!("SELECT COUNT(*) FROM {table_name}");
        connection
            .query_row(query.as_str(), [], |row| row.get(0))
            .map_err(|error| error.to_string())?
    } else {
        0
    };

    Ok(DatabaseTableInfo {
        name: table_name.to_string(),
        exists,
        row_count,
    })
}

pub fn get_library_snapshot(app: &AppHandle) -> Result<LibrarySnapshot, String> {
    initialize_database(app)?;

    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;

    let (total_entries, anime_entries, manga_entries, current_entries, planned_entries, completed_entries) = connection
        .query_row(
            "
            SELECT
              COUNT(*) as total_entries,
              SUM(CASE WHEN UPPER(media_type) = 'ANIME' THEN 1 ELSE 0 END) as anime_entries,
              SUM(CASE WHEN UPPER(media_type) = 'MANGA' THEN 1 ELSE 0 END) as manga_entries,
              SUM(CASE WHEN LOWER(status) IN ('current', 'repeating') THEN 1 ELSE 0 END) as current_entries,
              SUM(CASE WHEN LOWER(status) = 'planning' THEN 1 ELSE 0 END) as planned_entries,
              SUM(CASE WHEN LOWER(status) = 'completed' THEN 1 ELSE 0 END) as completed_entries
            FROM media_list_entries
            ",
            [],
            |row| {
                Ok((
                    row.get::<_, i64>(0)?,
                    row.get::<_, Option<i64>>(1)?.unwrap_or(0),
                    row.get::<_, Option<i64>>(2)?.unwrap_or(0),
                    row.get::<_, Option<i64>>(3)?.unwrap_or(0),
                    row.get::<_, Option<i64>>(4)?.unwrap_or(0),
                    row.get::<_, Option<i64>>(5)?.unwrap_or(0),
                ))
            },
        )
        .map_err(|error| error.to_string())?;

    let cached_media = connection
        .query_row("SELECT COUNT(*) FROM media_cache", [], |row| row.get(0))
        .map_err(|error| error.to_string())?;
    let search_history_count = connection
        .query_row("SELECT COUNT(*) FROM search_history", [], |row| row.get(0))
        .map_err(|error| error.to_string())?;

    let session = connection
        .query_row(
            "SELECT access_token, viewer_id FROM auth_session WHERE id = 1",
            [],
            |row| {
                Ok((
                    row.get::<_, Option<String>>(0)?,
                    row.get::<_, Option<i64>>(1)?,
                ))
            },
        )
        .optional()
        .map_err(|error| error.to_string())?;

    let (has_access_token, viewer_id) = session
        .map(|(token, viewer_id)| {
            (
                token.map(|value| !value.trim().is_empty()).unwrap_or(false),
                viewer_id,
            )
        })
        .unwrap_or((false, None));

    let (profile_name, profile_avatar_url) = if let Some(id) = viewer_id {
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

    Ok(LibrarySnapshot {
        total_entries,
        anime_entries,
        manga_entries,
        current_entries,
        planned_entries,
        completed_entries,
        cached_media,
        search_history_count,
        profile_name,
        profile_avatar_url,
        has_access_token,
    })
}
// ─── List entry reads ─────────────────────────────────────────────────────────

pub fn get_list_entries(
    app: &AppHandle,
    media_type: Option<String>,
    status: Option<String>,
) -> Result<Vec<crate::models::ListEntry>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;

    let effective_status = status.filter(|s| !matches!(s.as_str(), "all" | ""));

    let base = "SELECT e.id, e.anilist_entry_id, e.media_id, e.media_type, e.list_kind,
        COALESCE(c.title_english, c.title_romaji, CAST(e.media_id AS TEXT)) AS title,
        c.cover_image, e.status, e.score, e.progress, e.progress_volumes,
        COALESCE(
            CAST(json_extract(c.payload_json,'$.episodes') AS INTEGER),
            CAST(json_extract(c.payload_json,'$.chapters') AS INTEGER)
        ) AS eoc,
        e.repeat_count, e.notes, e.started_at, e.completed_at,
        COALESCE(e.custom_lists_json, '[]'), e.updated_at, e.is_dirty
        FROM media_list_entries e
        LEFT JOIN media_cache c ON c.media_id = e.media_id";

    // Build WHERE clause and collect boxed params at the same scope level
    let mut where_parts: Vec<String> = Vec::new();
    let mut param_values: Vec<String> = Vec::new();

    // "NOVEL" is AniList manga with format = NOVEL; "MANGA" excludes novels.
    match media_type.as_deref() {
        Some("NOVEL") => {
            where_parts.push("UPPER(e.media_type) = 'MANGA'".to_string());
            where_parts.push(
                "UPPER(COALESCE(json_extract(c.payload_json,'$.format'),'')) = 'NOVEL'".to_string(),
            );
        }
        Some("MANGA") => {
            where_parts.push("UPPER(e.media_type) = 'MANGA'".to_string());
            where_parts.push(
                "UPPER(COALESCE(json_extract(c.payload_json,'$.format'),'')) != 'NOVEL'"
                    .to_string(),
            );
        }
        Some(mt) if !mt.is_empty() => {
            where_parts.push(format!("UPPER(e.media_type) = ?{}", param_values.len() + 1));
            param_values.push(mt.to_ascii_uppercase());
        }
        _ => {}
    }
    match effective_status.as_deref() {
        Some("watching") | Some("current") => {
            where_parts.push("e.status IN ('current','repeating')".to_string());
        }
        Some(st) => {
            where_parts.push(format!("e.status = ?{}", param_values.len() + 1));
            param_values.push(st.to_string());
        }
        None => {}
    }

    let where_sql = if where_parts.is_empty() {
        String::new()
    } else {
        format!("WHERE {}", where_parts.join(" AND "))
    };
    let sql = format!("{base} {where_sql} ORDER BY e.updated_at DESC");

    let mut stmt = connection.prepare(&sql).map_err(|e| e.to_string())?;
    let params_refs: Vec<&dyn rusqlite::ToSql> = param_values
        .iter()
        .map(|v| v as &dyn rusqlite::ToSql)
        .collect();

    let entries = stmt
        .query_map(params_refs.as_slice(), |row| {
            // col 16 = custom_lists_json, 17 = updated_at, 18 = is_dirty
            // col 14 = started_at, 15 = completed_at
            let custom_lists_json: String = row.get(16)?;
            let custom_lists: Vec<String> =
                serde_json::from_str(&custom_lists_json).unwrap_or_default();
            Ok(crate::models::ListEntry {
                local_id: row.get(0)?,
                anilist_entry_id: row.get(1)?,
                media_id: row.get(2)?,
                media_type: row.get(3)?,
                list_kind: row.get(4)?,
                title: row.get(5)?,
                cover_image: row.get(6)?,
                status: row.get(7)?,
                score: row.get(8)?,
                progress: row.get(9)?,
                progress_volumes: row.get(10)?,
                episodes_or_chapters: row.get(11)?,
                repeat_count: row.get(12)?,
                notes: row.get(13)?,
                started_at: row.get(14)?,
                completed_at: row.get(15)?,
                custom_lists,
                updated_at: row.get(17)?,
                is_dirty: row.get::<_, i64>(18)? != 0,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(entries)
}

pub fn get_list_entry_by_media_id(
    app: &AppHandle,
    media_id: i64,
) -> Result<Option<crate::models::ListEntry>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;

    let sql = "SELECT e.id, e.anilist_entry_id, e.media_id, e.media_type, e.list_kind,
        COALESCE(c.title_english, c.title_romaji, CAST(e.media_id AS TEXT)) AS title,
        c.cover_image, e.status, e.score, e.progress, e.progress_volumes,
        COALESCE(
            CAST(json_extract(c.payload_json,'$.episodes') AS INTEGER),
            CAST(json_extract(c.payload_json,'$.chapters') AS INTEGER)
        ) AS eoc,
        e.repeat_count, e.notes, e.started_at, e.completed_at,
        COALESCE(e.custom_lists_json, '[]'), e.updated_at, e.is_dirty
        FROM media_list_entries e
        LEFT JOIN media_cache c ON c.media_id = e.media_id
        WHERE e.media_id = ?1
        ORDER BY e.updated_at DESC
        LIMIT 1";

    let mut stmt = connection.prepare(sql).map_err(|e| e.to_string())?;
    let entry = stmt
        .query_row([media_id], |row| {
            let custom_lists_json: String = row.get(16)?;
            let custom_lists: Vec<String> =
                serde_json::from_str(&custom_lists_json).unwrap_or_default();
            Ok(crate::models::ListEntry {
                local_id: row.get(0)?,
                anilist_entry_id: row.get(1)?,
                media_id: row.get(2)?,
                media_type: row.get(3)?,
                list_kind: row.get(4)?,
                title: row.get(5)?,
                cover_image: row.get(6)?,
                status: row.get(7)?,
                score: row.get(8)?,
                progress: row.get(9)?,
                progress_volumes: row.get(10)?,
                episodes_or_chapters: row.get(11)?,
                repeat_count: row.get(12)?,
                notes: row.get(13)?,
                started_at: row.get(14)?,
                completed_at: row.get(15)?,
                custom_lists,
                updated_at: row.get(17)?,
                is_dirty: row.get::<_, i64>(18)? != 0,
            })
        })
        .optional()
        .map_err(|e| e.to_string())?;

    Ok(entry)
}

// ─── List entry writes ────────────────────────────────────────────────────────

#[allow(clippy::too_many_arguments)]
pub fn update_list_entry_local(
    app: &AppHandle,
    local_id: i64,
    status: &str,
    score: Option<f64>,
    progress: i64,
    progress_volumes: i64,
    repeat_count: i64,
    start_date: Option<String>,
    completed_date: Option<String>,
    notes: Option<String>,
    custom_lists: Option<Vec<String>>,
) -> Result<(), String> {
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;

    // Read old values before updating so we can log what changed.
    let old = connection
        .query_row(
            "SELECT media_id, UPPER(media_type), status, score, progress FROM media_list_entries WHERE id = ?1",
            [local_id],
            |r| {
                Ok((
                    r.get::<_, i64>(0)?,
                    r.get::<_, String>(1)?,
                    r.get::<_, String>(2)?,
                    r.get::<_, Option<f64>>(3)?,
                    r.get::<_, i64>(4)?,
                ))
            },
        )
        .ok();

    let custom_lists_json = serde_json::to_string(&custom_lists.unwrap_or_default())
        .unwrap_or_else(|_| "[]".to_string());

    connection
        .execute(
            "UPDATE media_list_entries
             SET status=?1, score=?2, progress=?3, progress_volumes=?4,
                 repeat_count=?5, started_at=?6, completed_at=?7,
                 notes=?8, custom_lists_json=?9, is_dirty=1, updated_at=CURRENT_TIMESTAMP
             WHERE id=?10",
            (
                status,
                score,
                progress,
                progress_volumes,
                repeat_count,
                &start_date,
                &completed_date,
                &notes,
                &custom_lists_json,
                local_id,
            ),
        )
        .map_err(|e| e.to_string())?;

    // Log each changed field.
    if let Some((media_id, media_type, old_status, old_score, old_progress)) = old {
        let mt = media_type.as_str();
        if old_status.to_uppercase() != status.to_uppercase() {
            let _ = log_activity_conn(
                &connection,
                media_id,
                mt,
                "status_change",
                Some(&old_status),
                Some(status),
                None,
            );
        }
        let new_score_key = score.map(|s| format!("{:.1}", s));
        let old_score_key = old_score.map(|s| format!("{:.1}", s));
        if old_score_key != new_score_key {
            let _ = log_activity_conn(
                &connection,
                media_id,
                mt,
                "score_change",
                old_score_key.as_deref(),
                new_score_key.as_deref(),
                None,
            );
        }
        if old_progress != progress {
            let _ = log_activity_conn(
                &connection,
                media_id,
                mt,
                "progress_update",
                Some(&old_progress.to_string()),
                Some(&progress.to_string()),
                None,
            );
        }
    }

    Ok(())
}

pub fn clear_entry_dirty(app: &AppHandle, local_id: i64) -> Result<(), String> {
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;
    connection
        .execute(
            "UPDATE media_list_entries SET is_dirty=0, updated_at=CURRENT_TIMESTAMP WHERE id=?1",
            [local_id],
        )
        .map_err(|e| e.to_string())?;
    Ok(())
}

/// Returns all entries flagged as locally-modified (`is_dirty = 1`) with the
/// fields required by the `SaveMediaListEntry` AniList mutation.
/// Tuple: `(local_id, media_id, status, score, progress, progress_volumes, repeat_count, started_at, completed_at, notes, custom_lists)`
#[allow(clippy::type_complexity)]
pub fn get_dirty_entries(
    app: &AppHandle,
) -> Result<
    Vec<(
        i64,
        i64,
        String,
        Option<f64>,
        i64,
        i64,
        i64,
        Option<String>,
        Option<String>,
        Option<String>,
        Vec<String>,
    )>,
    String,
> {
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;
    let mut stmt = connection
        .prepare(
            "SELECT id, media_id, status, score, progress, progress_volumes,
                    repeat_count, started_at, completed_at, notes, COALESCE(custom_lists_json, '[]')
             FROM media_list_entries
             WHERE is_dirty = 1
             ORDER BY updated_at ASC",
        )
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, i64>(0)?,
                row.get::<_, i64>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, Option<f64>>(3)?,
                row.get::<_, i64>(4)?,
                row.get::<_, i64>(5)?,
                row.get::<_, i64>(6)?,
                row.get::<_, Option<String>>(7)?,
                row.get::<_, Option<String>>(8)?,
                row.get::<_, Option<String>>(9)?,
                serde_json::from_str::<Vec<String>>(&row.get::<_, String>(10)?).unwrap_or_default(),
            ))
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(rows)
}

pub fn delete_list_entry_local(app: &AppHandle, local_id: i64) -> Result<(), String> {
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;
    connection
        .execute("DELETE FROM media_list_entries WHERE id = ?1", [local_id])
        .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn add_entry_to_library(
    app: &AppHandle,
    media_id: i64,
    media_type: &str,
    status: &str,
    title: Option<&str>,
    cover_image: Option<&str>,
) -> Result<(), String> {
    let database_path = database_path(app)?;
    let connection = open_connection(&database_path)?;

    if let Some(t) = title {
        connection
            .execute(
                "INSERT INTO media_cache (media_id, media_type, title_romaji, title_english, cover_image, payload_json)
                 VALUES (?1, ?2, ?3, ?3, ?4, '{}')
                 ON CONFLICT(media_id) DO UPDATE SET
                   title_romaji = COALESCE(excluded.title_romaji, title_romaji),
                   title_english = COALESCE(excluded.title_english, title_english),
                   cover_image = COALESCE(excluded.cover_image, cover_image)",
                (&media_id, media_type, t, cover_image),
            )
            .map_err(|e| e.to_string())?;
    }

    connection
        .execute(
            "INSERT INTO media_list_entries (media_id, media_type, list_kind, status, progress, is_dirty, source)
             VALUES (?1, ?2, ?3, ?4, 0, 1, 'local')
             ON CONFLICT(media_id, media_type, list_kind) DO UPDATE SET
               status = excluded.status, is_dirty = 1, updated_at = CURRENT_TIMESTAMP",
            (&media_id, media_type, media_type, status),
        )
        .map_err(|e| e.to_string())?;

    Ok(())
}

// ─── Airing schedule ─────────────────────────────────────────────────────────

/// Returns all cached airing entries, enriched with user-list data where
/// available, ordered by `airing_at` ascending.
pub fn get_airing_schedule(app: &AppHandle) -> Result<Vec<crate::models::AiringEntry>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT
               ac.media_id,
               COALESCE(mc.title_english, mc.title_romaji, CAST(ac.media_id AS TEXT)) AS title,
               mc.cover_image,
               ac.episode,
               CAST(ac.airing_at AS INTEGER) AS airing_at,
               ac.notified,
               COALESCE(mle.progress, 0)     AS user_progress,
               COALESCE(mle.status, '')       AS list_status,
               mle.score,
               CAST(json_extract(mc.payload_json, '$.episodes') AS INTEGER) AS total_episodes
             FROM airing_cache ac
             LEFT JOIN media_cache mc  ON mc.media_id = ac.media_id
             LEFT JOIN media_list_entries mle
               ON mle.media_id = ac.media_id AND UPPER(mle.media_type) = 'ANIME'
             ORDER BY CAST(ac.airing_at AS INTEGER) ASC",
        )
        .map_err(|e| e.to_string())?;

    let rows = stmt
        .query_map([], |row| {
            Ok(crate::models::AiringEntry {
                media_id: row.get(0)?,
                title: row.get(1)?,
                cover_image: row.get(2)?,
                episode: row.get(3)?,
                airing_at: row.get(4)?,
                notified: row.get::<_, i64>(5)? != 0,
                user_progress: row.get(6)?,
                list_status: row.get(7)?,
                score: row.get(8)?,
                total_episodes: row.get(9)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(rows)
}

/// Returns all airing entries that have aired (airing_at < now) and have not
/// yet been notified.  Caller should send OS notifications and then call
/// `mark_airing_notified` for each.
pub fn get_unnotified_aired(app: &AppHandle) -> Result<Vec<crate::models::AiringEntry>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT
               ac.media_id,
               COALESCE(mc.title_english, mc.title_romaji, CAST(ac.media_id AS TEXT)) AS title,
               mc.cover_image,
               ac.episode,
               CAST(ac.airing_at AS INTEGER) AS airing_at,
               0 AS notified,
               COALESCE(mle.progress, 0),
               COALESCE(mle.status, ''),
               mle.score,
               CAST(json_extract(mc.payload_json, '$.episodes') AS INTEGER)
             FROM airing_cache ac
             LEFT JOIN media_cache mc  ON mc.media_id = ac.media_id
             LEFT JOIN media_list_entries mle
               ON mle.media_id = ac.media_id AND UPPER(mle.media_type) = 'ANIME'
                         LEFT JOIN notification_overrides no ON no.media_id = ac.media_id
             WHERE ac.airing_at < strftime('%s', 'now')
                             AND ac.notified = 0
                             AND COALESCE(no.enabled, 1) = 1",
        )
        .map_err(|e| e.to_string())?;

    let rows = stmt
        .query_map([], |row| {
            Ok(crate::models::AiringEntry {
                media_id: row.get(0)?,
                title: row.get(1)?,
                cover_image: row.get(2)?,
                episode: row.get(3)?,
                airing_at: row.get(4)?,
                notified: false,
                user_progress: row.get(6)?,
                list_status: row.get(7)?,
                score: row.get(8)?,
                total_episodes: row.get(9)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(rows)
}

/// Returns count of aired entries that are still unnotified.
#[cfg(desktop)]
pub fn get_unnotified_aired_count(app: &AppHandle) -> Result<i64, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    conn.query_row(
        "SELECT COUNT(*)
         FROM airing_cache ac
         LEFT JOIN notification_overrides no ON no.media_id = ac.media_id
         WHERE ac.airing_at < strftime('%s', 'now')
           AND ac.notified = 0
           AND COALESCE(no.enabled, 1) = 1",
        [],
        |r| r.get(0),
    )
    .map_err(|e| e.to_string())
}

/// Reads a string app setting from `app_settings` by key.
#[cfg(desktop)]
pub fn get_string_app_setting(app: &AppHandle, key: &str) -> Result<Option<String>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    conn.query_row(
        "SELECT value FROM app_settings WHERE key = ?1",
        [key],
        |r| r.get(0),
    )
    .optional()
    .map_err(|e| e.to_string())
}

/// Persists a string app setting in `app_settings` by key.
#[cfg(desktop)]
pub fn set_string_app_setting(app: &AppHandle, key: &str, value: &str) -> Result<(), String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    conn.execute(
        "INSERT INTO app_settings(key, value) VALUES(?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP",
        (key, value),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Reads a boolean app setting from `app_settings` by key.
#[cfg(desktop)]
pub fn get_bool_app_setting(app: &AppHandle, key: &str) -> Result<Option<bool>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let val: Option<String> = conn
        .query_row(
            "SELECT value FROM app_settings WHERE key = ?1",
            [key],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;

    Ok(val.map(|v| v == "1" || v.eq_ignore_ascii_case("true")))
}

/// Persists a boolean app setting in `app_settings` by key.
#[cfg(desktop)]
pub fn set_bool_app_setting(app: &AppHandle, key: &str, value: bool) -> Result<(), String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let val = if value { "1" } else { "0" };

    conn.execute(
        "INSERT INTO app_settings(key, value) VALUES(?1, ?2)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP",
        (key, val),
    )
    .map_err(|e| e.to_string())?;

    Ok(())
}

/// Persist the main window's outer bounds (physical pixels) so they can be
/// restored on the next launch.  Stored as a compact JSON string under the
/// `window_bounds` key.
pub fn save_window_bounds(
    app: &AppHandle,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
) -> Result<(), String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let json = serde_json::json!({
        "x": x,
        "y": y,
        "width": width,
        "height": height,
    })
    .to_string();
    conn.execute(
        "INSERT INTO app_settings(key, value) VALUES('window_bounds', ?1)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP",
        [json.as_str()],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Best local title for a media id (from `media_cache`), used by the
/// AnimeThemes integration to look up OP/ED by title.
pub fn get_cached_media_title(app: &AppHandle, media_id: i64) -> Result<String, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let title: Option<String> = conn
        .query_row(
            "SELECT COALESCE(title_english, title_romaji, title_native)
             FROM media_cache WHERE media_id = ?1",
            [media_id],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    Ok(title.unwrap_or_default())
}

/// Read the persisted main-window bounds, if any.  Returns `(x, y, width, height)`
/// in physical pixels, or `None` when the user has never resized/moved the window.
pub fn get_window_bounds(app: &AppHandle) -> Result<Option<(i32, i32, u32, u32)>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let value: Option<String> = conn
        .query_row(
            "SELECT value FROM app_settings WHERE key = 'window_bounds'",
            [],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;

    let Some(json) = value else {
        return Ok(None);
    };
    let parsed: serde_json::Value =
        serde_json::from_str(&json).map_err(|e| format!("invalid window_bounds: {e}"))?;
    Ok(Some((
        parsed.get("x").and_then(|v| v.as_i64()).unwrap_or(0) as i32,
        parsed.get("y").and_then(|v| v.as_i64()).unwrap_or(0) as i32,
        parsed.get("width").and_then(|v| v.as_u64()).unwrap_or(1280) as u32,
        parsed.get("height").and_then(|v| v.as_u64()).unwrap_or(840) as u32,
    )))
}

/// Marks a specific (media_id, episode) pair as notified.
pub fn mark_airing_notified(app: &AppHandle, media_id: i64, episode: i64) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "UPDATE airing_cache SET notified = 1 WHERE media_id = ?1 AND episode = ?2",
        (media_id, episode),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

// ─── Notification settings ────────────────────────────────────────────────────

pub fn get_notification_settings(app: &AppHandle) -> Result<NotificationSettings, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    // Ensure a default row exists.
    conn.execute(
        "INSERT OR IGNORE INTO notification_settings
         (id, airing_enabled, activity_enabled, forum_enabled, follows_enabled, media_enabled, submissions_enabled, manga_releases_enabled)
         VALUES (1, 1, 1, 1, 1, 1, 1, 0)",
        [],
    )
    .map_err(|e| e.to_string())?;

    conn.query_row(
        "SELECT airing_enabled, activity_enabled, forum_enabled, follows_enabled, media_enabled, submissions_enabled, manga_releases_enabled
         FROM notification_settings WHERE id = 1",
        [],
        |row| {
            Ok(NotificationSettings {
                airing_enabled:   row.get::<_, i64>(0)? != 0,
                activity_enabled: row.get::<_, i64>(1)? != 0,
                forum_enabled:    row.get::<_, i64>(2)? != 0,
                follows_enabled:  row.get::<_, i64>(3)? != 0,
                media_enabled:    row.get::<_, i64>(4)? != 0,
                submissions_enabled: row.get::<_, i64>(5)? != 0,
                manga_releases_enabled: row.get::<_, i64>(6)? != 0,
            })
        },
    )
    .map_err(|e| e.to_string())
}

pub fn save_notification_settings(
    app: &AppHandle,
    settings: &NotificationSettings,
) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "INSERT INTO notification_settings
                 (id, airing_enabled, activity_enabled, forum_enabled, follows_enabled, media_enabled, submissions_enabled, manga_releases_enabled, updated_at)
                 VALUES (1, ?1, ?2, ?3, ?4, ?5, ?6, ?7, CURRENT_TIMESTAMP)
         ON CONFLICT(id) DO UPDATE SET
           airing_enabled   = excluded.airing_enabled,
           activity_enabled = excluded.activity_enabled,
           forum_enabled    = excluded.forum_enabled,
           follows_enabled  = excluded.follows_enabled,
           media_enabled    = excluded.media_enabled,
                     submissions_enabled = excluded.submissions_enabled,
                     manga_releases_enabled = excluded.manga_releases_enabled,
           updated_at       = CURRENT_TIMESTAMP",
        (
            settings.airing_enabled   as i64,
            settings.activity_enabled as i64,
            settings.forum_enabled    as i64,
            settings.follows_enabled  as i64,
            settings.media_enabled    as i64,
                        settings.submissions_enabled as i64,
                        settings.manga_releases_enabled as i64,
        ),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn get_notification_overrides(
    app: &AppHandle,
    media_ids: &[i64],
) -> Result<Vec<NotificationOverride>, String> {
    if media_ids.is_empty() {
        return Ok(Vec::new());
    }

    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let mut sql = String::from(
        "SELECT media_id, enabled, discord_hidden FROM notification_overrides WHERE media_id IN (",
    );
    for index in 0..media_ids.len() {
        if index > 0 {
            sql.push(',');
        }
        sql.push('?');
        sql.push_str(&(index + 1).to_string());
    }
    sql.push(')');

    let mut stmt = conn.prepare(&sql).map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map(
            rusqlite::params_from_iter(media_ids.iter().copied()),
            |row| {
                Ok(NotificationOverride {
                    media_id: row.get(0)?,
                    enabled: row.get::<_, i64>(1)? != 0,
                    discord_hidden: row.get::<_, i64>(2)? != 0,
                })
            },
        )
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(rows)
}

/// Sets the per-media Discord Rich Presence privacy flag (`discord_hidden`)
/// on `notification_overrides`.  Independent of the notification `enabled`
/// flag — a title can still produce notifications while staying out of the
/// user's Discord status.
pub fn set_discord_hidden(app: &AppHandle, media_id: i64, hidden: bool) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "INSERT INTO notification_overrides (media_id, enabled, discord_hidden, updated_at)
         VALUES (?1, 1, ?2, CURRENT_TIMESTAMP)
         ON CONFLICT(media_id) DO UPDATE SET
           discord_hidden = excluded.discord_hidden,
           updated_at = CURRENT_TIMESTAMP",
        (media_id, if hidden { 1 } else { 0 }),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// True when the user hid this media from the Discord Rich Presence.
pub fn is_discord_hidden(app: &AppHandle, media_id: i64) -> Result<bool, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let hidden: Option<i64> = conn
        .query_row(
            "SELECT discord_hidden FROM notification_overrides WHERE media_id = ?1",
            [media_id],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    Ok(hidden == Some(1))
}

// ─── Favourite OP/ED themes ──────────────────────────────────────────────────

/// All themes the user starred for a media entry, newest first.
pub fn get_favorite_themes(app: &AppHandle, media_id: i64) -> Result<Vec<FavoriteTheme>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT media_id, theme_id, theme_type, song_title, artists, added_at
             FROM favorite_themes
             WHERE media_id = ?1
             ORDER BY added_at DESC",
        )
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([media_id], |row| {
            let artists_json: String = row.get(4)?;
            Ok(FavoriteTheme {
                media_id: row.get(0)?,
                theme_id: row.get(1)?,
                theme_type: row.get(2)?,
                song_title: row.get(3)?,
                artists: serde_json::from_str(&artists_json).unwrap_or_default(),
                added_at: row.get(5)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(rows)
}

/// Adds or removes a theme to/from the media's favourite list.  Returns the
/// new state (`true` = now favourited).
pub fn toggle_favorite_theme(
    app: &AppHandle,
    media_id: i64,
    theme_id: i64,
    theme_type: &str,
    song_title: &str,
    artists: &[String],
) -> Result<bool, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let exists: bool = conn
        .query_row(
            "SELECT EXISTS(SELECT 1 FROM favorite_themes WHERE media_id = ?1 AND theme_id = ?2)",
            (media_id, theme_id),
            |r| r.get::<_, i64>(0),
        )
        .map(|v| v != 0)
        .map_err(|e| e.to_string())?;

    if exists {
        conn.execute(
            "DELETE FROM favorite_themes WHERE media_id = ?1 AND theme_id = ?2",
            (media_id, theme_id),
        )
        .map_err(|e| e.to_string())?;
        Ok(false)
    } else {
        let artists_json = serde_json::to_string(artists).unwrap_or_else(|_| "[]".to_string());
        conn.execute(
            "INSERT INTO favorite_themes (media_id, theme_id, theme_type, song_title, artists, added_at)
             VALUES (?1, ?2, ?3, ?4, ?5, CURRENT_TIMESTAMP)
             ON CONFLICT(media_id, theme_id) DO UPDATE SET
               theme_type = excluded.theme_type,
               song_title = excluded.song_title,
               artists = excluded.artists,
               added_at = CURRENT_TIMESTAMP",
            (media_id, theme_id, theme_type, song_title, artists_json),
        )
        .map_err(|e| e.to_string())?;
        Ok(true)
    }
}

pub fn set_notification_override(
    app: &AppHandle,
    media_id: i64,
    enabled: bool,
) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "INSERT INTO notification_overrides (media_id, enabled, updated_at)
         VALUES (?1, ?2, CURRENT_TIMESTAMP)
         ON CONFLICT(media_id) DO UPDATE SET
           enabled = excluded.enabled,
           updated_at = CURRENT_TIMESTAMP",
        (media_id, if enabled { 1 } else { 0 }),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

// ─── MangaUpdates release tracking ───────────────────────────────────────────

/// Returns manga/novel list entries that are candidates for chapter-release
/// tracking: `CURRENT`/`REPEATING` status, any `MANGA`/`NOVEL` list kind.
/// Tuple: `(media_id, media_type, title, cover_image)`.
#[allow(clippy::type_complexity)]
pub fn get_tracked_manga(
    app: &AppHandle,
) -> Result<Vec<(i64, String, String, Option<String>)>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT e.media_id, UPPER(e.media_type),
                    COALESCE(c.title_english, c.title_romaji, CAST(e.media_id AS TEXT)),
                    c.cover_image
             FROM media_list_entries e
             LEFT JOIN media_cache c ON c.media_id = e.media_id
             WHERE UPPER(e.media_type) IN ('MANGA','NOVEL')
               AND LOWER(e.status) IN ('current','repeating')
             ORDER BY e.updated_at DESC",
        )
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| {
            Ok((
                row.get::<_, i64>(0)?,
                row.get::<_, String>(1)?,
                row.get::<_, String>(2)?,
                row.get::<_, Option<String>>(3)?,
            ))
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(rows)
}

/// Reads all MangaUpdates links from `manga_release_cache`, joined with the
/// media title, for the Settings UI.
pub fn get_manga_release_mappings(app: &AppHandle) -> Result<Vec<MangaReleaseMapping>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let mut stmt = conn
        .prepare(
            "SELECT r.media_id, r.media_type,
                    COALESCE(c.title_english, c.title_romaji, CAST(r.media_id AS TEXT)),
                    r.mu_series_id, r.mu_title, r.last_item_title, r.manual
             FROM manga_release_cache r
             LEFT JOIN media_cache c ON c.media_id = r.media_id
             ORDER BY r.updated_at DESC",
        )
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| {
            Ok(MangaReleaseMapping {
                media_id: row.get(0)?,
                media_type: row.get(1)?,
                title: row.get(2)?,
                mu_series_id: row.get(3)?,
                mu_title: row.get(4)?,
                last_item_title: row.get(5)?,
                manual: row.get::<_, i64>(6)? != 0,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;
    Ok(rows)
}

/// Reads a single MangaUpdates mapping for a media id, if present.
pub fn get_manga_release_mapping(
    app: &AppHandle,
    media_id: i64,
) -> Result<Option<MangaReleaseMapping>, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let row = conn
        .query_row(
            "SELECT r.media_id, r.media_type,
                    COALESCE(c.title_english, c.title_romaji, CAST(r.media_id AS TEXT)),
                    r.mu_series_id, r.mu_title, r.last_item_title, r.manual
             FROM manga_release_cache r
             LEFT JOIN media_cache c ON c.media_id = r.media_id
             WHERE r.media_id = ?1",
            [media_id],
            |row| {
                Ok(MangaReleaseMapping {
                    media_id: row.get(0)?,
                    media_type: row.get(1)?,
                    title: row.get(2)?,
                    mu_series_id: row.get(3)?,
                    mu_title: row.get(4)?,
                    last_item_title: row.get(5)?,
                    manual: row.get::<_, i64>(6)? != 0,
                })
            },
        )
        .optional()
        .map_err(|e| e.to_string())?;
    Ok(row)
}

/// Upserts the MangaUpdates link for a media entry.  `manual = true` marks a
/// user-picked link (auto-resolution skips it afterwards).
#[allow(clippy::too_many_arguments)]
pub fn set_manga_release_mapping(
    app: &AppHandle,
    media_id: i64,
    media_type: &str,
    mu_series_id: i64,
    mu_title: &str,
    manual: bool,
) -> Result<(), String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "INSERT INTO manga_release_cache (media_id, media_type, mu_series_id, mu_title, manual, updated_at)
         VALUES (?1, ?2, ?3, ?4, ?5, CURRENT_TIMESTAMP)
         ON CONFLICT(media_id) DO UPDATE SET
           media_type = excluded.media_type,
           mu_series_id = excluded.mu_series_id,
           mu_title = excluded.mu_title,
           manual = excluded.manual,
           updated_at = CURRENT_TIMESTAMP",
        (media_id, media_type, mu_series_id, mu_title, if manual { 1 } else { 0 }),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Removes the MangaUpdates link for a media entry (stops tracking it).
pub fn clear_manga_release_mapping(app: &AppHandle, media_id: i64) -> Result<(), String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "DELETE FROM manga_release_cache WHERE media_id = ?1",
        [media_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Advances the high-water mark (last notified RSS item title) for a media id.
pub fn update_manga_release_mark(
    app: &AppHandle,
    media_id: i64,
    last_item_title: &str,
) -> Result<(), String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "UPDATE manga_release_cache SET last_item_title = ?1, updated_at = CURRENT_TIMESTAMP
         WHERE media_id = ?2",
        (last_item_title, media_id),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// True when the user has muted notifications for this media id via
/// `notification_overrides` (`enabled = 0`).
///
/// NOTE: `enabled` is the *shared* per-media notification mute — the same
/// flag the airing schedule toggle writes (see `get_unnotified_aired`), and
/// the same one `EntryEditModal`'s "Notify about new chapters" switch reads.
/// It is not manga-release-specific; manga/novel entries simply never appear
/// in `airing_cache`, so the two consumers never collide.
pub fn is_manga_release_muted(app: &AppHandle, media_id: i64) -> Result<bool, String> {
    initialize_database(app)?;
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let enabled: Option<i64> = conn
        .query_row(
            "SELECT enabled FROM notification_overrides WHERE media_id = ?1",
            [media_id],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    Ok(enabled == Some(0))
}

/// Increment (or decrement when `delta` is negative) the episode progress for
/// an anime entry identified by `media_id`.  Clamps to 0 and the known total
/// episode count.  Sets `is_dirty = 1` so the change is picked up by the next
/// sync / auto-sync cycle.  Returns the new progress value.
pub fn increment_anime_progress(app: &AppHandle, media_id: i64, delta: i64) -> Result<i64, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    // Read current progress and optional episode ceiling.
    let (current_progress, total_episodes): (i64, Option<i64>) = conn
        .query_row(
            "SELECT e.progress,
                    CAST(json_extract(c.payload_json, '$.episodes') AS INTEGER)
             FROM media_list_entries e
             LEFT JOIN media_cache c ON c.media_id = e.media_id
             WHERE e.media_id = ?1 AND UPPER(e.media_type) = 'ANIME'
             ORDER BY e.id DESC LIMIT 1",
            [media_id],
            |row| Ok((row.get::<_, i64>(0)?, row.get::<_, Option<i64>>(1)?)),
        )
        .map_err(|e| e.to_string())?;

    let new_progress = {
        let raw = current_progress + delta;
        let floored = raw.max(0);
        match total_episodes {
            Some(max) if max > 0 => floored.min(max),
            _ => floored,
        }
    };

    if new_progress == current_progress {
        return Ok(current_progress); // already at boundary
    }

    conn.execute(
        "UPDATE media_list_entries
         SET progress = ?1, is_dirty = 1, updated_at = CURRENT_TIMESTAMP
         WHERE media_id = ?2 AND UPPER(media_type) = 'ANIME'",
        (new_progress, media_id),
    )
    .map_err(|e| e.to_string())?;

    // Log the progress update to the activity log.
    let _ = log_activity_conn(
        &conn,
        media_id,
        "ANIME",
        "progress_update",
        Some(&current_progress.to_string()),
        Some(&new_progress.to_string()),
        None,
    );

    Ok(new_progress)
}

// ─── Activity logging ────────────────────────────────────────────────────────

/// Internal helper — writes one row to `activity_log` using an open
/// connection.  Errors are intentionally swallowed by callers so that a
/// logging failure never blocks the primary operation.
fn log_activity_conn(
    conn: &Connection,
    media_id: i64,
    media_type: &str,
    activity_type: &str,
    old_value: Option<&str>,
    new_value: Option<&str>,
    note: Option<&str>,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO activity_log(media_id, media_type, activity_type, old_value, new_value, note)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        (
            media_id,
            media_type,
            activity_type,
            old_value,
            new_value,
            note,
        ),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

// ─── Statistics ───────────────────────────────────────────────────────────────

/// Compute derived statistics from the local library.  Pure SQL / JSON
/// extraction — no AniList requests.
pub fn get_library_stats(app: &AppHandle) -> Result<LibraryStats, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    // ── total counts per list kind ───────────────────────────────────────────
    let total_entries: i64 = conn
        .query_row("SELECT COUNT(*) FROM media_list_entries", [], |r| r.get(0))
        .map_err(|e| e.to_string())?;

    let total_anime: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM media_list_entries WHERE UPPER(list_kind) = 'ANIME'",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    let total_manga: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM media_list_entries WHERE UPPER(list_kind) = 'MANGA'",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    let total_novels: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM media_list_entries WHERE UPPER(list_kind) = 'NOVEL'",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    // ── status breakdown ─────────────────────────────────────────────────────
    let status_count = |s: &str| -> Result<i64, String> {
        conn.query_row(
            "SELECT COUNT(*) FROM media_list_entries WHERE UPPER(status) = ?1",
            [s],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())
    };
    let count_current = status_count("CURRENT")?;
    let count_completed = status_count("COMPLETED")?;
    let count_planning = status_count("PLANNING")?;
    let count_dropped = status_count("DROPPED")?;
    let count_paused = status_count("PAUSED")?;
    let count_repeating = status_count("REPEATING")?;

    // ── progress totals ──────────────────────────────────────────────────────
    let episodes_watched: i64 = conn
        .query_row(
            "SELECT COALESCE(SUM(progress), 0) FROM media_list_entries WHERE UPPER(list_kind) = 'ANIME'",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    let chapters_read: i64 = conn
        .query_row(
            "SELECT COALESCE(SUM(progress), 0) FROM media_list_entries WHERE UPPER(list_kind) IN ('MANGA', 'NOVEL')",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    let volumes_read: i64 = conn
        .query_row(
            "SELECT COALESCE(SUM(progress_volumes), 0) FROM media_list_entries WHERE UPPER(list_kind) IN ('MANGA', 'NOVEL')",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    // Estimated total watch time: progress × per-episode duration (minutes).
    let estimated_minutes: i64 = conn
        .query_row(
            "SELECT COALESCE(
               SUM(
                 mle.progress *
                 CAST(COALESCE(json_extract(mc.payload_json, '$.duration'), 0) AS INTEGER)
               ), 0)
             FROM media_list_entries mle
             LEFT JOIN media_cache mc ON mc.media_id = mle.media_id
             WHERE UPPER(mle.list_kind) = 'ANIME'",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    // ── mean score ───────────────────────────────────────────────────────────
    let mean_score: Option<f64> = conn
        .query_row(
            "SELECT AVG(score) FROM media_list_entries WHERE score IS NOT NULL AND score > 0",
            [],
            |r| r.get(0),
        )
        .map_err(|e| e.to_string())?;

    // ── score distribution (1-10) ────────────────────────────────────────────
    let mut score_distribution: Vec<ScoreBucket> = (1i64..=10)
        .map(|s| ScoreBucket { score: s, count: 0 })
        .collect();
    {
        let mut stmt = conn
            .prepare(
                "SELECT CAST(ROUND(score) AS INTEGER) as s, COUNT(*) as c
                 FROM media_list_entries
                 WHERE score IS NOT NULL AND score > 0
                 GROUP BY s
                 ORDER BY s",
            )
            .map_err(|e| e.to_string())?;
        let rows = stmt
            .query_map([], |r| Ok((r.get::<_, i64>(0)?, r.get::<_, i64>(1)?)))
            .map_err(|e| e.to_string())?;
        for row in rows.flatten() {
            let (s, c) = row;
            if (1..=10).contains(&s) {
                score_distribution[(s - 1) as usize].count = c;
            }
        }
    }

    // ── format breakdown ─────────────────────────────────────────────────────
    let format_breakdown = {
        let mut stmt = conn
            .prepare(
                "SELECT COALESCE(json_extract(mc.payload_json, '$.format'), 'UNKNOWN') as fmt,
                        COUNT(*) as c
                 FROM media_list_entries mle
                 LEFT JOIN media_cache mc ON mc.media_id = mle.media_id
                 WHERE UPPER(mle.status) != 'PLANNING'
                 GROUP BY fmt
                 ORDER BY c DESC",
            )
            .map_err(|e| e.to_string())?;
        let raw: Vec<(String, i64)> = stmt
            .query_map([], |r| Ok((r.get::<_, String>(0)?, r.get::<_, i64>(1)?)))
            .map_err(|e| e.to_string())?
            .flatten()
            .collect();
        raw.into_iter()
            .map(|(label, count)| BreakdownItem { label, count })
            .collect()
    };

    // ── genre breakdown (via json_each) ──────────────────────────────────────
    let genre_breakdown = {
        let mut stmt = conn
            .prepare(
                "SELECT je.value as genre, COUNT(*) as c
                 FROM media_list_entries mle
                 JOIN media_cache mc ON mc.media_id = mle.media_id
                 JOIN json_each(json_extract(mc.payload_json, '$.genres')) je
                 WHERE UPPER(mle.status) != 'PLANNING'
                 GROUP BY genre
                 ORDER BY c DESC
                 LIMIT 15",
            )
            .map_err(|e| e.to_string())?;
        let raw: Vec<(String, i64)> = stmt
            .query_map([], |r| Ok((r.get::<_, String>(0)?, r.get::<_, i64>(1)?)))
            .map_err(|e| e.to_string())?
            .flatten()
            .collect();
        raw.into_iter()
            .map(|(label, count)| BreakdownItem { label, count })
            .collect()
    };

    Ok(LibraryStats {
        total_entries,
        total_anime,
        total_manga,
        total_novels,
        count_current,
        count_completed,
        count_planning,
        count_dropped,
        count_paused,
        count_repeating,
        episodes_watched,
        chapters_read,
        volumes_read,
        estimated_minutes,
        mean_score,
        score_distribution,
        format_breakdown,
        genre_breakdown,
    })
}

/// Returns the `limit` most-recent activity log rows, joined with media title
/// and cover image from `media_cache`.
pub fn get_activity_log(app: &AppHandle, limit: i64) -> Result<Vec<ActivityEntry>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT al.id, al.media_id, al.media_type,
                    COALESCE(mc.title_english, mc.title_romaji, 'Unknown') AS title,
                    mc.cover_image,
                    al.activity_type, al.old_value, al.new_value, al.note, al.created_at
             FROM activity_log al
             LEFT JOIN media_cache mc ON mc.media_id = al.media_id
             ORDER BY al.created_at DESC, al.id DESC
             LIMIT ?1",
        )
        .map_err(|e| e.to_string())?;

    let entries = stmt
        .query_map([limit], |r| {
            Ok(ActivityEntry {
                id: r.get(0)?,
                media_id: r.get(1)?,
                media_type: r.get(2)?,
                title: r.get(3)?,
                cover_image: r.get(4)?,
                activity_type: r.get(5)?,
                old_value: r.get(6)?,
                new_value: r.get(7)?,
                note: r.get(8)?,
                created_at: r.get(9)?,
            })
        })
        .map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

    Ok(entries)
}

/// Returns per-day activity counts for a selected year (`YYYY`).
pub fn get_activity_heatmap(app: &AppHandle, year: Option<i32>) -> Result<Vec<HeatmapDay>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let selected_year = year.unwrap_or_else(|| {
        conn.query_row("SELECT CAST(strftime('%Y', 'now') AS INTEGER)", [], |r| {
            r.get::<_, i32>(0)
        })
        .unwrap_or(1970)
    });
    let start = format!("{selected_year:04}-01-01");
    let end = format!("{selected_year:04}-12-31");

    let mut stmt = conn
        .prepare(
                        "SELECT
                                COALESCE(
                                    CASE
                                        WHEN mle.ani_list_updated_at IS NOT NULL
                                                 AND mle.ani_list_updated_at GLOB '[0-9]*'
                                        THEN DATE(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                    END,
                                    DATE(mle.updated_at)
                                ) AS day,
                                COUNT(*) AS c
                         FROM media_list_entries mle
                         WHERE day BETWEEN DATE(?1) AND DATE(?2)
             GROUP BY day
             ORDER BY day ASC",
        )
        .map_err(|e| e.to_string())?;

    let days = stmt
        .query_map([start, end], |r| {
            Ok(HeatmapDay {
                date: r.get(0)?,
                count: r.get(1)?,
            })
        })
        .map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

    Ok(days)
}

/// Returns list-entry update rows for a specific date (`YYYY-MM-DD`).
pub fn get_activity_log_by_date(
    app: &AppHandle,
    date: &str,
    limit: i64,
) -> Result<Vec<ActivityEntry>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
                        "SELECT
                                mle.id,
                                mle.media_id,
                                mle.media_type,
                                COALESCE(mc.title_english, mc.title_romaji, 'Unknown') AS title,
                                mc.cover_image,
                                'list_update' AS activity_type,
                                NULL AS old_value,
                                NULL AS new_value,
                                ('Status: ' || UPPER(COALESCE(mle.status, '?')) ||
                                 ', Progress: ' || COALESCE(CAST(mle.progress AS TEXT), '0') ||
                                 CASE
                                     WHEN UPPER(COALESCE(mle.media_type, '')) IN ('MANGA', 'NOVEL')
                                     THEN (', Volumes: ' || COALESCE(CAST(mle.progress_volumes AS TEXT), '0'))
                                     ELSE ''
                                 END
                                ) AS note,
                                COALESCE(
                                    CASE
                                        WHEN mle.ani_list_updated_at IS NOT NULL
                                                 AND mle.ani_list_updated_at GLOB '[0-9]*'
                                        THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                    END,
                                    mle.updated_at
                                ) AS created_at
                         FROM media_list_entries mle
                         LEFT JOIN media_cache mc ON mc.media_id = mle.media_id
                         WHERE DATE(COALESCE(
                                        CASE
                                            WHEN mle.ani_list_updated_at IS NOT NULL
                                                     AND mle.ani_list_updated_at GLOB '[0-9]*'
                                            THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                        END,
                                        mle.updated_at
                                    )) = DATE(?1)
                         ORDER BY created_at DESC, mle.id DESC
             LIMIT ?2",
        )
        .map_err(|e| e.to_string())?;

    let entries = stmt
        .query_map(rusqlite::params![date, limit], |r| {
            Ok(ActivityEntry {
                id: r.get(0)?,
                media_id: r.get(1)?,
                media_type: r.get(2)?,
                title: r.get(3)?,
                cover_image: r.get(4)?,
                activity_type: r.get(5)?,
                old_value: r.get(6)?,
                new_value: r.get(7)?,
                note: r.get(8)?,
                created_at: r.get(9)?,
            })
        })
        .map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

    Ok(entries)
}

/// Returns per-month list-entry update counts by media type and update date.
pub fn get_activity_monthly_totals(
    app: &AppHandle,
    year: i32,
) -> Result<Vec<MonthlyActivityCount>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let start = format!("{year:04}-01-01");
    let end = format!("{year:04}-12-31");

    let mut stmt = conn
        .prepare(
                        "SELECT
                                CAST(strftime(
                                        '%m',
                                        COALESCE(
                                            CASE
                                                WHEN mle.ani_list_updated_at IS NOT NULL
                                                         AND mle.ani_list_updated_at GLOB '[0-9]*'
                                                THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                            END,
                                            mle.updated_at
                                        )
                                ) AS INTEGER) AS month,
                                    SUM(CASE WHEN UPPER(mle.media_type) = 'ANIME' THEN 1 ELSE 0 END) AS episodes,
                                    SUM(CASE WHEN UPPER(mle.media_type) IN ('MANGA', 'NOVEL') THEN 1 ELSE 0 END) AS chapters
                         FROM media_list_entries mle
                         WHERE DATE(COALESCE(
                                        CASE
                                            WHEN mle.ani_list_updated_at IS NOT NULL
                                                     AND mle.ani_list_updated_at GLOB '[0-9]*'
                                            THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                        END,
                                        mle.updated_at
                                    )) BETWEEN DATE(?1) AND DATE(?2)
             GROUP BY month
             ORDER BY month ASC",
        )
        .map_err(|e| e.to_string())?;

    let rows: Vec<MonthlyActivityCount> = stmt
        .query_map([start, end], |r| {
            Ok(MonthlyActivityCount {
                month: r.get(0)?,
                episodes: r.get(1)?,
                chapters: r.get(2)?,
            })
        })
        .map_err(|e| e.to_string())?
        .filter_map(|r| r.ok())
        .collect();

    let mut full = (1..=12)
        .map(|m| MonthlyActivityCount {
            month: m,
            episodes: 0,
            chapters: 0,
        })
        .collect::<Vec<_>>();

    for row in rows {
        if (1..=12).contains(&row.month) {
            let month_index = (row.month - 1) as usize;
            full[month_index] = row;
        }
    }

    Ok(full)
}

/// Returns annual wrap-up aggregates for the selected year.
pub fn get_annual_wrap_up(
    app: &AppHandle,
    year: i32,
) -> Result<crate::models::AnnualWrapUp, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let start = format!("{year:04}-01-01");
    let end = format!("{year:04}-12-31");

    let (days_active, list_updates): (i64, i64) = conn
        .query_row(
            "SELECT COALESCE(COUNT(DISTINCT DATE(created_at)), 0), COALESCE(COUNT(*), 0)
                         FROM activity_log
                         WHERE DATE(created_at) BETWEEN DATE(?1) AND DATE(?2)",
            rusqlite::params![start, end],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )
        .map_err(|e| e.to_string())?;

    let (completed_anime, episodes_watched, chapters_read, mean_score): (i64, i64, i64, Option<f64>) = conn
                .query_row(
                        "WITH base AS (
                                SELECT
                                    UPPER(mle.media_type) AS media_type,
                                    UPPER(mle.status) AS status,
                                    mle.score AS score,
                                    mle.progress AS progress,
                                    COALESCE(
                                        CASE
                                            WHEN mle.ani_list_updated_at IS NOT NULL
                                                     AND mle.ani_list_updated_at GLOB '[0-9]*'
                                            THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                        END,
                                        mle.updated_at
                                    ) AS touched_at,
                                    mle.completed_at AS completed_at
                                FROM media_list_entries mle
                         )
                         SELECT
                             COALESCE(SUM(
                                 CASE
                                     WHEN media_type = 'ANIME'
                                                AND status = 'COMPLETED'
                                                AND DATE(COALESCE(NULLIF(completed_at, ''), touched_at)) BETWEEN DATE(?1) AND DATE(?2)
                                     THEN 1 ELSE 0
                                 END
                             ), 0) AS completed_anime,
                             COALESCE(SUM(CASE WHEN media_type = 'ANIME' AND DATE(touched_at) BETWEEN DATE(?1) AND DATE(?2) THEN progress ELSE 0 END), 0) AS episodes_watched,
                             COALESCE(SUM(CASE WHEN media_type IN ('MANGA', 'NOVEL') AND DATE(touched_at) BETWEEN DATE(?1) AND DATE(?2) THEN progress ELSE 0 END), 0) AS chapters_read,
                             AVG(CASE WHEN score IS NOT NULL AND score > 0 AND DATE(touched_at) BETWEEN DATE(?1) AND DATE(?2) THEN score END) AS mean_score
                         FROM base",
                        rusqlite::params![start, end],
                        |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
                )
                .map_err(|e| e.to_string())?;

    let top_genres = {
        let mut stmt = conn
                        .prepare(
                                "WITH base AS (
                                        SELECT
                                            mle.media_id AS media_id,
                                            COALESCE(
                                                CASE
                                                    WHEN mle.ani_list_updated_at IS NOT NULL
                                                             AND mle.ani_list_updated_at GLOB '[0-9]*'
                                                    THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                                END,
                                                mle.updated_at
                                            ) AS touched_at
                                        FROM media_list_entries mle
                                 )
                                 SELECT je.value AS genre, COUNT(*) AS c
                                 FROM base b
                                 JOIN media_cache mc ON mc.media_id = b.media_id
                                 JOIN json_each(json_extract(mc.payload_json, '$.genres')) je
                                 WHERE DATE(b.touched_at) BETWEEN DATE(?1) AND DATE(?2)
                                 GROUP BY genre
                                 ORDER BY c DESC
                                 LIMIT 3",
                        )
                        .map_err(|e| e.to_string())?;

        let raw: Vec<(String, i64)> = stmt
            .query_map(rusqlite::params![start, end], |r| {
                Ok((r.get::<_, String>(0)?, r.get::<_, i64>(1)?))
            })
            .map_err(|e| e.to_string())?
            .flatten()
            .collect();

        raw.into_iter()
            .map(|(label, count)| crate::models::BreakdownItem { label, count })
            .collect::<Vec<_>>()
    };

    let top_studio: Option<String> = conn
                .query_row(
                        "WITH base AS (
                                SELECT
                                    mle.media_id AS media_id,
                                    COALESCE(
                                        CASE
                                            WHEN mle.ani_list_updated_at IS NOT NULL
                                                     AND mle.ani_list_updated_at GLOB '[0-9]*'
                                            THEN DATETIME(CAST(mle.ani_list_updated_at AS INTEGER), 'unixepoch')
                                        END,
                                        mle.updated_at
                                    ) AS touched_at
                                FROM media_list_entries mle
                         )
                         SELECT json_extract(js.value, '$.name') AS studio_name
                         FROM base b
                         JOIN media_cache mc ON mc.media_id = b.media_id
                         JOIN json_each(json_extract(mc.payload_json, '$.studios')) js
                         WHERE DATE(b.touched_at) BETWEEN DATE(?1) AND DATE(?2)
                             AND studio_name IS NOT NULL
                             AND studio_name != ''
                         GROUP BY studio_name
                         ORDER BY COUNT(*) DESC
                         LIMIT 1",
                        rusqlite::params![start, end],
                        |r| r.get(0),
                )
                .optional()
                .map_err(|e| e.to_string())?
                .flatten();

    let weekday_code: Option<String> = conn
        .query_row(
            "SELECT strftime('%w', created_at) AS weekday
                         FROM activity_log
                         WHERE DATE(created_at) BETWEEN DATE(?1) AND DATE(?2)
                         GROUP BY weekday
                         ORDER BY COUNT(*) DESC
                         LIMIT 1",
            rusqlite::params![start, end],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?
        .flatten();

    let most_watched_weekday = weekday_code.and_then(|w| {
        Some(match w.as_str() {
            "0" => "Sunday".to_string(),
            "1" => "Monday".to_string(),
            "2" => "Tuesday".to_string(),
            "3" => "Wednesday".to_string(),
            "4" => "Thursday".to_string(),
            "5" => "Friday".to_string(),
            "6" => "Saturday".to_string(),
            _ => return None,
        })
    });

    let first_completed_title: Option<String> = conn
                .query_row(
                        "SELECT COALESCE(mc.title_english, mc.title_romaji, 'Unknown')
                         FROM media_list_entries mle
                         LEFT JOIN media_cache mc ON mc.media_id = mle.media_id
                         WHERE UPPER(mle.media_type) = 'ANIME'
                             AND UPPER(mle.status) = 'COMPLETED'
                             AND DATE(COALESCE(NULLIF(mle.completed_at, ''), mle.updated_at)) BETWEEN DATE(?1) AND DATE(?2)
                         ORDER BY DATE(COALESCE(NULLIF(mle.completed_at, ''), mle.updated_at)) ASC, mle.id ASC
                         LIMIT 1",
                        rusqlite::params![start, end],
                        |r| r.get(0),
                )
                .optional()
                .map_err(|e| e.to_string())?
                .flatten();

    let last_completed_title: Option<String> = conn
                .query_row(
                        "SELECT COALESCE(mc.title_english, mc.title_romaji, 'Unknown')
                         FROM media_list_entries mle
                         LEFT JOIN media_cache mc ON mc.media_id = mle.media_id
                         WHERE UPPER(mle.media_type) = 'ANIME'
                             AND UPPER(mle.status) = 'COMPLETED'
                             AND DATE(COALESCE(NULLIF(mle.completed_at, ''), mle.updated_at)) BETWEEN DATE(?1) AND DATE(?2)
                         ORDER BY DATE(COALESCE(NULLIF(mle.completed_at, ''), mle.updated_at)) DESC, mle.id DESC
                         LIMIT 1",
                        rusqlite::params![start, end],
                        |r| r.get(0),
                )
                .optional()
                .map_err(|e| e.to_string())?
                .flatten();

    Ok(crate::models::AnnualWrapUp {
        year: year as i64,
        days_active,
        list_updates,
        completed_anime,
        episodes_watched,
        chapters_read,
        mean_score,
        top_genres,
        top_studio,
        most_watched_weekday,
        first_completed_title,
        last_completed_title,
    })
}

// ─── App settings ─────────────────────────────────────────────────────────────

pub fn get_app_settings(app: &AppHandle) -> Result<AppSettings, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut settings = AppSettings::default();

    let mut stmt = conn
        .prepare("SELECT key, value FROM app_settings")
        .map_err(|e| e.to_string())?;
    let rows: Vec<(String, String)> = stmt
        .query_map([], |r| Ok((r.get(0)?, r.get(1)?)))
        .map_err(|e| e.to_string())?
        .flatten()
        .collect();

    for (key, value) in rows {
        match key.as_str() {
            "show_adult_content" => settings.show_adult_content = value == "1",
            "default_list_tab" => settings.default_list_tab = value,
            "default_sort" => settings.default_sort = value,
            "library_view" => settings.library_view = value,
            "schedule_view" => settings.schedule_view = value,
            "hidden_statuses" => settings.hidden_statuses = value,
            "auto_sync_interval" => settings.auto_sync_interval = value.parse().unwrap_or(15),
            "last_synced_at" => settings.last_synced_at = Some(value),
            "score_format" => settings.score_format = value,
            "minimize_to_tray_on_close" => settings.minimize_to_tray_on_close = value == "1",
            "keyboard_shortcuts" => settings.keyboard_shortcuts = value,
            "always_on_top" => settings.always_on_top = value == "1",
            "discord_rpc_enabled" => settings.discord_rpc_enabled = value == "1",
            _ => {}
        }
    }

    Ok(settings)
}

pub fn save_app_settings(app: &AppHandle, settings: &AppSettings) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let interval_str = settings.auto_sync_interval.to_string();
    let mut pairs: Vec<(&str, &str)> = vec![
        (
            "show_adult_content",
            if settings.show_adult_content {
                "1"
            } else {
                "0"
            },
        ),
        ("default_list_tab", settings.default_list_tab.as_str()),
        ("default_sort", settings.default_sort.as_str()),
        ("library_view", settings.library_view.as_str()),
        ("schedule_view", settings.schedule_view.as_str()),
        ("hidden_statuses", settings.hidden_statuses.as_str()),
        ("auto_sync_interval", interval_str.as_str()),
        ("score_format", settings.score_format.as_str()),
        (
            "minimize_to_tray_on_close",
            if settings.minimize_to_tray_on_close {
                "1"
            } else {
                "0"
            },
        ),
        ("keyboard_shortcuts", settings.keyboard_shortcuts.as_str()),
        (
            "always_on_top",
            if settings.always_on_top { "1" } else { "0" },
        ),
        (
            "discord_rpc_enabled",
            if settings.discord_rpc_enabled {
                "1"
            } else {
                "0"
            },
        ),
    ];
    // Only persist last_synced_at if set — we never erase it via settings save.
    let synced_str;
    if let Some(ref ts) = settings.last_synced_at {
        synced_str = ts.clone();
        pairs.push(("last_synced_at", synced_str.as_str()));
    }

    for (key, value) in &pairs {
        conn.execute(
            "INSERT INTO app_settings(key, value) VALUES(?1, ?2)
             ON CONFLICT(key) DO UPDATE SET value = excluded.value,
             updated_at = CURRENT_TIMESTAMP",
            (*key, *value),
        )
        .map_err(|e| e.to_string())?;
    }

    Ok(())
}

// ─── Sync helpers ─────────────────────────────────────────────────────────────

/// Returns the stored high-water mark for delta sync — the max `updatedAt`
/// Unix timestamp (seconds) seen in the previous full/delta pull from AniList.
/// Returns `None` if no sync has been performed yet (triggers a full sync).
pub fn get_sync_high_water(app: &AppHandle) -> Result<Option<i64>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let val: Option<String> = conn
        .query_row(
            "SELECT value FROM app_settings WHERE key = 'sync_high_water'",
            [],
            |r| r.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?
        .flatten();
    Ok(val.and_then(|v| v.parse::<i64>().ok()))
}

/// Persists `ts` as the new high-water mark in `app_settings`.
pub fn set_sync_high_water(app: &AppHandle, ts: i64) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let val = ts.to_string();
    conn.execute(
        "INSERT INTO app_settings(key, value) VALUES('sync_high_water', ?1)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP",
        [val.as_str()],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Persists the current UTC timestamp as `last_synced_at` in `app_settings`.
pub fn set_last_synced_at(app: &AppHandle) -> Result<String, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let ts: String = conn
        .query_row("SELECT CURRENT_TIMESTAMP", [], |r| r.get(0))
        .map_err(|e| e.to_string())?;
    conn.execute(
        "INSERT INTO app_settings(key, value) VALUES('last_synced_at', ?1)
         ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = CURRENT_TIMESTAMP",
        [ts.as_str()],
    )
    .map_err(|e| e.to_string())?;
    Ok(ts)
}

/// Appends a row to `sync_log`.  Call with an open connection that is already
/// inside a transaction to avoid per-row commit overhead.
pub fn log_sync_event(
    conn: &Connection,
    media_id: i64,
    sync_type: &str,
    detail: Option<&str>,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO sync_log(media_id, sync_type, detail) VALUES(?1, ?2, ?3)",
        (media_id, sync_type, detail),
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Trims `sync_log` down to the `keep` most recent rows so the table (and
/// its two indexes) cannot grow without bound.  A single full sync of a
/// 2.5k-entry library used to insert 2.5k `pulled` rows; pruning keeps the
/// log readable and INSERTs fast on subsequent runs.
pub fn prune_sync_log(app: &AppHandle, keep: i64) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute(
        "DELETE FROM sync_log WHERE id NOT IN (
             SELECT id FROM sync_log ORDER BY id DESC LIMIT ?1
         )",
        [keep],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Returns the most-recent `limit` sync log entries, joined with
/// `media_cache` to supply a human-readable title.
pub fn get_sync_log(app: &AppHandle, limit: i64) -> Result<Vec<SyncLogEntry>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT sl.id, sl.media_id,
                    COALESCE(mc.title_english, mc.title_romaji,
                             CASE WHEN sl.media_id = 0 THEN 'Sync summary' ELSE NULL END) AS title,
                    sl.sync_type, sl.detail, sl.created_at
             FROM sync_log sl
             LEFT JOIN media_cache mc ON mc.media_id = sl.media_id
             ORDER BY sl.created_at DESC
             LIMIT ?1",
        )
        .map_err(|e| e.to_string())?;

    let rows = stmt
        .query_map([limit], |row| {
            Ok(SyncLogEntry {
                id: row.get(0)?,
                media_id: row.get(1)?,
                media_title: row.get(2)?,
                sync_type: row.get(3)?,
                detail: row.get(4)?,
                created_at: row.get(5)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(rows)
}

// ─── Conflict resolution ──────────────────────────────────────────────────────

/// Save both sides of a conflict to `pending_conflicts` so the user can choose
/// which version to keep.  Uses `ON CONFLICT` to update if the entry was already
/// recorded from a previous sync run.
#[allow(clippy::too_many_arguments)]
pub fn store_pending_conflict(
    conn: &Connection,
    media_id: i64,
    media_type: &str,
    local_status: Option<&str>,
    local_score: Option<f64>,
    local_progress: i64,
    local_notes: Option<&str>,
    remote_status: &str,
    remote_score: Option<f64>,
    remote_progress: i64,
    remote_notes: Option<&str>,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO pending_conflicts (
           media_id, media_type,
           local_status, local_score, local_progress, local_notes,
           remote_status, remote_score, remote_progress, remote_notes
         ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)
         ON CONFLICT(media_id) DO UPDATE SET
           media_type      = excluded.media_type,
           local_status    = excluded.local_status,
           local_score     = excluded.local_score,
           local_progress  = excluded.local_progress,
           local_notes     = excluded.local_notes,
           remote_status   = excluded.remote_status,
           remote_score    = excluded.remote_score,
           remote_progress = excluded.remote_progress,
           remote_notes    = excluded.remote_notes,
           detected_at     = CURRENT_TIMESTAMP",
        rusqlite::params![
            media_id,
            media_type,
            local_status,
            local_score,
            local_progress,
            local_notes,
            remote_status,
            remote_score,
            remote_progress,
            remote_notes,
        ],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

/// Return all unresolved pending conflicts, joined with `media_cache` for titles.
pub fn get_pending_conflicts(app: &AppHandle) -> Result<Vec<PendingConflict>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut stmt = conn
        .prepare(
            "SELECT pc.media_id, pc.media_type,
                    COALESCE(mc.title_english, mc.title_romaji) AS title,
                    pc.local_status, pc.local_score, pc.local_progress, pc.local_notes,
                    pc.remote_status, pc.remote_score, pc.remote_progress, pc.remote_notes,
                    pc.detected_at
             FROM pending_conflicts pc
             LEFT JOIN media_cache mc ON mc.media_id = pc.media_id
             ORDER BY pc.detected_at DESC",
        )
        .map_err(|e| e.to_string())?;

    let rows = stmt
        .query_map([], |row| {
            Ok(PendingConflict {
                media_id: row.get(0)?,
                media_type: row.get(1)?,
                media_title: row.get(2)?,
                local_status: row.get(3)?,
                local_score: row.get(4)?,
                local_progress: row.get(5)?,
                local_notes: row.get(6)?,
                remote_status: row.get(7)?,
                remote_score: row.get(8)?,
                remote_progress: row.get(9)?,
                remote_notes: row.get(10)?,
                detected_at: row.get(11)?,
            })
        })
        .map_err(|e| e.to_string())?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|e| e.to_string())?;

    Ok(rows)
}

/// Apply the user's choice for a single conflict.
///
/// - `use_remote = true`  → copy the remote values into the local entry and
///   clear `is_dirty` (AniList is now the authority).
/// - `use_remote = false` → keep local values as-is; `is_dirty` stays `1` so
///   the entry is pushed to AniList on the next sync.
///
/// Either way the row is removed from `pending_conflicts`.
pub fn apply_conflict_resolution(
    app: &AppHandle,
    media_id: i64,
    use_remote: bool,
) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    if use_remote {
        #[allow(clippy::type_complexity)]
        let row: Option<(String, Option<String>, Option<f64>, i64, Option<String>)> = conn
            .query_row(
                "SELECT media_type, remote_status, remote_score,
                        remote_progress, remote_notes
                 FROM pending_conflicts WHERE media_id = ?1",
                [media_id],
                |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?, r.get(4)?)),
            )
            .optional()
            .map_err(|e| e.to_string())?;

        if let Some((media_type, status, score, progress, notes)) = row {
            conn.execute(
                "UPDATE media_list_entries
                 SET status    = COALESCE(?1, status),
                     score     = ?2,
                     progress  = ?3,
                     notes     = ?4,
                     is_dirty  = 0,
                     updated_at = CURRENT_TIMESTAMP
                 WHERE media_id = ?5
                   AND UPPER(media_type) = ?6
                   AND UPPER(list_kind)  = ?6",
                rusqlite::params![status, score, progress, notes, media_id, &media_type],
            )
            .map_err(|e| e.to_string())?;
        }
    }
    // Local wins path: local values already in place; is_dirty=1 will push them next sync.

    conn.execute(
        "DELETE FROM pending_conflicts WHERE media_id = ?1",
        [media_id],
    )
    .map_err(|e| e.to_string())?;

    Ok(())
}

// ─── Cache management ─────────────────────────────────────────────────────────

pub fn get_cache_stats(app: &AppHandle) -> Result<CacheStats, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let count = |sql: &str| -> Result<i64, String> {
        conn.query_row(sql, [], |r| r.get(0))
            .map_err(|e| e.to_string())
    };

    let media_cache_count = count("SELECT COUNT(*) FROM media_cache")?;
    let search_history_count = count("SELECT COUNT(*) FROM search_history")?;
    let airing_cache_count = count("SELECT COUNT(*) FROM airing_cache")?;
    let activity_log_count = count("SELECT COUNT(*) FROM activity_log")?;

    let (image_cache_count, image_cache_bytes) =
        crate::cache::image_cache_stats(app).unwrap_or((0, 0));

    Ok(CacheStats {
        media_cache_count,
        search_history_count,
        airing_cache_count,
        activity_log_count,
        image_cache_count,
        image_cache_bytes,
    })
}

pub fn clear_search_history(app: &AppHandle) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute("DELETE FROM search_history", [])
        .map_err(|e| e.to_string())?;
    Ok(())
}

/// Removes media_cache rows that are not referenced by any library entry.
pub fn clear_orphan_media_cache(app: &AppHandle) -> Result<i64, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let deleted = conn
        .execute(
            "DELETE FROM media_cache
             WHERE media_id NOT IN (SELECT media_id FROM media_list_entries)",
            [],
        )
        .map_err(|e| e.to_string())?;
    Ok(deleted as i64)
}

pub fn clear_airing_cache(app: &AppHandle) -> Result<(), String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    conn.execute("DELETE FROM airing_cache", [])
        .map_err(|e| e.to_string())?;
    Ok(())
}

// ─── Backup / export / import ─────────────────────────────────────────────────

/// Exports all library entries + app settings as JSON to
/// `{app_data_dir}/exports/library_{timestamp}.json`.
pub fn export_library_json(app: &AppHandle) -> Result<ExportResult, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    // Collect entries.
    let mut stmt = conn
        .prepare(
            "SELECT mle.media_id, mle.media_type, mle.list_kind, mle.status, mle.score,
                    mle.progress, mle.progress_volumes, mle.repeat_count, mle.notes,
                    mle.started_at, mle.completed_at, mle.updated_at,
                    mle.anilist_entry_id,
                    COALESCE(mc.title_english, mc.title_romaji, '') AS title,
                    COALESCE(mc.cover_image, '') AS cover_image
             FROM media_list_entries mle
             LEFT JOIN media_cache mc ON mc.media_id = mle.media_id
             ORDER BY mle.media_type, mle.updated_at DESC",
        )
        .map_err(|e| e.to_string())?;

    let entries: Vec<serde_json::Value> = stmt
        .query_map([], |r| {
            Ok(serde_json::json!({
                "mediaId":        r.get::<_, i64>(0)?,
                "mediaType":      r.get::<_, String>(1)?,
                "listKind":       r.get::<_, String>(2)?,
                "status":         r.get::<_, String>(3)?,
                "score":          r.get::<_, Option<f64>>(4)?,
                "progress":       r.get::<_, i64>(5)?,
                "progressVolumes":r.get::<_, i64>(6)?,
                "repeatCount":    r.get::<_, i64>(7)?,
                "notes":          r.get::<_, Option<String>>(8)?,
                "startedAt":      r.get::<_, Option<String>>(9)?,
                "completedAt":    r.get::<_, Option<String>>(10)?,
                "updatedAt":      r.get::<_, String>(11)?,
                "anilistEntryId": r.get::<_, Option<i64>>(12)?,
                "title":          r.get::<_, String>(13)?,
                "coverImage":     r.get::<_, String>(14)?,
            }))
        })
        .map_err(|e| e.to_string())?
        .flatten()
        .collect();

    let entry_count = entries.len() as i64;

    // Collect settings.
    let settings = get_app_settings(app)?;

    let payload = serde_json::json!({
        "version": 1,
        "exportedAt": chrono_now_iso(),
        "productName": "miyolist",
        "entryCount": entry_count,
        "settings": settings,
        "entries": entries,
    });

    // Write to exports dir.
    let export_dir = export_directory(app)?;
    let timestamp = chrono_now_file_safe();
    let filename = format!("library_{timestamp}.json");
    let file_path = export_dir.join(&filename);

    let json = serde_json::to_string_pretty(&payload).map_err(|e| e.to_string())?;
    std::fs::write(&file_path, json).map_err(|e| e.to_string())?;

    Ok(ExportResult {
        path: file_path.to_string_lossy().to_string(),
        entry_count,
    })
}

/// Creates a consistent snapshot of the live database in the exports
/// directory using `VACUUM INTO`.
///
/// A plain `std::fs::copy` of a WAL-mode database is unsafe: writes still
/// sitting in the `-wal` file are silently dropped from the backup, and
/// copying while another connection is mid-write can produce a torn file.
/// `VACUUM INTO` reads a consistent snapshot through SQLite itself.
pub fn export_database_backup(app: &AppHandle) -> Result<ExportResult, String> {
    let database_path = database_path(app)?;
    let export_dir = export_directory(app)?;
    let timestamp = chrono_now_file_safe();
    let filename = format!("miyolist_{timestamp}.sqlite3");
    let dest = export_dir.join(&filename);

    // VACUUM INTO fails if the destination file already exists; make the
    // name unique when two exports land in the same second.
    let mut dest = dest;
    let mut suffix = 0;
    while dest.exists() {
        suffix += 1;
        dest = export_dir.join(format!("miyolist_{timestamp}_{suffix}.sqlite3"));
    }

    let dest_str = dest.to_string_lossy().replace('\'', "''");
    let conn = open_connection(&database_path)?;

    // Retry a few times: if another connection (e.g. a background sync) holds
    // a write transaction at this moment, VACUUM INTO fails with
    // "database is locked".  A short backoff usually lets it complete.
    let mut last_error: Option<String> = None;
    for attempt in 0..3 {
        match conn.execute_batch(&format!("VACUUM INTO '{dest_str}';")) {
            Ok(()) => {
                last_error = None;
                break;
            }
            Err(e) => {
                last_error = Some(format!("Failed to snapshot database: {e}"));
                if attempt < 2 {
                    std::thread::sleep(std::time::Duration::from_millis(300 * (attempt + 1)));
                }
            }
        }
    }
    if let Some(error) = last_error {
        return Err(error);
    }

    Ok(ExportResult {
        path: dest.to_string_lossy().to_string(),
        entry_count: 0, // raw backup — entry count not meaningful
    })
}

/// Imports library entries from a JSON file produced by `export_library_json`.
/// Existing entries (same media_id + media_type + list_kind) are skipped.
pub fn import_library_json(app: &AppHandle, path: String) -> Result<ImportResult, String> {
    let content = std::fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let payload: serde_json::Value = serde_json::from_str(&content).map_err(|e| e.to_string())?;

    let entries = payload["entries"]
        .as_array()
        .ok_or_else(|| "Invalid export format: missing 'entries' array".to_string())?;

    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;

    let mut imported = 0i64;
    let mut skipped = 0i64;
    let mut errors: Vec<String> = Vec::new();

    for entry in entries {
        let media_id = entry["mediaId"].as_i64().unwrap_or(0);
        let media_type = entry["mediaType"].as_str().unwrap_or("ANIME");
        let list_kind = entry["listKind"].as_str().unwrap_or("ANIME");
        let status = entry["status"].as_str().unwrap_or("PLANNING");
        let score = entry["score"].as_f64();
        let progress = entry["progress"].as_i64().unwrap_or(0);
        let progress_v = entry["progressVolumes"].as_i64().unwrap_or(0);
        let repeat_c = entry["repeatCount"].as_i64().unwrap_or(0);
        let notes = entry["notes"].as_str();
        let started = entry["startedAt"].as_str();
        let completed = entry["completedAt"].as_str();
        // NOTE: keep `updated` as an Option.  Inserting the literal string
        // "CURRENT_TIMESTAMP" here would persist that text instead of the SQL
        // function; the INSERT uses COALESCE(?12, CURRENT_TIMESTAMP) instead.
        let updated = entry["updatedAt"].as_str();
        let al_id = entry["anilistEntryId"].as_i64();

        if media_id == 0 {
            errors.push("Skipped entry with missing mediaId".into());
            skipped += 1;
            continue;
        }

        match conn.execute(
            "INSERT OR IGNORE INTO media_list_entries
             (media_id, media_type, list_kind, status, score, progress, progress_volumes,
              repeat_count, notes, started_at, completed_at, updated_at, anilist_entry_id,
              is_dirty, source)
             VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,COALESCE(?12, CURRENT_TIMESTAMP),?13,0,'import')",
            rusqlite::params![
                media_id, media_type, list_kind, status, score, progress, progress_v, repeat_c,
                notes, started, completed, updated, al_id,
            ],
        ) {
            Ok(rows) if rows > 0 => imported += 1,
            Ok(_) => skipped += 1,
            Err(e) => {
                errors.push(format!("media_id={media_id}: {e}"));
                skipped += 1;
            }
        }
    }

    Ok(ImportResult {
        imported_count: imported,
        skipped_count: skipped,
        errors,
    })
}

// ─── Local helpers ────────────────────────────────────────────────────────────

fn export_directory(app: &AppHandle) -> Result<std::path::PathBuf, String> {
    let base = app.path().app_data_dir().map_err(|e| e.to_string())?;
    let dir = base.join("exports");
    std::fs::create_dir_all(&dir).map_err(|e| e.to_string())?;
    Ok(dir)
}

fn chrono_now_iso() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Simple ISO-8601 approximation; full chrono dep not needed.
    format!("{secs}")
}

fn chrono_now_file_safe() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    format!("{secs}")
}

/// Returns all non-null cover image URLs from `media_cache` (used by the
/// image prefetch logic).
pub fn get_all_cover_urls(app: &AppHandle) -> Result<Vec<String>, String> {
    let database_path = database_path(app)?;
    let conn = open_connection(&database_path)?;
    let mut stmt = conn
        .prepare("SELECT cover_image FROM media_cache WHERE cover_image IS NOT NULL")
        .map_err(|e| e.to_string())?;
    let urls: Vec<String> = stmt
        .query_map([], |r| r.get(0))
        .map_err(|e| e.to_string())?
        .flatten()
        .collect();
    Ok(urls)
}
