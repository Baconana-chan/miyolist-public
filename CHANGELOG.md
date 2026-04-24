# Changelog

All notable changes to this project are documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]



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
