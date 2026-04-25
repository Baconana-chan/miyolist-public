//! Remote AniList GraphQL response types.
//!
//! These structs exist **only** to deserialize the raw JSON that AniList sends
//! back over the wire. They are never persisted directly and never cross the
//! Tauri IPC boundary. All fields use the exact naming that AniList's schema
//! produces so that `serde_json` can map them with minimal custom attributes.
//!
//! After deserialization the data is converted into local app models
//! (`crate::models`) before being stored or returned to the frontend.

use serde::Deserialize;
use serde_json::Value;

// ─── Generic GraphQL envelope ─────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct GraphQlResponse<T> {
    pub data: Option<T>,
    pub errors: Option<Vec<GraphQlError>>,
}

#[derive(Deserialize)]
pub(super) struct GraphQlError {
    pub message: String,
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

/// Response to the OAuth token exchange POST.
#[derive(Deserialize)]
pub(super) struct TokenExchangeResponse {
    pub access_token: String,
    pub expires_in: Option<i64>,
}

// ─── Viewer ───────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct ViewerPayload {
    #[serde(rename = "Viewer")]
    pub viewer: ViewerNode,
}

#[derive(Deserialize)]
pub(super) struct ViewerNode {
    pub id: i64,
    pub name: String,
    pub avatar: Option<AvatarNode>,
    #[serde(rename = "mediaListOptions")]
    pub media_list_options: Option<ViewerMediaListOptions>,
}

#[derive(Deserialize)]
pub(super) struct AvatarNode {
    pub large: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct ViewerMediaListOptions {
    #[serde(rename = "scoreFormat")]
    pub score_format: Option<String>,
    #[serde(rename = "animeList")]
    pub anime_list: Option<ViewerListOptions>,
    #[serde(rename = "mangaList")]
    pub manga_list: Option<ViewerListOptions>,
}

// ─── Notifications ───────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct NotificationsPayload {
    #[serde(rename = "Page")]
    pub page: NotificationsPage,
}

#[derive(Deserialize)]
pub(super) struct NotificationsPage {
    pub notifications: Vec<Value>,
}

#[derive(Deserialize)]
pub(super) struct ViewerListOptions {
    #[serde(rename = "customLists")]
    pub custom_lists: Option<Vec<String>>,
}

// ─── User media lists ─────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct UserListsPayload {
    #[serde(rename = "MediaListCollection")]
    pub media_list_collection: UserMediaListCollection,
}

// ─── Delta / Page.mediaList query ────────────────────────────────────────────

/// Response shape for `Page { mediaList(...) { ... } pageInfo { hasNextPage } }`.
/// Used by the incremental delta-sync path that only fetches entries updated
/// since the high-water mark timestamp.
#[derive(Deserialize)]
pub(super) struct DeltaListPayload {
    #[serde(rename = "Page")]
    pub page: DeltaListPage,
}

#[derive(Deserialize)]
pub(super) struct DeltaListPage {
    #[serde(rename = "mediaList")]
    pub media_list: Vec<DeltaListEntry>,
    #[serde(rename = "pageInfo")]
    pub page_info: ListPageInfo,
}

#[derive(Deserialize)]
pub(super) struct ListPageInfo {
    #[serde(rename = "hasNextPage")]
    pub has_next_page: bool,
}

/// One entry from the `Page.mediaList` delta query.
#[derive(Deserialize)]
pub(super) struct DeltaListEntry {
    /// Server-side MediaList.id.
    pub id: i64,
    pub status: String,
    pub score: Option<f64>,
    pub progress: i64,
    #[serde(rename = "progressVolumes")]
    pub progress_volumes: Option<i64>,
    pub repeat: i64,
    pub notes: Option<String>,
    /// `customLists(asArray: true)` returns `[{name, enabled}]` — not a flat
    /// list of strings.  Use `enabled_custom_list_names()` to get the names
    /// the entry is currently in.
    #[serde(rename = "customLists")]
    pub custom_lists: Option<Vec<DeltaCustomListEntry>>,
    #[serde(rename = "startedAt")]
    pub started_at: Option<FuzzyDateNode>,
    #[serde(rename = "completedAt")]
    pub completed_at: Option<FuzzyDateNode>,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
    pub media: DeltaMedia,
}

