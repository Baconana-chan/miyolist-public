export type ScreenId =
  | "overview"
  | "auth"
  | "library"
  | "activity"
  | "discovery"
  | "notifications"
  | "search"
  | "schedule"
  | "settings"
  | "statistics";

export type ModuleStatus = "ready" | "planned" | "research";

export interface FoundationModule {
  name: string;
  summary: string;
  status: ModuleStatus;
}

export interface BootstrapPayload {
  productName: string;
  appVersion: string;
  primaryPlatform: string;
  supportedTargets: string[];
  guarantees: string[];
  authStrategy: string[];
  foundationModules: FoundationModule[];
}

export interface DatabaseTableInfo {
  name: string;
  exists: boolean;
  rowCount: number;
}

export interface DatabaseOverview {
  databasePath: string;
  schemaVersion: number;
  tableCount: number;
  tables: DatabaseTableInfo[];
}

export interface DatabaseInitResult {
  databasePath: string;
  schemaVersion: number;
  createdNow: boolean;
  migrationApplied: boolean;
}

export interface AuthRequestPlan {
  authUrl: string;
  redirectUri: string;
  callbackHost: string;
  callbackPort: number;
  callbackPath: string;
  state: string;
  responseType: string;
  usesWebsiteBridge: boolean;
  notes: string[];
}

export interface AniListConfigStatus {
  clientIdConfigured: boolean;
  clientSecretConfigured: boolean;
  authUrl: string;
  tokenUrl: string;
  graphqlUrl: string;
  usesEnvFile: boolean;
  missingVars: string[];
}

export interface AniListViewer {
  id: number;
  name: string;
  avatarUrl: string | null;
  scoreFormat: string;
  animeCustomLists: string[];
  mangaCustomLists: string[];
}

export interface AuthSessionStatus {
  hasAccessToken: boolean;
  viewerId: number | null;
  viewerName: string | null;
  viewerAvatarUrl: string | null;
  tokenExpiresAt: string | null;
  isTokenExpired: boolean;
  updatedAt: string | null;
}

export interface LibrarySnapshot {
  totalEntries: number;
  animeEntries: number;
  mangaEntries: number;
  currentEntries: number;
  plannedEntries: number;
  completedEntries: number;
  cachedMedia: number;
  searchHistoryCount: number;
  profileName: string | null;
  profileAvatarUrl: string | null;
  hasAccessToken: boolean;
}

export interface ListEntry {
  localId: number;
  /** AniList server-side MediaList.id; null until first sync. */
  anilistEntryId: number | null;
  mediaId: number;
  mediaType: string;
  listKind: string;
  title: string;
  coverImage: string | null;
  status: string;
  score: number | null;
  /** Episodes watched (anime) or chapters read (manga/LN). */
  progress: number;
  /** Volumes read — manga/LN only; 0 for anime. */
  progressVolumes: number;
  episodesOrChapters: number | null;
  repeatCount: number;
  notes: string | null;
  startedAt: string | null;
  completedAt: string | null;
  customLists: string[];
  updatedAt: string;
  isDirty: boolean;
}

export interface MediaSearchResult {
  mediaId: number;
  mediaType: string;
  title: string;
  coverImage: string | null;
  format: string | null;
  status: string | null;
  episodes: number | null;
  chapters: number | null;
  genres: string[];
  averageScore: number | null;
  isAdult: boolean;
  inLibrary: boolean;
}

export interface SyncSummary {
  /** Entries pulled from AniList into local DB. */
  synced: number;
  /** Dirty local entries successfully pushed to AniList. */
  pushed: number;
  /** Entries that failed to push. */
  failed: number;
  /** Entries where both local and remote changed since last sync. */
  conflicts: number;
  /** Whether this sync used the delta (partial) pull path. */
  isDelta: boolean;
  /** ISO-8601 UTC timestamp when this sync completed. */
  lastSyncedAt: string;
}

/**
 * Live snapshot of an in-flight sync so the UI can render real progress
 * ("Syncing 250/2500") instead of an opaque spinner on long pulls.
 * Polled from the frontend every ~1s while a sync command is awaiting.
 */
export interface SyncProgress {
  active: boolean;
  phase: string;
  page: number;
  entries: number;
  totalEntries: number;
  message: string;
}

export interface SyncLogEntry {
  id: number;
  mediaId: number;
  mediaTitle: string | null;
  /** `"pulled"` | `"pushed"` | `"conflict"` | `"skipped"` */
  syncType: string;
  detail: string | null;
  createdAt: string;
}

export interface PendingConflict {
  mediaId: number;
  mediaType: string;
  mediaTitle: string | null;
  /** Current value on this device (dirty). */
  localStatus: string | null;
  localScore: number | null;
  localProgress: number;
  localNotes: string | null;
  /** Incoming AniList value that was not applied. */
  remoteStatus: string | null;
  remoteScore: number | null;
  remoteProgress: number;
  remoteNotes: string | null;
  detectedAt: string;
}

export interface MediaTag {
  name: string;
  category: string | null;
  rank: number | null;
  isSpoiler: boolean;
}

