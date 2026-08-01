import { invoke } from "@tauri-apps/api/core";
import type {
  AniListNotificationItem,
  ActivityEntry,
  AnnualWrapUp,
  AiringEntry,
  AppSettings,
  AuthSessionStatus,
  CacheStats,
  CharacterDetails,
  DatabaseInitResult,
  DatabaseOverview,
  ExportResult,
  FavoriteTheme,
  FollowingActivityItem,
  GlobalAiringEntry,
  HeatmapDay,
  ImportResult,
  LibrarySnapshot,
  LibraryStats,
  ListEntry,
  MangaReleaseMapping,
  MangaUpdatesSeries,
  MediaDetails,
  MediaSearchResult,
  MediaTheme,
  MonthlyActivityCount,
  NotificationOverride,
  NotificationSettings,
  PendingConflict,
  PersonSearchResult,
  SocialUser,
  StaffDetails,
  StudioDetails,
  StudioSearchResult,
  SyncLogEntry,
  SyncProgress,
  SyncSummary,
  ThemeAnime,
  UpdateInfo,
  UserFavorites,
  UserMediaListItem,
  UserProfile,
  UserSearchResult,
} from "../types/app";

import {
  getOnlineStatus,
  initializeOnlineStatus,
} from "../network/onlineStatus";

const OFFLINE_ERROR_PREFIX = "[OFFLINE]";

const EMPTY_SYNC_SUMMARY: SyncSummary = {
  synced: 0,
  pushed: 0,
  failed: 0,
  conflicts: 0,
  isDelta: false,
  lastSyncedAt: "",
};

const EMPTY_FAVORITES: UserFavorites = {
  anime: [],
  manga: [],
  characters: [],
  staff: [],
  studios: [],
};

function isLikelyNetworkError(error: unknown) {
  const message = String(error ?? "").toUpperCase();
  return (
    message.includes("NETWORK_ERROR")
    || message.includes("HTTP_ERROR")
    || message.includes("FAILED TO FETCH")
    || message.includes("TIMED OUT")
    || message.includes("ECONN")
    || message.includes("ENOTFOUND")
  );
}

/**
 * Fire-and-forget global toast.  AppShell listens for "miyolist:toast" and
 * renders it as a transient bottom bar.
 */
function notifyToast(text: string, kind: "warn" | "ok" | "err" = "warn") {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent("miyolist:toast", { detail: { text, kind } }));
}

async function invokeRemote<T>(
  command: string,
  args?: Record<string, unknown>,
  offlineFallback?: T | (() => T),
): Promise<T> {
  initializeOnlineStatus();

  if (!getOnlineStatus()) {
    if (offlineFallback !== undefined) {
      return typeof offlineFallback === "function"
        ? (offlineFallback as () => T)()
        : offlineFallback;
    }
    throw new Error(`${OFFLINE_ERROR_PREFIX} No network connection`);
  }

  try {
    return await invoke<T>(command, args);
  } catch (error) {
    if (offlineFallback !== undefined && isLikelyNetworkError(error)) {
      return typeof offlineFallback === "function"
        ? (offlineFallback as () => T)()
        : offlineFallback;
    }
    throw error;
  }
}

export function initializeDatabase() {
  return invoke<DatabaseInitResult>("initialize_database");
}

export function getDatabaseOverview() {
  return invoke<DatabaseOverview>("get_database_overview");
}

export function getLibrarySnapshot() {
  return invoke<LibrarySnapshot>("get_library_snapshot");
}

export function getListEntries(mediaType?: string, status?: string) {
  return invoke<ListEntry[]>("get_list_entries", {
    mediaType: mediaType ?? null,
    status: status ?? null,
  });
}

export function getListEntryByMediaId(mediaId: number) {
  return invoke<ListEntry | null>("get_list_entry_by_media_id", { mediaId });
}

export function syncUserLists() {
  return invokeRemote<SyncSummary>("sync_user_lists");
}

export function getSyncProgress() {
  return invoke<SyncProgress>("get_sync_progress");
}

export function pushDirtyEntries() {
  return invokeRemote<SyncSummary>("push_dirty_entries", undefined, EMPTY_SYNC_SUMMARY);
}

export function getSyncLog(limit = 100) {
  return invoke<SyncLogEntry[]>("get_sync_log", { limit });
}

export function getPendingConflicts() {
  return invoke<PendingConflict[]>("get_pending_conflicts");
}

export function resolveConflict(mediaId: number, useRemote: boolean) {
  return invoke<void>("resolve_conflict", { mediaId, useRemote });
}