/// `customLists(asArray: true)` element shape: `{ name, enabled }`.
#[derive(Deserialize, Clone)]
pub(super) struct DeltaCustomListEntry {
    pub name: String,
    pub enabled: bool,
}

impl DeltaListEntry {
    /// Extract the names of custom lists this entry currently belongs to
    /// (i.e. `enabled = true`).  Empty when AniList returns nothing.
    pub fn enabled_custom_list_names(&self) -> Vec<String> {
        self.custom_lists
            .as_ref()
            .map(|items| {
                items
                    .iter()
                    .filter(|c| c.enabled)
                    .map(|c| c.name.clone())
                    .collect()
            })
            .unwrap_or_default()
    }
}

#[derive(Deserialize)]
pub(super) struct DeltaMedia {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: String,
    pub format: Option<String>,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub episodes: Option<i64>,
    pub chapters: Option<i64>,
    pub volumes: Option<i64>,
    #[serde(rename = "isAdult")]
    pub is_adult: Option<bool>,
    /// AniList genre tags. Required for the local genre breakdown / top genres
    /// statistics (`media_cache.payload_json.genres`).
    #[serde(default)]
    pub genres: Vec<String>,
    /// Per-episode duration in minutes (anime only). Required for the
    /// estimated-watch-time stat (`media_cache.payload_json.duration`).
    pub duration: Option<i64>,
    /// Studios connection — only the studio name is stored locally for the
    /// "top studio" annual-wrap-up stat.
    pub studios: Option<DeltaStudioConnection>,
}

#[derive(Deserialize)]
pub(super) struct DeltaStudioConnection {
    #[serde(default)]
    pub nodes: Vec<DeltaStudioNode>,
}

#[derive(Deserialize)]
pub(super) struct DeltaStudioNode {
    pub name: String,
}

#[derive(Deserialize)]
pub(super) struct UserMediaListCollection {
    pub lists: Vec<UserMediaList>,
}

#[derive(Deserialize)]
pub(super) struct UserMediaList {
    pub entries: Vec<UserListEntry>,
}

/// A single entry in the authenticated user's AniList media list.
///
/// **AniList-canonical fields** (remote always wins on sync, local copy exists
/// only as a working copy until the next successful sync):
/// - `id` — the server-side MediaList.id (stored as `anilist_entry_id`)
/// - `status`, `score`, `progress`, `progress_volumes`, `repeat`, `notes`
/// - `started_at`, `completed_at`, `updated_at`
///
/// Everything else (`media`) is read-only metadata, also AniList-canonical.
#[derive(Deserialize)]
pub(super) struct UserListEntry {
    /// Server-side MediaList.id — used to issue save/delete mutations.
    pub id: i64,
    pub status: String,
    pub score: Option<f64>,
    /// Episodes watched (anime) or chapters read (manga).
    pub progress: i64,
    /// Volumes read (manga only).
    #[serde(rename = "progressVolumes")]
    pub progress_volumes: Option<i64>,
    pub repeat: i64,
    pub notes: Option<String>,
    #[serde(rename = "customLists")]
    pub custom_lists: Option<Vec<String>>,
    #[serde(rename = "startedAt")]
    pub started_at: Option<FuzzyDateNode>,
    #[serde(rename = "completedAt")]
    pub completed_at: Option<FuzzyDateNode>,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
    pub media: UserListMedia,
}

/// AniList FuzzyDate — year/month/day are all nullable.
#[derive(Deserialize)]
pub(super) struct FuzzyDateNode {
    pub year: Option<i32>,
    pub month: Option<i32>,
    pub day: Option<i32>,
}

