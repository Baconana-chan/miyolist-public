# Changelog

All notable changes to this project are documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

## [2.1.0] - 2026-08-01

### Added
- **Auto-updater** — checks GitHub Releases once a day (throttled), with a manual "Check for
  updates" button in the About dialog. `UpdateDialog` offers Download & Install (with a real
  progress bar), Remind me later, and Skip this version. Requires a signing keypair configured
  before the first release (`bunx tauri signer generate`; pubkey in `tauri.conf.json`, private
  key in CI secrets).
- **MangaUpdates chapter notifications** — new-chapter alerts for CURRENT/REPEATING manga via
  the MangaUpdates release indexer: automatic title→series linking, per-media mute switch in
  the entry edit modal, Settings section with toggle, "Check now", mapping list, and manual
  re-link when auto-resolution picks the wrong title.
- **Discord Rich Presence** (desktop) — shows "Watching/Reading <title>" when list progress
  changes, with a master toggle in Settings and a per-media privacy override ("Hide from
  Discord") in the entry edit modal.
- **OP/ED theme player** — themes section in `MediaDetailsPanel` (via AnimeThemes.moe):
  OP/ED/IN list with artists and episode ranges, in-panel `<audio>` player, and per-theme
  favourite stars stored locally (`favorite_themes` table).
- **Configurable keyboard shortcuts** — rebindable Alt+1..6 navigation, Ctrl+F search,
  Ctrl+Shift+S sync, F5 refresh, and Escape close, with a click-to-record "Keyboard" section
  in Settings and conflict detection.
- **Window management** — "Always on top" toggle and persistence/restore of window size and
  position across launches.
- **Schema v10** — `discord_hidden` on `notification_overrides` + `favorite_themes` table.

### Changed
- SQLite connections are now pooled instead of re-opened per command call.
- `reqwest` requests carry a `User-Agent` header.
- Version bumped to 2.1.0.

### Fixed
- Re-authorization flow (localhost callback on port 43821).
- SQLite WAL backup integrity.
- Cover-prefetch de-duplication.
- Airing-schedule pagination and the "aired episodes" window.
- `is_dirty` not being set on library JSON import.
- Tray Quick Sync running on the main thread (now off-thread).
- Dead `Volume{...}` expression in `EntryEditModal`.


## [2.0.0] - 2026-04-24

### Added
- Initial Tauri 2 + Preact release of MiyoList.
- OAuth2 authentication with localhost callback and manual fallback flow.
- Local-first SQLite data layer with offline queue and sync to AniList.
- Library management for Anime, Manga, and Light Novel lists.
- Entry editing with status, score, progress, notes, dates, repeat count, volume progress, and delete support.
- Global search for media and people, including advanced media filters.
- Media details panel with rich metadata, markdown description, relations, recommendations, cast/staff, and external links.
- Airing schedule view for tracked anime with progress controls and native notifications.
- Statistics dashboard with totals, score distribution, genre/format breakdowns, annual summary, and activity heatmap.
- Social integrations: following/followers, following activity feed, posting activity, and read-only user list browsing.
- Global discovery/activity surfaces with trending and global feed support.
- Cover image cache with prefetching, cache stats, and clear actions.
- System tray integration with quick actions and minimize-to-tray behavior.
- Desktop keyboard shortcuts for navigation and common actions.
- About dialog and settings surfaces for application preferences.

### Changed
- Improved sync flow with conflict detection, conflict resolution paths, partial sync support, and sync event logging.
- Improved offline behavior for network-dependent commands and background refresh.
- Added score-format awareness across UI and data operations.
- Added custom list handling in edit flows and AniList sync payloads.

### Notes
- Supported platforms: Windows, Linux, macOS, and Android.
- Desktop release artifacts are built via the Tauri build workflow; CI performs validation checks across multiple platforms.