export function updateListEntry(
  localId: number,
  mediaId: number,
  status: string,
  score: number | null,
  progress: number,
  progressVolumes: number,
  repeatCount: number,
  startDate: string | null,
  completedDate: string | null,
  notes: string | null,
  customLists: string[] | null,
) {
  // The command returns a warning string when the local save succeeded but
  // the AniList push failed (retried on the next sync).
  return invoke<string | null>("update_list_entry", {
    localId, mediaId, status, score, progress,
    progressVolumes, repeatCount, startDate, completedDate, notes, customLists,
  }).then((warning) => {
    if (warning) notifyToast(warning);
  });
}

export function deleteListEntry(localId: number, anilistEntryId: number | null) {
  return invoke<string | null>("delete_list_entry", { localId, anilistEntryId }).then((warning) => {
    if (warning) notifyToast(warning);
  });
}

export function searchMedia(
  query: string,
  mediaType: string,
  filters?: {
    genresIn?: string[] | null;
    genresNotIn?: string[] | null;
    tagsIn?: string[] | null;
    tagsNotIn?: string[] | null;
    formatIn?: string[] | null;
    statusFilter?: string | null;
    sort?: string | null;
    yearGreater?: number | null;
    yearLesser?: number | null;
    minimumTagRank?: number | null;
    isAdult?: boolean | null;
  },
) {
  return invokeRemote<MediaSearchResult[]>("search_media", {
    query,
    mediaType,
    genresIn:       filters?.genresIn       ?? null,
    genresNotIn:    filters?.genresNotIn    ?? null,
    tagsIn:         filters?.tagsIn         ?? null,
    tagsNotIn:      filters?.tagsNotIn      ?? null,
    formatIn:       filters?.formatIn       ?? null,
    statusFilter:   filters?.statusFilter   ?? null,
    sort:           filters?.sort           ?? null,
    yearGreater:    filters?.yearGreater    ?? null,
    yearLesser:     filters?.yearLesser     ?? null,
    minimumTagRank: filters?.minimumTagRank ?? null,
    isAdult:        filters?.isAdult        ?? null,
  }, []);
}

export function getTrendingMedia(page = 1) {
  return invokeRemote<MediaSearchResult[]>("get_trending_media", { page }, []);
}

export function addToLibrary(
  mediaId: number,
  mediaType: string,
  status: string,
  title: string | null,
  coverImage: string | null,
) {
  return invoke<string | null>("add_to_library", { mediaId, mediaType, status, title, coverImage }).then((warning) => {
    if (warning) notifyToast(warning);
  });
}

export function getMediaDetails(mediaId: number) {
  return invoke<MediaDetails>("get_media_details", { mediaId });
}

export function getAuthCallbackStatus() {
  return invoke<string>("get_auth_callback_status");
}

export function reopenAuthBrowser(authUrl: string) {
  return invoke<void>("reopen_auth_browser", { authUrl });
}

export function submitAuthCodeManually(code: string) {
  return invoke<AuthSessionStatus>("submit_auth_code_manually", { code });
}

export function getAuthSessionStatus() {
  return invoke<AuthSessionStatus>("get_auth_session_status");
}

// ─── Schedule and notifications ────────────────────────────────────────────────────

export function getAiringSchedule() {
  return invoke<AiringEntry[]>("get_airing_schedule");
}

export function getGlobalAiringSchedule(weekday?: number) {
  return invokeRemote<GlobalAiringEntry[]>("get_global_airing_schedule", {
    weekday: weekday ?? null,
  }, []);
}

/** Fetches fresh data from AniList, then fires any pending notifications. */
export function refreshAiringSchedule() {
  return invokeRemote<number>("refresh_airing_schedule", undefined, 0);
}

/** Check cached airing data and fire OS notifications for newly aired episodes. */
export function checkNotifications() {
  return invoke<number>("check_notifications");
}

export function getNotificationSettings() {
  return invoke<NotificationSettings>("get_notification_settings");
}

export function saveNotificationSettings(settings: NotificationSettings) {
  return invoke<void>("save_notification_settings", { settings });
}

export function getNotificationOverrides(mediaIds: number[]) {
  return invoke<NotificationOverride[]>("get_notification_overrides", { mediaIds });
}

export function setNotificationOverride(mediaId: number, enabled: boolean) {
  return invoke<void>("set_notification_override", { mediaId, enabled });
}

/** Hides (or un-hides) a media title from the Discord Rich Presence (desktop). */
export function setDiscordHidden(mediaId: number, hidden: boolean) {
  return invoke<void>("set_discord_hidden", { mediaId, hidden });
}

// ─── Auto-updater ─────────────────────────────────────────────────────────────

/**
 * Checks GitHub Releases for a newer version.  `force` bypasses the 24 h
 * throttle (manual "Check for updates" from About); a user-skipped version is
 * still respected.  Resolves to the available update, or null when up to date.
 */
export function checkForUpdates(force = false) {
  return invoke<UpdateInfo | null>("check_for_updates", { force });
}