impl FuzzyDateNode {
    /// Format as an ISO-8601 date string (`YYYY-MM-DD`), returning `None` if
    /// the year is absent.
    pub fn to_iso_date(&self) -> Option<String> {
        self.year.map(|y| {
            format!(
                "{:04}-{:02}-{:02}",
                y,
                self.month.unwrap_or(1),
                self.day.unwrap_or(1)
            )
        })
    }
}

/// Embedded media metadata inside a list entry. All fields are AniList-canonical
/// — they are cached locally but never edited by the user directly.
#[derive(Deserialize)]
pub(super) struct UserListMedia {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: String,
    /// AniList format string: TV, MOVIE, OVA, ONA, MANGA, NOVEL, ONE_SHOT, etc.
    pub format: Option<String>,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub episodes: Option<i64>,
    pub chapters: Option<i64>,
    pub volumes: Option<i64>,
    #[serde(rename = "isAdult")]
    pub is_adult: Option<bool>,
}

// ─── Shared media title / image helpers ──────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct MediaTitleNode {
    pub romaji: Option<String>,
    pub english: Option<String>,
    pub native: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct CoverImageNode {
    pub large: Option<String>,
}

// ─── Search ───────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct SearchPayload {
    #[serde(rename = "Page")]
    pub page: SearchPage,
}

#[derive(Deserialize)]
pub(super) struct SearchPage {
    pub media: Vec<SearchMediaNode>,
}

#[derive(Deserialize)]
pub(super) struct SearchMediaNode {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: String,
    pub format: Option<String>,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub status: Option<String>,
    pub episodes: Option<i64>,
    pub chapters: Option<i64>,
    pub genres: Vec<String>,
    #[serde(rename = "averageScore")]
    pub average_score: Option<i64>,
    #[serde(rename = "isAdult")]
    pub is_adult: Option<bool>,
}

// ─── Mutations ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct SaveEntryPayload {
    #[serde(rename = "SaveMediaListEntry")]
    pub save_media_list_entry: SavedEntryNode,
}

#[derive(Deserialize)]
pub(super) struct SavedEntryNode {
    /// The server-side MediaList.id returned after a successful mutation.
    pub id: i64,
}

// ─── Media details ────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct MediaDetailsPayload {
    #[serde(rename = "Media")]
    pub media: MediaDetailsNode,
}

/// Full media metadata returned by the Media(id) query.
/// All fields are AniList-canonical and cached in `media_cache.payload_json`.
#[derive(Deserialize)]
pub(super) struct MediaDetailsNode {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: String,
    pub format: Option<String>,
    pub status: Option<String>,
    pub title: MediaTitleNode,
    pub description: Option<String>,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<DetailCoverImageNode>,
    #[serde(rename = "bannerImage")]
    pub banner_image: Option<String>,
    pub episodes: Option<i64>,
    pub chapters: Option<i64>,
    pub volumes: Option<i64>,
    /// Episode duration in minutes.
    pub duration: Option<i64>,
    pub season: Option<String>,
    #[serde(rename = "seasonYear")]
    pub season_year: Option<i64>,
    pub source: Option<String>,
    pub genres: Vec<String>,
    pub tags: Vec<MediaTagNode>,
    #[serde(rename = "averageScore")]
    pub average_score: Option<i64>,
    pub popularity: Option<i64>,
    pub favourites: Option<i64>,
    #[serde(rename = "isAdult")]
    pub is_adult: Option<bool>,
    pub studios: Option<StudioConnection>,
    #[serde(rename = "nextAiringEpisode")]
    pub next_airing_episode: Option<AiringNode>,
    #[serde(rename = "startDate")]
    pub start_date: Option<FuzzyDateNode>,
    #[serde(rename = "endDate")]
    pub end_date: Option<FuzzyDateNode>,
    pub relations: Option<RelationsConnection>,
    pub characters: Option<CharactersConnection>,
    pub staff: Option<MediaStaffConnection>,
    pub recommendations: Option<RecommendationsConnection>,
    #[serde(rename = "externalLinks")]
    pub external_links: Option<Vec<ExternalLinkNode>>,
}