export interface MediaStudio {
  id: number;
  name: string;
  isAnimationStudio: boolean;
}

export interface MediaRelation {
  mediaId: number;
  mediaType: string | null;
  format: string | null;
  title: string;
  coverImage: string | null;
  status: string | null;
  relationType: string;
}

export interface MediaCharacterEdge {
  characterId: number;
  name: string;
  image: string | null;
  role: string;
}

export interface MediaStaffEdge {
  staffId: number;
  name: string;
  image: string | null;
  role: string;
}

export interface AiringInfo {
  episode: number;
  airingAt: number;
}

export interface MediaDetails {
  mediaId: number;
  mediaType: string;
  format: string | null;
  status: string | null;
  titleRomaji: string | null;
  titleEnglish: string | null;
  titleNative: string | null;
  description: string | null;
  coverImage: string | null;
  bannerImage: string | null;
  episodes: number | null;
  chapters: number | null;
  volumes: number | null;
  duration: number | null;
  season: string | null;
  seasonYear: number | null;
  source: string | null;
  genres: string[];
  tags: MediaTag[];
  averageScore: number | null;
  popularity: number | null;
  favourites: number | null;
  isAdult: boolean;
  studios: MediaStudio[];
  nextAiringEpisode: AiringInfo | null;
  startDate: string | null;
  endDate: string | null;
  cachedAt: string;
  inLibrary: boolean;
  relations: MediaRelation[];
  characters: MediaCharacterEdge[];
  staff: MediaStaffEdge[];
  recommendations: MediaRecommendation[];
  externalLinks: ExternalLink[];
}

export interface MediaRecommendation {
  mediaId: number;
  format: string | null;
  title: string;
  coverImage: string | null;
  meanScore: number | null;
  rating: number;
}

export interface ExternalLink {
  url: string;
  site: string;
  linkType: string;
}

export interface AiringEntry {
  mediaId: number;
  title: string;
  coverImage: string | null;
  episode: number;
  /** Unix timestamp (seconds) when this episode airs / aired. */
  airingAt: number;
  notified: boolean;
  userProgress: number;
  listStatus: string;
  score: number | null;
  totalEpisodes: number | null;
}

export interface GlobalAiringEntry {
  mediaId: number;
  title: string;
  coverImage: string | null;
  episode: number;
  /** Unix timestamp (seconds) when this episode airs. */
  airingAt: number;
  format: string | null;
  popularity: number | null;
}

export interface NotificationSettings {
  airingEnabled: boolean;
  activityEnabled: boolean;
  forumEnabled: boolean;
  followsEnabled: boolean;
  mediaEnabled: boolean;
  submissionsEnabled: boolean;
}

export interface NotificationOverride {
  mediaId: number;
  enabled: boolean;
}

export interface AniListNotificationItem {
  id: number;
  notificationType: string;
  createdAt: number;
  isRead: boolean;
  title: string;
  body: string;
  link: string | null;
  mediaId: number | null;
  coverImage: string | null;
  userName: string | null;
  userAvatar: string | null;
}

// ─── Statistics ───────────────────────────────────────────────────────────────

export interface ScoreBucket {
  score: number;
  count: number;
}

export interface BreakdownItem {
  label: string;
  count: number;
}

export interface LibraryStats {
  totalEntries: number;
  totalAnime: number;
  totalManga: number;
  totalNovels: number;

  countCurrent: number;
  countCompleted: number;
  countPlanning: number;
  countDropped: number;
  countPaused: number;
  countRepeating: number;

  episodesWatched: number;
  chaptersRead: number;
  volumesRead: number;
  estimatedMinutes: number;

  meanScore: number | null;
  scoreDistribution: ScoreBucket[];

  formatBreakdown: BreakdownItem[];
  genreBreakdown: BreakdownItem[];
}

export interface ActivityEntry {
  id: number;
  mediaId: number;
  mediaType: string;
  title: string;
  coverImage: string | null;
  activityType: string;
  oldValue: string | null;
  newValue: string | null;
  note: string | null;
  createdAt: string;
}

export interface HeatmapDay {
  date: string;
  count: number;
}

export interface MonthlyActivityCount {
  month: number;
  episodes: number;
  chapters: number;
}

export interface AnnualWrapUp {
  year: number;
  daysActive: number;
  listUpdates: number;
  completedAnime: number;
  episodesWatched: number;
  chaptersRead: number;
  meanScore: number | null;
  topGenres: BreakdownItem[];
  topStudio: string | null;
  mostWatchedWeekday: string | null;
  firstCompletedTitle: string | null;
  lastCompletedTitle: string | null;
}

// ─── App settings ─────────────────────────────────────────────────────────────