/** Downloads + installs the latest release, then restarts the app. */
export function installUpdate() {
  return invoke<void>("install_update");
}

/** Remembers a version the user asked to skip so it stops being offered. */
export function skipUpdateVersion(version: string) {
  return invoke<void>("skip_update_version", { version });
}

// ─── MangaUpdates release tracking ───────────────────────────────────────────

/** Search MangaUpdates by title (public API, no auth). */
export function searchMangaupdatesSeries(query: string) {
  return invoke<MangaUpdatesSeries[]>("search_mangaupdates_series", { query });
}

/** All stored AniList→MangaUpdates links (for the Settings UI). */
export function getMangaReleaseMappings() {
  return invoke<MangaReleaseMapping[]>("get_manga_release_mappings");
}

/** Manually (re)link a manga entry to a MangaUpdates series. */
export function setMangaReleaseMapping(mediaId: number, muSeriesId: number, muTitle: string) {
  return invoke<void>("set_manga_release_mapping", { mediaId, muSeriesId, muTitle });
}

/** Remove a MangaUpdates link (stops tracking that entry). */
export function clearMangaReleaseMapping(mediaId: number) {
  return invoke<void>("clear_manga_release_mapping", { mediaId });
}

/** Poll tracked manga now; resolves to the number of notifications sent. */
export function checkMangaReleases() {
  return invoke<number>("check_manga_releases");
}

export function getAniListNotifications(
  typeFilter?: string | null,
  page = 1,
  perPage = 50,
  resetUnreadCount = false,
) {
  return invokeRemote<AniListNotificationItem[]>("get_anilist_notifications", {
    typeFilter: typeFilter ?? null,
    page,
    perPage,
    resetUnreadCount,
  }, []);
}

/** Increment (+1) or decrement (-1) episode progress directly from the schedule. */
export function incrementEpisodeProgress(mediaId: number, delta: number) {
  return invoke<number>("increment_episode_progress", { mediaId, delta });
}

// ─── Statistics ────────────────────────────────────────────────────────────────

/** Derived statistics built from local library data. */
export function getLibraryStats() {
  return invoke<LibraryStats>("get_library_stats");
}

/** Most-recent activity log entries. */
export function getActivityLog(limit?: number) {
  return invoke<ActivityEntry[]>("get_activity_log", { limit: limit ?? null });
}

/** Per-day activity counts for the heatmap (selected year). */
export function getActivityHeatmap(year?: number) {
  return invoke<HeatmapDay[]>("get_activity_heatmap", { year: year ?? null });
}

/** Activity entries for a specific date (`YYYY-MM-DD`). */
export function getActivityLogByDate(date: string, limit?: number) {
  return invoke<ActivityEntry[]>("get_activity_log_by_date", { date, limit: limit ?? null });
}

/** Per-month episode/chapter totals for progress updates in a selected year. */
export function getActivityMonthlyTotals(year: number) {
  return invoke<MonthlyActivityCount[]>("get_activity_monthly_totals", { year });
}

/** Year-in-review aggregate metrics for the selected year. */
export function getAnnualWrapUp(year: number) {
  return invoke<AnnualWrapUp>("get_annual_wrap_up", { year });
}

// ─── App settings ──────────────────────────────────────────────────────────────

export function getAppSettings() {
  return invoke<AppSettings>("get_app_settings");
}

export function saveAppSettings(settings: AppSettings) {
  return invoke<void>("save_app_settings", { settings }).then(() => {
    // Let the shell re-read settings (e.g. the auto-sync interval) so changes
    // apply immediately without an app restart.
    if (typeof window !== "undefined") {
      window.dispatchEvent(new CustomEvent("miyolist:settings-changed"));
    }
  });
}

/** Toggle the main window's "always on top" state and persist the preference. */
export function setAlwaysOnTop(enabled: boolean) {
  return invoke<void>("set_always_on_top", { enabled });
}

/** Toggle Discord Rich Presence and persist the preference (desktop only). */
export function setDiscordRpc(enabled: boolean) {
  return invoke<void>("set_discord_rpc", { enabled });
}

// ─── Cache management ──────────────────────────────────────────────────────────

export function getCacheStats() {
  return invoke<CacheStats>("get_cache_stats");
}

export function clearSearchHistory() {
  return invoke<void>("clear_search_history");
}

export function clearOrphanMediaCache() {
  return invoke<number>("clear_orphan_media_cache");
}

export function clearAiringCache() {
  return invoke<void>("clear_airing_cache");
}

export function clearImageCache() {
  return invoke<number>("clear_image_cache");
}

export function prefetchCovers() {
  return invokeRemote<void>("prefetch_covers", undefined, () => undefined);
}

// ─── AnimeThemes.moe (OP/ED) ─────────────────────────────────────────────────