#[derive(Deserialize)]
pub(super) struct DetailCoverImageNode {
    pub extra_large: Option<String>,
    pub large: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct MediaTagNode {
    pub name: String,
    pub category: Option<String>,
    pub rank: Option<i64>,
    #[serde(rename = "isGeneralSpoiler")]
    pub is_spoiler: Option<bool>,
}

#[derive(Deserialize)]
pub(super) struct StudioConnection {
    pub nodes: Vec<StudioNode>,
}

#[derive(Deserialize)]
pub(super) struct StudioNode {
    pub id: i64,
    pub name: String,
    #[serde(rename = "isAnimationStudio")]
    pub is_animation_studio: bool,
}

#[derive(Deserialize)]
pub(super) struct AiringNode {
    pub episode: i64,
    #[serde(rename = "airingAt")]
    pub airing_at: i64,
}

// ─── Relations ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct RelationsConnection {
    pub edges: Vec<RelationEdge>,
}

#[derive(Deserialize)]
pub(super) struct RelationEdge {
    #[serde(rename = "relationType")]
    pub relation_type: Option<String>,
    pub node: RelationMediaNode,
}

#[derive(Deserialize)]
pub(super) struct RelationMediaNode {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: Option<String>,
    pub format: Option<String>,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub status: Option<String>,
}

// ─── Characters & Staff in media ────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct PersonNameNode {
    pub full: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct PersonImageNode {
    pub large: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct CharactersConnection {
    pub edges: Vec<CharacterEdgeMedia>,
}

#[derive(Deserialize)]
pub(super) struct CharacterEdgeMedia {
    pub role: Option<String>,
    pub node: CharacterPersonNode,
}

#[derive(Deserialize)]
pub(super) struct CharacterPersonNode {
    pub id: i64,
    pub name: Option<PersonNameNode>,
    pub image: Option<PersonImageNode>,
}

#[derive(Deserialize)]
pub(super) struct MediaStaffConnection {
    pub edges: Vec<StaffEdgeMedia>,
}

#[derive(Deserialize)]
pub(super) struct StaffEdgeMedia {
    pub role: Option<String>,
    pub node: StaffPersonNode,
}

#[derive(Deserialize)]
pub(super) struct StaffPersonNode {
    pub id: i64,
    pub name: Option<PersonNameNode>,
    pub image: Option<PersonImageNode>,
}

// ─── Recommendations ───────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct RecommendationsConnection {
    pub nodes: Vec<RecommendationNode>,
}

#[derive(Deserialize)]
pub(super) struct RecommendationNode {
    #[serde(rename = "mediaRecommendation")]
    pub media_recommendation: Option<RecommendationMediaNode>,
    pub rating: Option<i64>,
}

#[derive(Deserialize)]
pub(super) struct RecommendationMediaNode {
    pub id: i64,
    pub format: Option<String>,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    #[serde(rename = "meanScore")]
    pub mean_score: Option<i64>,
}

// ─── Airing schedule ─────────────────────────────────────────────────────────

// ─── External Links ─────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct ExternalLinkNode {
    pub url: String,
    pub site: String,
    #[serde(rename = "type")]
    pub link_type: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct AiringSchedulePayload {
    #[serde(rename = "Page")]
    pub page: AiringSchedulePage,
}

#[derive(Deserialize)]
pub(super) struct AiringSchedulePage {
    #[serde(rename = "airingSchedules")]
    pub airing_schedules: Vec<AiringScheduleNode>,
    #[serde(rename = "pageInfo")]
    pub page_info: Option<PageInfo>,
}

