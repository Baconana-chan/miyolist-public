use serde::{Deserialize, Serialize};

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FoundationModule {
    pub name: String,
    pub summary: String,
    pub status: String,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BootstrapPayload {
    pub product_name: String,
    pub app_version: String,
    pub primary_platform: String,
    pub supported_targets: Vec<String>,
    pub guarantees: Vec<String>,
    pub auth_strategy: Vec<String>,
    pub foundation_modules: Vec<FoundationModule>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DatabaseTableInfo {
    pub name: String,
    pub exists: bool,
    pub row_count: i64,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DatabaseOverview {
    pub database_path: String,
    pub schema_version: i64,
    pub table_count: usize,
    pub tables: Vec<DatabaseTableInfo>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DatabaseInitResult {
    pub database_path: String,
    pub schema_version: i64,
    pub created_now: bool,
    pub migration_applied: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthRequestPlan {
    pub auth_url: String,
    pub redirect_uri: String,
    pub callback_host: String,
    pub callback_port: u16,
    pub callback_path: String,
    pub state: String,
    pub response_type: String,
    pub uses_website_bridge: bool,
    pub notes: Vec<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AniListConfigStatus {
    pub client_id_configured: bool,
    pub client_secret_configured: bool,
    pub auth_url: String,
    pub token_url: String,
    pub graphql_url: String,
    pub uses_env_file: bool,
    pub missing_vars: Vec<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AniListViewer {
    pub id: i64,
    pub name: String,
    pub avatar_url: Option<String>,
    /// AniList score format preference (`POINT_100`, `POINT_10_DECIMAL`, ...).
    pub score_format: String,
    /// User-defined custom lists for anime media.
    pub anime_custom_lists: Vec<String>,
    /// User-defined custom lists for manga/novel media.
    pub manga_custom_lists: Vec<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthSessionStatus {
    pub has_access_token: bool,
    pub viewer_id: Option<i64>,
    pub viewer_name: Option<String>,
    pub viewer_avatar_url: Option<String>,
    pub token_expires_at: Option<String>,
    pub is_token_expired: bool,
    pub updated_at: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LibrarySnapshot {
    pub total_entries: i64,
    pub anime_entries: i64,
    pub manga_entries: i64,
    pub current_entries: i64,
    pub planned_entries: i64,
    pub completed_entries: i64,
    pub cached_media: i64,
    pub search_history_count: i64,
    pub profile_name: Option<String>,
    pub profile_avatar_url: Option<String>,
    pub has_access_token: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ListEntry {
    pub local_id: i64,
    /// AniList server-side MediaList.id; `None` for entries created locally
    /// before the first sync. After a successful sync this is always set.
    pub anilist_entry_id: Option<i64>,
    pub media_id: i64,
    pub media_type: String,
    pub list_kind: String,
    pub title: String,
    pub cover_image: Option<String>,
    pub status: String,
    pub score: Option<f64>,
    /// Episodes watched (anime) or chapters read (manga/LN).
    pub progress: i64,
    /// Volumes read — manga/LN only; always 0 for anime.
    pub progress_volumes: i64,
    pub episodes_or_chapters: Option<i64>,
    pub repeat_count: i64,
    pub notes: Option<String>,
    pub started_at: Option<String>,
    pub completed_at: Option<String>,
    /// Custom list names stored as a JSON array in the DB.
    pub custom_lists: Vec<String>,
    pub updated_at: String,
    pub is_dirty: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaSearchResult {
    pub media_id: i64,
    pub media_type: String,
    pub title: String,
    pub cover_image: Option<String>,
    pub format: Option<String>,
    pub status: Option<String>,
    pub episodes: Option<i64>,
    pub chapters: Option<i64>,
    pub genres: Vec<String>,
    pub average_score: Option<i64>,
    pub is_adult: bool,
    pub in_library: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncSummary {
    /// Entries pulled from AniList into the local DB.
    pub synced: i64,
    /// Dirty local entries successfully pushed to AniList.
    pub pushed: i64,
    /// Entries that failed to push (network / auth errors).
    pub failed: i64,
    /// Entries where both local and remote changed since the last sync (conflict).
    pub conflicts: i64,
    /// `true` if this sync used the high-water-mark delta path (partial pull).
    pub is_delta: bool,
    /// ISO-8601 UTC timestamp when this sync completed.
    pub last_synced_at: String,
}

/// One entry from the `pending_conflicts` table — both sides of a conflict.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PendingConflict {
    pub media_id: i64,
    pub media_type: String,
    pub media_title: Option<String>,
    // local (dirty) values currently stored on device
    pub local_status: Option<String>,
    pub local_score: Option<f64>,
    pub local_progress: i64,
    pub local_notes: Option<String>,
    // remote (AniList) values that were not applied due to the conflict
    pub remote_status: Option<String>,
    pub remote_score: Option<f64>,
    pub remote_progress: i64,
    pub remote_notes: Option<String>,
    pub detected_at: String,
}

/// One row from the `sync_log` table.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncLogEntry {
    pub id: i64,
    pub media_id: i64,
    pub media_title: Option<String>,
    /// `"pulled"` | `"pushed"` | `"conflict"` | `"skipped"`
    pub sync_type: String,
    pub detail: Option<String>,
    pub created_at: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaTag {
    pub name: String,
    pub category: Option<String>,
    pub rank: Option<i64>,
    pub is_spoiler: bool,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaStudio {
    pub id: i64,
    pub name: String,
    pub is_animation_studio: bool,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaRelation {
    pub media_id: i64,
    pub media_type: Option<String>,
    pub format: Option<String>,
    pub title: String,
    pub cover_image: Option<String>,
    pub status: Option<String>,
    pub relation_type: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaRecommendation {
    pub media_id: i64,
    pub format: Option<String>,
    pub title: String,
    pub cover_image: Option<String>,
    pub mean_score: Option<i64>,
    pub rating: i64,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaCharacterEdge {
    pub character_id: i64,
    pub name: String,
    pub image: Option<String>,
    pub role: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaStaffEdge {
    pub staff_id: i64,
    pub name: String,
    pub image: Option<String>,
    pub role: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ExternalLink {
    pub url: String,
    pub site: String,
    pub link_type: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AiringInfo {
    pub episode: i64,
    pub airing_at: i64,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MediaDetails {
    pub media_id: i64,
    pub media_type: String,
    pub format: Option<String>,
    pub status: Option<String>,
    pub title_romaji: Option<String>,
    pub title_english: Option<String>,
    pub title_native: Option<String>,
    pub description: Option<String>,
    pub cover_image: Option<String>,
    pub banner_image: Option<String>,
    pub episodes: Option<i64>,
    pub chapters: Option<i64>,
    pub volumes: Option<i64>,
    pub duration: Option<i64>,
    pub season: Option<String>,
    pub season_year: Option<i64>,
    pub source: Option<String>,
    pub genres: Vec<String>,
    pub tags: Vec<MediaTag>,
    pub average_score: Option<i64>,
    pub popularity: Option<i64>,
    pub favourites: Option<i64>,
    pub is_adult: bool,
    pub studios: Vec<MediaStudio>,
    pub next_airing_episode: Option<AiringInfo>,
    pub start_date: Option<String>,
    pub end_date: Option<String>,
    pub cached_at: String,
    pub in_library: bool,
    #[serde(default)]
    pub relations: Vec<MediaRelation>,
    #[serde(default)]
    pub characters: Vec<MediaCharacterEdge>,
    #[serde(default)]
    pub staff: Vec<MediaStaffEdge>,
    #[serde(default)]
    pub recommendations: Vec<MediaRecommendation>,
    #[serde(default)]
    pub external_links: Vec<ExternalLink>,
}

/// A single upcoming or recently aired episode for an anime in the user's list.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AiringEntry {
    pub media_id: i64,
    pub title: String,
    pub cover_image: Option<String>,
    /// Next airing episode number.
    pub episode: i64,
    /// Unix timestamp (seconds) when this episode airs / aired.
    pub airing_at: i64,
    /// Whether an OS notification has already been sent for this episode.
    pub notified: bool,
    /// User's current watch progress (episodes watched).
    pub user_progress: i64,
    /// User's list status (current, planning, …) or empty string if not in library.
    pub list_status: String,
    pub score: Option<f64>,
    /// Total episode count of the series (None if unknown/ongoing).
    pub total_episodes: Option<i64>,
}

/// A global upcoming airing entry from AniList, not limited to the user's library.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GlobalAiringEntry {
    pub media_id: i64,
    pub title: String,
    pub cover_image: Option<String>,
    pub episode: i64,
    /// Unix timestamp (seconds) when this episode airs.
    pub airing_at: i64,
    pub format: Option<String>,
    pub popularity: Option<i64>,
}

/// Per-category notification toggles stored in `notification_settings`.
#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationSettings {
    pub airing_enabled: bool,
    pub activity_enabled: bool,
    pub forum_enabled: bool,
    pub follows_enabled: bool,
    pub media_enabled: bool,
    pub submissions_enabled: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct NotificationOverride {
    pub media_id: i64,
    pub enabled: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AniListNotificationItem {
    pub id: i64,
    pub notification_type: String,
    pub created_at: i64,
    pub is_read: bool,
    pub title: String,
    pub body: String,
    pub link: Option<String>,
    pub media_id: Option<i64>,
    pub cover_image: Option<String>,
    pub user_name: Option<String>,
    pub user_avatar: Option<String>,
}

// ─── Statistics ───────────────────────────────────────────────────────────────

/// One bucket in the score histogram (score 1–10, plus bucket 0 = unscored).
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ScoreBucket {
    /// Integer score 1-10 (0 = no score).
    pub score: i64,
    pub count: i64,
}

/// A single label → count pair used for format / genre breakdowns.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BreakdownItem {
    pub label: String,
    pub count: i64,
}

/// Derived statistics built from local library data — no AniList requests.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LibraryStats {
    // ── totals ──────────────────────────────────────────────────────────────
    pub total_entries: i64,
    pub total_anime: i64,
    pub total_manga: i64,
    pub total_novels: i64,

    // ── status breakdown ────────────────────────────────────────────────────
    pub count_current: i64,
    pub count_completed: i64,
    pub count_planning: i64,
    pub count_dropped: i64,
    pub count_paused: i64,
    pub count_repeating: i64,

    // ── progress totals ─────────────────────────────────────────────────────
    pub episodes_watched: i64,
    pub chapters_read: i64,
    pub volumes_read: i64,
    /// Total minutes estimated from `progress × per-episode duration`.
    pub estimated_minutes: i64,

    // ── scores ──────────────────────────────────────────────────────────────
    pub mean_score: Option<f64>,
    /// Histogram; always 10 elements (scores 1-10).
    pub score_distribution: Vec<ScoreBucket>,

    // ── breakdowns ──────────────────────────────────────────────────────────
    pub format_breakdown: Vec<BreakdownItem>,
    /// Top 15 genres by entry count.
    pub genre_breakdown: Vec<BreakdownItem>,
}

// ─── Activity log ─────────────────────────────────────────────────────────────

/// One row from `activity_log` with joined media metadata.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ActivityEntry {
    pub id: i64,
    pub media_id: i64,
    pub media_type: String,
    pub title: String,
    pub cover_image: Option<String>,
    /// `progress_update` | `status_change` | `score_change` | `added` | `completed`
    pub activity_type: String,
    pub old_value: Option<String>,
    pub new_value: Option<String>,
    pub note: Option<String>,
    pub created_at: String,
}

/// One day of heatmap data.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct HeatmapDay {
    /// `YYYY-MM-DD`
    pub date: String,
    pub count: i64,
}

/// Monthly progress totals for the selected year.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MonthlyActivityCount {
    /// 1..=12
    pub month: i64,
    pub episodes: i64,
    pub chapters: i64,
}

/// Year-in-review aggregate stats for the selected year.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AnnualWrapUp {
    pub year: i64,
    pub days_active: i64,
    pub list_updates: i64,
    pub completed_anime: i64,
    pub episodes_watched: i64,
    pub chapters_read: i64,
    pub mean_score: Option<f64>,
    pub top_genres: Vec<BreakdownItem>,
    pub top_studio: Option<String>,
    pub most_watched_weekday: Option<String>,
    pub first_completed_title: Option<String>,
    pub last_completed_title: Option<String>,
}

// ─── App settings ─────────────────────────────────────────────────────────────

/// User-configurable app settings persisted in the `app_settings` key-value table.
#[derive(Clone, Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct AppSettings {
    /// Whether to show adult (18+) content in search and library.
    pub show_adult_content: bool,
    /// Default media-type tab: `"ANIME"` | `"MANGA"` | `"NOVEL"`
    pub default_list_tab: String,
    /// Default library sort: `"updated_desc"` | `"title_asc"` | `"score_desc"` | `"progress_desc"`
    pub default_sort: String,
    /// Default library view: `"list"` | `"compact"` | `"grid"`
    pub library_view: String,
    /// Default schedule view: `"list"` | `"card"`
    pub schedule_view: String,
    /// Statuses to hide from the library (comma-separated, e.g. `"DROPPED,PAUSED"`)
    pub hidden_statuses: String,
    /// Auto-sync interval in minutes; 0 = disabled.  Default 15.
    pub auto_sync_interval: i64,
    /// ISO-8601 UTC timestamp of the last completed sync; `None` if never synced.
    pub last_synced_at: Option<String>,
    /// AniList viewer score format preference.
    pub score_format: String,
    /// Hide app to system tray when the main window close button is pressed.
    pub minimize_to_tray_on_close: bool,
}

impl Default for AppSettings {
    fn default() -> Self {
        AppSettings {
            show_adult_content: false,
            default_list_tab: "ANIME".into(),
            default_sort: "updated_desc".into(),
            library_view: "list".into(),
            schedule_view: "list".into(),
            hidden_statuses: String::new(),
            auto_sync_interval: 15,
            last_synced_at: None,
            score_format: "POINT_10_DECIMAL".into(),
            minimize_to_tray_on_close: false,
        }
    }
}

// ─── Cache stats ──────────────────────────────────────────────────────────────

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CacheStats {
    pub media_cache_count: i64,
    pub search_history_count: i64,
    pub airing_cache_count: i64,
    pub activity_log_count: i64,
    pub image_cache_count: i64,
    /// Total bytes of cached cover images on disk.
    pub image_cache_bytes: i64,
}

// ─── Backup / export ─────────────────────────────────────────────────────────

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ExportResult {
    pub path: String,
    pub entry_count: i64,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ImportResult {
    pub imported_count: i64,
    pub skipped_count: i64,
    pub errors: Vec<String>,
}

// ─── Favourites ───────────────────────────────────────────────────────────────

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FavoriteMedia {
    pub id: i64,
    pub title: String,
    pub cover_image: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FavoritePerson {
    pub id: i64,
    pub name: String,
    pub image: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FavoriteStudio {
    pub id: i64,
    pub name: String,
    pub is_animation_studio: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UserFavorites {
    pub anime: Vec<FavoriteMedia>,
    pub manga: Vec<FavoriteMedia>,
    pub characters: Vec<FavoritePerson>,
    pub staff: Vec<FavoritePerson>,
    pub studios: Vec<FavoriteStudio>,
}

// ─── People / public detail pages ────────────────────────────────────────────

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CharacterMedia {
    pub id: i64,
    pub title: String,
    pub cover_image: Option<String>,
    pub format: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CharacterDetails {
    pub id: i64,
    pub name_full: Option<String>,
    pub name_native: Option<String>,
    pub image: Option<String>,
    pub description: Option<String>,
    pub gender: Option<String>,
    pub age: Option<String>,
    pub date_of_birth: Option<String>,
    pub favourites: Option<i64>,
    pub media: Vec<CharacterMedia>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StaffCharacter {
    pub id: i64,
    pub name: String,
    pub image: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StaffDetails {
    pub id: i64,
    pub name_full: Option<String>,
    pub name_native: Option<String>,
    pub image: Option<String>,
    pub description: Option<String>,
    pub primary_occupations: Vec<String>,
    pub gender: Option<String>,
    pub age: Option<i64>,
    pub date_of_birth: Option<String>,
    pub date_of_death: Option<String>,
    pub favourites: Option<i64>,
    pub characters: Vec<StaffCharacter>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StudioMedia {
    pub id: i64,
    pub title: String,
    pub cover_image: Option<String>,
    pub format: Option<String>,
    pub status: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StudioDetails {
    pub id: i64,
    pub name: String,
    pub is_animation_studio: bool,
    pub favourites: Option<i64>,
    pub site_url: Option<String>,
    pub media: Vec<StudioMedia>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UserProfileStats {
    pub anime_count: i64,
    pub episodes_watched: i64,
    pub anime_mean_score: Option<f64>,
    pub manga_count: i64,
    pub chapters_read: i64,
    pub manga_mean_score: Option<f64>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UserProfile {
    pub id: i64,
    pub name: String,
    pub avatar_url: Option<String>,
    pub banner_url: Option<String>,
    pub about: Option<String>,
    pub is_following: bool,
    pub is_follower: bool,
    pub followers_count: i64,
    pub following_count: i64,
    pub stats: Option<UserProfileStats>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SocialUser {
    pub id: i64,
    pub name: String,
    pub avatar_url: Option<String>,
    pub is_following: bool,
    pub is_follower: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ActivityReplyItem {
    pub id: i64,
    /// Unix timestamp (seconds)
    pub created_at: i64,
    pub like_count: i64,
    pub is_liked: bool,
    pub user_id: i64,
    pub user_name: String,
    pub user_avatar: Option<String>,
    pub text: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FollowingActivityItem {
    pub id: i64,
    /// `TEXT` | `ANIME_LIST` | `MANGA_LIST`
    pub activity_type: String,
    /// Unix timestamp (seconds)
    pub created_at: i64,
    pub like_count: i64,
    pub reply_count: i64,
    pub is_liked: bool,
    pub is_message: bool,
    pub user_id: i64,
    pub user_name: String,
    pub user_avatar: Option<String>,
    pub text: Option<String>,
    pub status: Option<String>,
    pub progress: Option<String>,
    pub media_id: Option<i64>,
    pub media_title: Option<String>,
    pub media_cover_image: Option<String>,
    pub replies: Vec<ActivityReplyItem>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UserMediaListItem {
    pub media_id: i64,
    pub media_type: String,
    pub title: String,
    pub cover_image: Option<String>,
    pub status: String,
    pub score: Option<f64>,
    pub progress: i64,
    pub progress_volumes: i64,
    pub updated_at: i64,
}

// ─── People / search results ──────────────────────────────────────────────────

/// Result for character or staff search.
#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct PersonSearchResult {
    pub id: i64,
    /// `"CHARACTER"` or `"STAFF"`
    pub kind: String,
    pub name: String,
    pub image: Option<String>,
    /// First media title (for characters), primary occupation (for staff).
    pub sub: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StudioSearchResult {
    pub id: i64,
    pub name: String,
    pub is_animation_studio: bool,
    pub recent_title: Option<String>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UserSearchResult {
    pub id: i64,
    pub name: String,
    pub avatar_url: Option<String>,
}