/** Search AnimeThemes.moe by anime title; returns matches with their OP/ED list. */
export function searchThemes(query: string) {
  return invoke<ThemeAnime[]>("search_themes", { query });
}

/** Fetch OP/ED themes for a media entry by its locally cached title. */
export function getThemesForMedia(mediaId: number) {
  return invoke<MediaTheme[]>("get_themes_for_media", { mediaId });
}

/** All OP/ED themes the user starred for a media entry (local favourites). */
export function getFavoriteThemes(mediaId: number) {
  return invoke<FavoriteTheme[]>("get_favorite_themes", { mediaId });
}

/** Adds/removes a theme to/from the media's favourites. Resolves to the new state. */
export function toggleFavoriteTheme(
  mediaId: number,
  themeId: number,
  themeType: string,
  songTitle: string,
  artists: string[],
) {
  return invoke<boolean>("toggle_favorite_theme", {
    mediaId,
    themeId,
    themeType,
    songTitle,
    artists,
  });
}

export function getCachedImagePath(url: string) {
  return invoke<string | null>("get_cached_image_path", { url });
}

// ─── Backup / export / import ─────────────────────────────────────────────────

/** Exports all library entries as a JSON file and returns the file path. */
export function exportLibraryJson() {
  return invoke<ExportResult>("export_library_json");
}

/** Copies the SQLite database to the exports folder and returns the file path. */
export function exportDatabaseBackup() {
  return invoke<ExportResult>("export_database_backup");
}

/** Imports library entries from a JSON file produced by exportLibraryJson. */
export function importLibraryJson(path: string) {
  return invoke<ImportResult>("import_library_json", { path });
}

// ─── Favourites ───────────────────────────────────────────────────────────────

/** Fetches the authenticated user's favourites from AniList (all pages). */
export function getFavorites() {
  return invokeRemote<UserFavorites>("get_favorites", undefined, EMPTY_FAVORITES);
}

export function toggleMediaFavorite(mediaId: number, mediaType: "ANIME" | "MANGA") {
  return invokeRemote<boolean>("toggle_media_favorite", { mediaId, mediaType });
}

export function toggleFavorite(targetId: number, targetType: "ANIME" | "MANGA" | "CHARACTER" | "STAFF" | "STUDIO") {
  return invokeRemote<boolean>("toggle_favorite", { targetId, targetType });
}

// ─── Public detail pages ──────────────────────────────────────────────────────

export function getCharacterDetails(id: number) {
  return invoke<CharacterDetails>("get_character_details", { id });
}

export function getStaffDetails(id: number) {
  return invoke<StaffDetails>("get_staff_details", { id });
}

export function getStudioDetails(id: number) {
  return invoke<StudioDetails>("get_studio_details", { id });
}

export function getUserProfile(name: string) {
  return invoke<UserProfile>("get_user_profile", { name });
}

// ─── People / search ──────────────────────────────────────────────────────────

export function searchCharacters(query: string) {
  return invokeRemote<PersonSearchResult[]>("search_characters", { query }, []);
}

export function searchStaff(query: string) {
  return invokeRemote<PersonSearchResult[]>("search_staff", { query }, []);
}

export function searchStudios(query: string) {
  return invokeRemote<StudioSearchResult[]>("search_studios", { query }, []);
}

export function searchUsers(query: string) {
  return invokeRemote<UserSearchResult[]>("search_users", { query }, []);
}

// ─── Social ──────────────────────────────────────────────────────────────────

export function toggleFollow(userId: number, follow: boolean) {
  return invokeRemote<boolean>("toggle_follow", { userId, follow });
}

export function getFollowing(userId: number, page = 1) {
  return invokeRemote<SocialUser[]>("get_following", { userId, page }, []);
}

export function getFollowers(userId: number, page = 1) {
  return invokeRemote<SocialUser[]>("get_followers", { userId, page }, []);
}

export function getFollowingActivity(page = 1, perPage = 25) {
  return invokeRemote<FollowingActivityItem[]>("get_following_activity", { page, perPage }, []);
}

export function getGlobalActivity(page = 1, perPage = 25) {
  return invokeRemote<FollowingActivityItem[]>("get_global_activity", { page, perPage }, []);
}

export function toggleActivityLike(activityId: number) {
  return invokeRemote<boolean>("toggle_activity_like", { activityId });
}

export function saveActivityReply(activityId: number, text: string) {
  return invokeRemote<number>("save_activity_reply", { activityId, text });
}

export function getUserMediaList(userId: number, mediaType: "ANIME" | "MANGA") {
  return invokeRemote<UserMediaListItem[]>("get_user_media_list", { userId, mediaType }, []);
}

export function postActivity(text: string) {
  return invokeRemote<number>("post_activity", { text });
}