#[derive(Deserialize)]
pub(super) struct AiringScheduleNode {
    pub episode: i64,
    #[serde(rename = "airingAt")]
    pub airing_at: i64,
    pub media: AiringScheduleMedia,
}

#[derive(Deserialize)]
pub(super) struct AiringScheduleMedia {
    pub id: i64,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub episodes: Option<i64>,
    pub format: Option<String>,
    pub popularity: Option<i64>,
}

// ─── Favourites ───────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct FavouritesPayload {
    #[serde(rename = "Viewer")]
    pub viewer: FavViewerNode,
}

#[derive(Deserialize)]
pub(super) struct FavViewerNode {
    pub favourites: FavouritesNode,
}

#[derive(Deserialize)]
pub(super) struct PageInfo {
    #[serde(rename = "hasNextPage")]
    pub has_next_page: bool,
    pub total: Option<i64>,
}

#[derive(Deserialize)]
pub(super) struct FavouritesNode {
    pub anime: FavMediaConnection,
    pub manga: FavMediaConnection,
    pub characters: FavCharacterConnection,
    pub staff: FavStaffConnection,
    pub studios: FavStudioConnection,
}

#[derive(Deserialize)]
pub(super) struct FavMediaConnection {
    pub nodes: Vec<FavMediaNode>,
    #[serde(rename = "pageInfo")]
    pub page_info: PageInfo,
}

#[derive(Deserialize)]
pub(super) struct FavMediaNode {
    pub id: i64,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
}

#[derive(Deserialize)]
pub(super) struct FavCharacterConnection {
    pub nodes: Vec<FavPersonNode>,
    #[serde(rename = "pageInfo")]
    pub page_info: PageInfo,
}

#[derive(Deserialize)]
pub(super) struct FavStaffConnection {
    pub nodes: Vec<FavPersonNode>,
    #[serde(rename = "pageInfo")]
    pub page_info: PageInfo,
}

#[derive(Deserialize)]
pub(super) struct FavStudioConnection {
    pub nodes: Vec<FavStudioNode>,
    #[serde(rename = "pageInfo")]
    pub page_info: PageInfo,
}

#[derive(Deserialize)]
pub(super) struct FavPersonNode {
    pub id: i64,
    pub name: FavPersonName,
    pub image: Option<FavPersonImage>,
}

#[derive(Deserialize)]
pub(super) struct FavStudioNode {
    pub id: i64,
    pub name: String,
    #[serde(rename = "isAnimationStudio")]
    pub is_animation_studio: bool,
}

#[derive(Deserialize)]
pub(super) struct FavPersonName {
    pub full: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct FavPersonImage {
    pub large: Option<String>,
}

// ─── Character details ────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct CharacterDetailsPayload {
    #[serde(rename = "Character")]
    pub character: CharacterDetailsNode,
}

#[derive(Deserialize)]
pub(super) struct CharacterDetailsNode {
    pub id: i64,
    pub name: CharacterName,
    pub image: Option<FavPersonImage>,
    pub description: Option<String>,
    pub gender: Option<String>,
    pub age: Option<String>,
    #[serde(rename = "dateOfBirth")]
    pub date_of_birth: Option<FuzzyDateNode>,
    pub favourites: Option<i64>,
    pub media: Option<CharacterMediaConnection>,
}

#[derive(Deserialize)]
pub(super) struct CharacterName {
    pub full: Option<String>,
    pub native: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct CharacterMediaConnection {
    pub nodes: Vec<CharacterMediaNode>,
}

#[derive(Deserialize)]
pub(super) struct CharacterMediaNode {
    pub id: i64,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub format: Option<String>,
}

// ─── Staff details ────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct StaffDetailsPayload {
    #[serde(rename = "Staff")]
    pub staff: StaffDetailsNode,
}