export interface AppSettings {
  showAdultContent: boolean;
  /** `"ANIME"` | `"MANGA"` | `"NOVEL"` */
  defaultListTab: string;
  /** `"updated_desc"` | `"title_asc"` | `"score_desc"` | `"progress_desc"` */
  defaultSort: string;
  /** `"list"` | `"compact"` | `"grid"` */
  libraryView: string;
  /** `"list"` | `"card"` */
  scheduleView: string;
  /** Comma-separated statuses to hide from the library, e.g. `"DROPPED,PAUSED"` */
  hiddenStatuses: string;
  /** Background auto-sync interval in minutes; 0 = disabled. */
  autoSyncInterval: number;
  /** ISO-8601 UTC timestamp of the last completed sync; null if never. */
  lastSyncedAt: string | null;
  /** AniList score format preference (`POINT_100`, `POINT_10_DECIMAL`, ...). */
  scoreFormat: string;
  /** When enabled, closing the main window hides the app to system tray instead of exiting. */
  minimizeToTrayOnClose: boolean;
}

export interface CacheStats {
  mediaCacheCount: number;
  searchHistoryCount: number;
  airingCacheCount: number;
  activityLogCount: number;
  imageCacheCount: number;
  imageCacheBytes: number;
}

export interface ExportResult {
  path: string;
  entryCount: number;
}

export interface ImportResult {
  importedCount: number;
  skippedCount: number;
  errors: string[];
}

// ─── Favourites ───────────────────────────────────────────────────────────────

export interface FavoriteMedia {
  id: number;
  title: string;
  coverImage: string | null;
}

export interface FavoritePerson {
  id: number;
  name: string;
  image: string | null;
}

export interface FavoriteStudio {
  id: number;
  name: string;
  isAnimationStudio: boolean;
}

export interface UserFavorites {
  anime: FavoriteMedia[];
  manga: FavoriteMedia[];
  characters: FavoritePerson[];
  staff: FavoritePerson[];
  studios: FavoriteStudio[];
}

// ─── People / public detail pages ────────────────────────────────────────────

export interface CharacterMedia {
  id: number;
  title: string;
  coverImage: string | null;
  format: string | null;
}

export interface CharacterDetails {
  id: number;
  nameFull: string | null;
  nameNative: string | null;
  image: string | null;
  description: string | null;
  gender: string | null;
  age: string | null;
  dateOfBirth: string | null;
  favourites: number | null;
  media: CharacterMedia[];
}

export interface StaffCharacter {
  id: number;
  name: string;
  image: string | null;
}

export interface StaffDetails {
  id: number;
  nameFull: string | null;
  nameNative: string | null;
  image: string | null;
  description: string | null;
  primaryOccupations: string[];
  gender: string | null;
  age: number | null;
  dateOfBirth: string | null;
  dateOfDeath: string | null;
  favourites: number | null;
  characters: StaffCharacter[];
}

export interface StudioMedia {
  id: number;
  title: string;
  coverImage: string | null;
  format: string | null;
  status: string | null;
}

export interface StudioDetails {
  id: number;
  name: string;
  isAnimationStudio: boolean;
  favourites: number | null;
  siteUrl: string | null;
  media: StudioMedia[];
}

export interface UserProfileStats {
  animeCount: number;
  episodesWatched: number;
  animeMeanScore: number | null;
  mangaCount: number;
  chaptersRead: number;
  mangaMeanScore: number | null;
}

export interface UserProfile {
  id: number;
  name: string;
  avatarUrl: string | null;
  bannerUrl: string | null;
  about: string | null;
  isFollowing: boolean;
  isFollower: boolean;
  followersCount: number;
  followingCount: number;
  stats: UserProfileStats | null;
}

export interface SocialUser {
  id: number;
  name: string;
  avatarUrl: string | null;
  isFollowing: boolean;
  isFollower: boolean;
}

export interface FollowingActivityItem {
  id: number;
  activityType: string;
  createdAt: number;
  likeCount: number;
  replyCount: number;
  isLiked: boolean;
  isMessage: boolean;
  userId: number;
  userName: string;
  userAvatar: string | null;
  text: string | null;
  status: string | null;
  progress: string | null;
  mediaId: number | null;
  mediaTitle: string | null;
  mediaCoverImage: string | null;
  replies: ActivityReplyItem[];
}

export interface ActivityReplyItem {
  id: number;
  createdAt: number;
  likeCount: number;
  isLiked: boolean;
  userId: number;
  userName: string;
  userAvatar: string | null;
  text: string | null;
}

export interface UserMediaListItem {
  mediaId: number;
  mediaType: string;
  title: string;
  coverImage: string | null;
  status: string;
  score: number | null;
  progress: number;
  progressVolumes: number;
  updatedAt: number;
}

// ─── People / search results ─────────────────────────────────────────────────

export interface PersonSearchResult {
  id: number;
  /** `"CHARACTER"` or `"STAFF"` */
  kind: string;
  name: string;
  image: string | null;
  /** First media title (character) or primary occupation (staff). */
  sub: string | null;
}

export interface StudioSearchResult {
  id: number;
  name: string;
  isAnimationStudio: boolean;
  recentTitle: string | null;
}

export interface UserSearchResult {
  id: number;
  name: string;
  avatarUrl: string | null;
}

export interface NavigationItem {
  id: ScreenId;
  label: string;
  eyebrow: string;
  summary: string;
}

export interface DetailPoint {
  title: string;
  description: string;
}