#[derive(Deserialize)]
pub(super) struct StaffDetailsNode {
    pub id: i64,
    pub name: StaffName,
    pub image: Option<FavPersonImage>,
    pub description: Option<String>,
    #[serde(rename = "primaryOccupations")]
    pub primary_occupations: Option<Vec<String>>,
    pub gender: Option<String>,
    pub age: Option<i64>,
    #[serde(rename = "dateOfBirth")]
    pub date_of_birth: Option<FuzzyDateNode>,
    #[serde(rename = "dateOfDeath")]
    pub date_of_death: Option<FuzzyDateNode>,
    pub favourites: Option<i64>,
    pub characters: Option<StaffCharacterConnection>,
}

#[derive(Deserialize)]
pub(super) struct StaffName {
    pub full: Option<String>,
    pub native: Option<String>,
}

#[derive(Deserialize)]
pub(super) struct StaffCharacterConnection {
    pub nodes: Vec<FavPersonNode>,
}

// ─── Studio details ───────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct StudioDetailsPayload {
    #[serde(rename = "Studio")]
    pub studio: StudioDetailsNode,
}

#[derive(Deserialize)]
pub(super) struct StudioDetailsNode {
    pub id: i64,
    pub name: String,
    #[serde(rename = "isAnimationStudio")]
    pub is_animation_studio: bool,
    pub favourites: Option<i64>,
    #[serde(rename = "siteUrl")]
    pub site_url: Option<String>,
    pub media: Option<StudioMediaConnection>,
}

#[derive(Deserialize)]
pub(super) struct StudioMediaConnection {
    pub nodes: Vec<StudioMediaNode>,
}

#[derive(Deserialize)]
pub(super) struct StudioMediaNode {
    pub id: i64,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
    pub format: Option<String>,
    pub status: Option<String>,
}

// ─── User profile ─────────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct UserProfilePayload {
    #[serde(rename = "User")]
    pub user: UserProfileNode,
}

#[derive(Deserialize)]
pub(super) struct UserProfileNode {
    pub id: i64,
    pub name: String,
    pub avatar: Option<AvatarNode>,
    #[serde(rename = "bannerImage")]
    pub banner_image: Option<String>,
    pub about: Option<String>,
    #[serde(rename = "isFollowing")]
    pub is_following: Option<bool>,
    #[serde(rename = "isFollower")]
    pub is_follower: Option<bool>,
    pub statistics: Option<UserStatsNode>,
}

#[derive(Deserialize)]
pub(super) struct UserStatsNode {
    pub anime: Option<UserAnimeStats>,
    pub manga: Option<UserMangaStats>,
}

#[derive(Deserialize)]
#[allow(dead_code)]
pub(super) struct UserAnimeStats {
    pub count: i64,
    #[serde(rename = "episodesWatched")]
    pub episodes_watched: Option<i64>,
    #[serde(rename = "minutesWatched")]
    pub minutes_watched: Option<i64>,
    #[serde(rename = "meanScore")]
    pub mean_score: Option<f64>,
}

#[derive(Deserialize)]
#[allow(dead_code)]
pub(super) struct UserMangaStats {
    pub count: i64,
    #[serde(rename = "chaptersRead")]
    pub chapters_read: Option<i64>,
    #[serde(rename = "volumesRead")]
    pub volumes_read: Option<i64>,
    #[serde(rename = "meanScore")]
    pub mean_score: Option<f64>,
}

// ─── People / search ──────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct CharacterSearchPayload {
    #[serde(rename = "Page")]
    pub page: CharacterSearchPage,
}

#[derive(Deserialize)]
pub(super) struct CharacterSearchPage {
    pub characters: Vec<CharacterSearchNode>,
}

#[derive(Deserialize)]
pub(super) struct CharacterSearchNode {
    pub id: i64,
    pub name: CharacterName,
    pub image: Option<FavPersonImage>,
    pub media: Option<CharacterMediaConnection>,
}

#[derive(Deserialize)]
pub(super) struct StaffSearchPayload {
    #[serde(rename = "Page")]
    pub page: StaffSearchPage,
}

#[derive(Deserialize)]
pub(super) struct StaffSearchPage {
    pub staff: Vec<StaffSearchNode>,
}

#[derive(Deserialize)]
pub(super) struct StaffSearchNode {
    pub id: i64,
    pub name: StaffName,
    pub image: Option<FavPersonImage>,
    #[serde(rename = "primaryOccupations")]
    pub primary_occupations: Option<Vec<String>>,
}

#[derive(Deserialize)]
pub(super) struct StudioSearchPayload {
    #[serde(rename = "Page")]
    pub page: StudioSearchPage,
}

#[derive(Deserialize)]
pub(super) struct StudioSearchPage {
    pub studios: Vec<StudioSearchNode>,
}

#[derive(Deserialize)]
pub(super) struct StudioSearchNode {
    pub id: i64,
    pub name: String,
    #[serde(rename = "isAnimationStudio")]
    pub is_animation_studio: bool,
    pub media: Option<StudioMediaConnection>,
}

#[derive(Deserialize)]
pub(super) struct UserSearchPayload {
    #[serde(rename = "Page")]
    pub page: UserSearchPage,
}

#[derive(Deserialize)]
pub(super) struct UserSearchPage {
    pub users: Vec<UserSearchNode>,
}

#[derive(Deserialize)]
pub(super) struct UserSearchNode {
    pub id: i64,
    pub name: String,
    pub avatar: Option<AvatarNode>,
}

// ─── Social features ─────────────────────────────────────────────────────────

#[derive(Deserialize)]
pub(super) struct ToggleFollowPayload {
    #[serde(rename = "ToggleFollow")]
    pub toggle_follow: Option<ToggleFollowNode>,
}

#[derive(Deserialize)]
pub(super) struct ToggleFollowNode {
    #[serde(rename = "isFollowing")]
    pub is_following: Option<bool>,
}

#[derive(Deserialize)]
pub(super) struct FollowUsersPayload {
    #[serde(rename = "Page")]
    pub page: FollowUsersPage,
}

#[derive(Deserialize)]
pub(super) struct FollowUsersPage {
    #[serde(rename = "pageInfo")]
    pub page_info: Option<PageInfo>,
    pub following: Option<Vec<FollowUserNode>>,
    pub followers: Option<Vec<FollowUserNode>>,
}

#[derive(Deserialize)]
pub(super) struct FollowUserNode {
    pub id: i64,
    pub name: String,
    pub avatar: Option<AvatarNode>,
    #[serde(rename = "isFollowing")]
    pub is_following: Option<bool>,
    #[serde(rename = "isFollower")]
    pub is_follower: Option<bool>,
}

#[derive(Deserialize)]
pub(super) struct FollowingActivityPayload {
    #[serde(rename = "Page")]
    pub page: FollowingActivityPage,
}

#[derive(Deserialize)]
pub(super) struct FollowingActivityPage {
    pub activities: Vec<FollowingActivityNode>,
}

#[derive(Deserialize)]
pub(super) struct FollowingActivityNode {
    pub id: i64,
    #[serde(rename = "__typename")]
    pub typename: String,
    #[serde(rename = "createdAt")]
    pub created_at: i64,
    #[serde(rename = "likeCount")]
    pub like_count: Option<i64>,
    #[serde(rename = "replyCount")]
    pub reply_count: Option<i64>,
    #[serde(rename = "isLiked")]
    pub is_liked: Option<bool>,
    pub user: Option<ActivityUserNode>,
    pub messenger: Option<ActivityUserNode>,
    pub text: Option<String>,
    pub message: Option<String>,
    pub status: Option<String>,
    pub progress: Option<String>,
    pub media: Option<ActivityMediaNode>,
    pub replies: Option<Vec<ActivityReplyNode>>,
}

#[derive(Deserialize)]
pub(super) struct ActivityUserNode {
    pub id: i64,
    pub name: String,
    pub avatar: Option<AvatarNode>,
}

#[derive(Deserialize)]
pub(super) struct ActivityMediaNode {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: Option<String>,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
}

#[derive(Deserialize)]
pub(super) struct ActivityReplyNode {
    pub id: i64,
    #[serde(rename = "createdAt")]
    pub created_at: Option<i64>,
    #[serde(rename = "likeCount")]
    pub like_count: Option<i64>,
    #[serde(rename = "isLiked")]
    pub is_liked: Option<bool>,
    pub text: Option<String>,
    pub user: Option<ActivityUserNode>,
}

#[derive(Deserialize)]
pub(super) struct UserMediaListPayload {
    #[serde(rename = "MediaListCollection")]
    pub media_list_collection: Option<RemoteMediaListCollection>,
}

#[derive(Deserialize)]
pub(super) struct RemoteMediaListCollection {
    pub lists: Vec<RemoteMediaList>,
}

#[derive(Deserialize)]
pub(super) struct RemoteMediaList {
    pub entries: Vec<RemoteMediaListEntry>,
}

#[derive(Deserialize)]
pub(super) struct RemoteMediaListEntry {
    pub status: Option<String>,
    pub score: Option<f64>,
    pub progress: Option<i64>,
    #[serde(rename = "progressVolumes")]
    pub progress_volumes: Option<i64>,
    #[serde(rename = "updatedAt")]
    pub updated_at: Option<i64>,
    pub media: Option<RemoteMediaListMedia>,
}

#[derive(Deserialize)]
pub(super) struct RemoteMediaListMedia {
    pub id: i64,
    #[serde(rename = "type")]
    pub media_type: String,
    pub title: MediaTitleNode,
    #[serde(rename = "coverImage")]
    pub cover_image: Option<CoverImageNode>,
}

#[derive(Deserialize)]
pub(super) struct SaveTextActivityPayload {
    #[serde(rename = "SaveTextActivity")]
    pub save_text_activity: SaveTextActivityNode,
}

#[derive(Deserialize)]
pub(super) struct SaveTextActivityNode {
    pub id: i64,
}

#[derive(Deserialize)]
pub(super) struct ToggleLikePayload {
    #[serde(rename = "ToggleLikeV2")]
    pub toggle_like_v2: ToggleLikeNode,
}

#[derive(Deserialize)]
#[allow(dead_code)]
pub(super) struct ToggleLikeNode {
    pub id: i64,
    #[serde(rename = "isLiked")]
    pub is_liked: bool,
    #[serde(rename = "likeCount")]
    pub like_count: Option<i64>,
}

#[derive(Deserialize)]
pub(super) struct SaveActivityReplyPayload {
    #[serde(rename = "SaveActivityReply")]
    pub save_activity_reply: SaveActivityReplyNode,
}

#[derive(Deserialize)]
pub(super) struct SaveActivityReplyNode {
    pub id: i64,
}

#[derive(Deserialize)]
pub(super) struct ToggleFavouritePayload {
    #[serde(rename = "ToggleFavourite")]
    pub toggle_favourite: ToggleFavouriteCollections,
}

#[derive(Deserialize)]
pub(super) struct ToggleFavouriteCollections {
    pub anime: Option<ToggleFavouriteMediaConnection>,
    pub manga: Option<ToggleFavouriteMediaConnection>,
    pub characters: Option<ToggleFavouriteMediaConnection>,
    pub staff: Option<ToggleFavouriteMediaConnection>,
    pub studios: Option<ToggleFavouriteMediaConnection>,
}

#[derive(Deserialize)]
pub(super) struct ToggleFavouriteMediaConnection {
    pub nodes: Option<Vec<ToggleFavouriteMediaNode>>,
}

#[derive(Deserialize)]
pub(super) struct ToggleFavouriteMediaNode {
    pub id: i64,
}
