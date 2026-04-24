# MiyoList Tauri — Active Development TODO

> **Status as of current session.** All 8 migration phases from `MIGRATION_TODO.md` are complete.
> This file tracks remaining unimplemented features (from Flutter reference app + new ideas)
> and Tauri-desktop-specific features that have no Flutter equivalent.
>
> Priority: `[P0]` critical · `[P1]` high · `[P2]` medium · `[P3]` low/future · `[P4]` ambitious · `[P5]` moonshot

---

## ✅ Already Implemented (reference baseline)

- OAuth2 authentication with localhost callback + manual fallback
- Library: Anime / Manga / Light Novel, status filters, sort, 3 view modes
- Entry edit modal (status, score, progress, notes)
- Library sync (pull from AniList, push dirty entries)
- Global search: media + people (Characters, Staff, Studios, Users)
- Advanced media search (genres, tags, year range, format, status, adult filter)
- MediaDetailsPanel: banner, cover, all titles, description (AniList Markdown V2), genres, tags, studios, airing countdown, dates, score/popularity
- AnilistMarkdown component (links, bold, italic, strikethrough, spoilers)
- Airing schedule (user's watching anime, grouped by day, +/− progress)
- OS notifications on airing refresh + notification settings
- Statistics: totals, status bar, score histogram, format/genre bars, 52-week activity heatmap
- Activity log (last 100 entries, relative timestamps)
- Settings: adult content filter, library defaults, cache manager, backup/export/import
- Offline cover cache + prefetch + per-table clear
- Character / Staff / Studio / User detail panels
- Favorites with clickable tiles (Character, Staff, Studio, Anime, Manga)
- Public people search in SearchSurface

---

## 🔴 P0 — Core Completions

### Entry Edit Modal — missing fields

**File:** `src/shared/components/EntryEditModal.tsx`

Current modal has status, score, progress (chapters), notes. Still missing:

- [x] **Volume progress** — add a second progress field for manga/LN (current volumes read)
- [x] **Start date / Finish date** — optional date pickers; pass to `update_list_entry`
- [x] **Rewatches / Rereads counter** — integer field; display in library card
- [x] **Delete entry** — red "Remove from library" button with confirmation; needs a `delete_list_entry` Tauri command that removes locally and calls AniList `DeleteMediaListEntry` mutation

Rust side (`commands/mod.rs`, `anilist/mod.rs`):
- Add `delete_list_entry(local_id: i64, anilist_entry_id: Option<i64>) -> Result<()>`
- Extend `update_list_entry` to accept `start_date`, `completed_date`, `repeat` fields
- Extend `media_list_entries` schema columns: `start_date TEXT`, `completed_date TEXT`, `repeat INTEGER DEFAULT 0`, `progress_volumes INTEGER DEFAULT 0`
- Add schema migration (bump `SCHEMA_VERSION` to 6)

---

## 🟠 P1 — High Priority

### MediaDetailsPanel — Relations section

**File:** `src/features/media/MediaDetailsPanel.tsx`

AniList `Media` returns a `relations` field with `edges[].relationType` and `node` (id, title, type, format, coverImage, status).

- [x] Fetch relations in `get_media_details` (`anilist/mod.rs`)
- [x] Add `relations: Vec<MediaRelation>` to `MediaDetails` model
- [x] Add `MediaRelation` type to `shared/types/app.ts`
- [x] Render a horizontal scroll row in the panel: "Prequel → Sequel → Adaptation → …" with cover tiles
- [x] Clicking a relation tile opens `MediaDetailsPanel` for that media ID

Relation types to display: `PREQUEL`, `SEQUEL`, `ALTERNATIVE`, `SPIN_OFF`, `ADAPTATION`, `SIDE_STORY`, `SUMMARY`, `COMPILATION`, `PARENT`

---

### MediaDetailsPanel — Characters & Staff sections

**File:** `src/features/media/MediaDetailsPanel.tsx`

AniList `Media` returns `characters(perPage: 6)` and `staff(perPage: 6)`.

- [x] Fetch top 6 characters + staff in `get_media_details`
- [x] Add to models: `MediaCharacterEdge` (role, node: {id, name, image}), `MediaStaffEdge` (role, node: {id, name, image})
- [x] Add `characters: Vec<MediaCharacterEdge>` and `staff: Vec<MediaStaffEdge>` to `MediaDetails`
- [x] Render two collapsible sections in the panel with small portrait tiles
- [x] Character tile click → opens `CharacterPanel`; Staff tile click → opens `StaffPanel`
- [x] "See all" link → opens `CharacterPanel`/`StaffPanel` for full cast (use existing search or a new command)

---

### MediaDetailsPanel — Recommendations section

- [x] Fetch `recommendations(perPage: 6)` from AniList in `get_media_details`
- [x] Add `recommendations: Vec<MediaRecommendation>` to `MediaDetails` (id, title, coverImage, meanScore, format)
- [x] Render a horizontal scroll row "More like this" with cover tiles + score badge
- [x] Clicking opens `MediaDetailsPanel` for that recommendation

---

### MediaDetailsPanel — External Links (streaming)

AniList provides `externalLinks[]` with `url`, `site`, `type` (`STREAMING`, `INFO`, `SOCIAL`, `OFFICIAL`).

- [x] Add `external_links: Vec<ExternalLink>` to `MediaDetails` model and TS types
- [x] Render a "Watch on" chip row for `STREAMING` links (Crunchyroll, Netflix, Funimation, etc.)
- [x] Use `openUrl` from Tauri opener plugin for each chip
- [x] Show other link types (Official Site, Twitter) in a secondary row

---

### True offline mode

Currently the app stores data locally but some transitions and refreshes still expect network connectivity. The goal is a fully seamless offline experience with a clean recovery when connectivity returns.

- [x] Detect network status at startup and on change (OS event or periodic ping to `anilist.co`); expose a `useOnlineStatus` hook
- [x] Show a persistent but non-intrusive offline banner in the app shell
- [x] Gate all Tauri commands that hit AniList behind the online check — queue or silently skip rather than showing an error
- [x] `sync_user_lists` and `push_dirty_entries`: skip silently when offline, auto-retry on reconnect
- [x] Cover prefetch queue: pause when offline, resume on reconnect without duplicating requests
- [x] All navigation (library, details panel, schedule) must work fully from local cache when offline
- [x] Notification scheduler: skip airing refresh when offline; retry on reconnect
- [ ] Write integration tests (manual checklist) for offline → online transition

---

### Schedule — Card view mode

**File:** `src/features/schedule/ScheduleSurface.tsx`

`MIGRATION_TODO.md` listed "Add schedule view modes: list and card". Currently only list.

- [x] Add a view toggle (list / card grid) to the schedule header
- [x] Card mode: show cover image prominently, episode/countdown below, +/− overlay buttons
- [x] Persist selected view mode in `AppSettings`

---

### Activity / Discovery screen

A new surface for content discovery — no equivalent currently exists in the Tauri app.

**New file:** `src/features/discovery/DiscoverySurface.tsx`

- [x] Add `discovery` to `ScreenId` union in `shared/types/app.ts`
- [x] Add nav item in `App.tsx`
- [x] Rust: `get_trending_media(page: i32) -> Result<Vec<MediaSearchResult>>` querying AniList `Page.media(sort: TRENDING, type: ANIME)`
- [x] Sections:
  - Trending Anime (horizontal scroll, top 10)
  - Trending Manga (horizontal scroll, top 10)
  - Newly Added Anime (horizontal scroll)
  - Currently Airing — top 10 this season
- [x] Click card → `MediaDetailsPanel`; "Add to library" inline button

---

## 🟡 P2 — Medium Priority

### Social features (AniList-native only, no app backend)

**New files:** `src/features/social/`

These are read-only AniList-native features: no app-side social graph, no Supabase.

- [x] **Follow / Unfollow user** — add button to `UserPanel.tsx`; Rust command `toggle_follow(user_id: i64, follow: bool)`
- [x] **View following/followers list** — `get_following(user_id, page)` + `get_followers(user_id, page)` commands; list UI in `UserPanel`
- [x] **Following activity feed** — a "Following" tab in the Discovery/Activity screen; `get_following_activity(page)` command returning AniList `Page.activities` filtered to following
- [x] **Other user's list** — in `UserPanel`, add a button "View their list" that calls `get_user_media_list(user_id, type)` and renders a read-only library view
- [x] **AniList activity posting** — in Statistics or a dedicated panel, allow posting a text activity to AniList via `post_activity(text: String)`

---

### Notification improvements

**File:** `src-tauri/src/notifications/mod.rs`, `src/features/settings/SettingsSurface.tsx`

- [x] **Per-anime notification preference** — store a per-`mediaId` notification flag in a new `notification_overrides` table; expose toggle in airing card context menu
- [x] **Notification action: "Mark Watched"** — in-app action added in Notifications inbox for Airing events (calls `increment_episode_progress`); native OS action remains best-effort per platform/plugin capabilities
- [x] **Rich notifications with cover image** — include local cached cover path in notification payload

---

### Activity heatmap improvements

**File:** `src/features/statistics/StatisticsSurface.tsx`

- [x] **Year selector** — dropdown to switch the heatmap between years (2024, 2025, 2026…); pass `year` param to `get_activity_heatmap`
- [x] **Click a day** — clicking a cell opens a popover/drawer listing all activity entries for that date (filter `activity_log` by `DATE(created_at)`)
- [x] **Monthly chart** — add a bar chart showing per-month episode/chapter counts for the selected year

---

### Global airing schedule (AniChart-like)

**Scope:** All currently-airing anime, not just the user's watching list.

- [x] New Rust command: `get_global_airing_schedule(weekday: Option<u8>) -> Result<Vec<GlobalAiringEntry>>` — fetches AniList `Page.airingSchedules` for a date range
- [x] New type `GlobalAiringEntry` (title, coverImage, episode, airingAt, mediaId, format, popularity)
- [x] UI: expandable section in `ScheduleSurface` or a dedicated tab — "All Airing" with day-of-week tabs (Mon–Sun)
- [x] Quick "Add to Planning" button on each entry
- [x] Filter by popularity threshold to avoid listing 200+ obscure entries

---

### Sync improvements & conflict resolution

The current sync is a simple last-write-wins pull + dirty-flag push. It works well in practice but has edge cases.

- [x] **Conflict detection** — on pull, compare `updated_at` of incoming AniList entry against local `updated_at`; if both sides changed since last sync, record a conflict rather than silently overwriting
- [x] **Conflict resolution UI** — a small dialog or toast listing conflicting fields (e.g. "AniList says Ep 12, local says Ep 14") with "Keep local" / "Use AniList" / "Use higher value" choices
- [x] **Sync log** — persist per-entry sync events to `sync_log` table with timestamps, so users can audit what changed
- [x] **Background auto-sync** — trigger a quiet `sync_user_lists` every N minutes when the app is in focus (configurable in Settings, default 15 min)
- [x] **Sync indicator** — last-synced timestamp in Settings; delta/conflict count in the sync toast
- [x] **Rate limiting** — respect AniList rate-limit response headers (90 req/min); back off and retry rather than hard-fail (already implemented, now documented)
- [x] **Partial sync** — on startup, only pull entries with `updatedAt` newer than the stored high-water mark instead of fetching all pages

---

### Score format awareness

- [x] Read `scoreFormat` from AniList viewer (`POINT_100`, `POINT_10_DECIMAL`, `POINT_10`, `POINT_5`, `POINT_3`, `POINT_100`, `SMILEY`)
- [x] Store it in `auth_session` or `app_settings`
- [x] Render score correctly in library cards, edit modal, and stats (e.g. ★★★ for POINT_5)
- [x] Score input in edit modal adapts to the user's preferred format

---

### Custom lists support

- [x] Fetch user's custom list names from AniList `mediaListOptions.animeList.customLists` / `mangaList.customLists`
- [x] Display custom list membership in `EntryEditModal` as checkboxes
- [x] Pass custom list state through `update_list_entry` to AniList mutation

---

### About / Info dialog

- [x] New component: `AboutDialog.tsx` accessible from Settings
- [x] Content: app name + version (read from `tauri.conf.json` via `get_bootstrap`), app info, three external links (GitHub, AniList, website)
- [ ] "Check for updates" button (see Auto-updater below)
- [x] Credits / acknowledgments section

---

## 🟢 P3 — Low Priority / Future

### Activity: Global feed implementation (replace placeholder)

- [x] Replace current Global Activity placeholder in `ActivitySurface` with real AniList feed (`Page.activities` without `isFollowing`)
- [x] Add pagination (`page`, `perPage`) and "Load more" for global activity
- [x] Reuse existing Activity cards (likes/replies/open profile/media) for Global tab
- [x] Keep current filters (`All/Status/Messages/List`) working in Global tab with adapted semantics
- [x] Add lightweight cache + manual refresh for Global activity (same policy as Following, but independent key)

### Desktop-exclusive: Multi-panel Side Sheet

On large desktop screens (≥ 1400 px wide) there is enough space to show more than one detail panel side-by-side instead of replacing the previous one.

- [x] Track an ordered list of open side-sheet entries in a `useSideSheet` context (`id`, `type`, `props`)
- [x] On desktop (viewport width ≥ 1400 px), render up to 3–4 panels as a horizontal flex row to the right of the main content
- [x] Opening a new panel appends it to the right; closing removes it from the list; the row scrolls horizontally if all panels don't fit
- [x] On narrow viewports (≤ 1400 px) fall back to the current single-panel behavior (last-in replaces previous)
- [x] Each panel gets a `×` close button and optionally a "pop out" button to detach it into a float position
- [x] Deep-linking a studio → clicking a title inside the Studio panel opens a `MediaDetailsPanel` alongside, not replacing the Studio panel
- [x] Persist panel stack across navigation (switching library tab keeps open panels visible)
- [x] Keyboard: `Escape` closes the rightmost panel; `Alt+←` / `Alt+→` cycles focus between open panels

---

### Desktop-exclusive: Discord Rich Presence

Unique to the desktop app — not possible in AniList web or Flutter mobile.

- [ ] Add `discord-presence` or `discord-sdk` crate to `Cargo.toml`
- [ ] Rust module `src-tauri/src/discord/mod.rs`
- [ ] When user increments progress on an airing anime, update Discord status: "Watching {title} — Ep {n}"
- [ ] When user opens manga, status: "Reading {title} — Ch {n}"
- [ ] Elapsed timer per session
- [ ] Master enable/disable toggle in Settings
- [ ] Per-anime privacy override (same table as notification overrides)
- [ ] Clear status on logout / app close

---

### Desktop-exclusive: System tray

- [x] Minimize to tray on close (with first-time notice)
- [x] Tray icon with context menu:
  - Open MiyoList
  - Quick Sync (calls `sync_user_lists`)
  - Next Airing — shows next episode from schedule
  - Quit
- [x] Badge count on tray icon showing unnotified aired episodes
- [x] Setting: "Close button minimizes to tray" toggle

---

### Desktop-exclusive: Auto-updater

Tauri has a built-in updater plugin.

- [ ] Add `tauri-plugin-updater` to `Cargo.toml` and register in `lib.rs`
- [ ] Add `updater` capability to `capabilities/default.json`
- [ ] Check GitHub releases on startup (once per day, throttled)
- [ ] Show update dialog with version number + changelog excerpt
- [ ] "Download & Install" action that restarts the app
- [ ] "Remind me later" / "Skip this version" options
- [ ] Manual "Check for updates" button in About dialog

---

### Desktop-exclusive: Keyboard shortcuts

- [x] Add keyboard event handler in `App.tsx`
- [x] Default shortcuts:
  - `Ctrl+F` → focus search
  - `Ctrl+Shift+S` → trigger sync
  - `Alt+1` … `Alt+6` → navigate to each surface
  - `Escape` → close open drawer/modal
  - `F5` → refresh current surface
- [x] Show shortcut hints in tooltips
- [ ] Configurable shortcuts in Settings (optional, low effort if done with a map)

---

### Desktop-exclusive: Media player integration (Taiga-style)

Detect anime being played in VLC, mpv, MPC-HC via window title or player IPC.

- [ ] Research phase: determine most reliable detection method for Windows (window title polling vs named pipe)
- [ ] Rust background thread: poll active windows for player process every 30 seconds
- [ ] Parse filename/window title against library titles using fuzzy matching
- [ ] On match: show a "Now Playing" banner with proposed episode increment
- [ ] User confirms → `increment_episode_progress` called
- [ ] Opt-in toggle in Settings; disabled by default

---

### Window management

- [ ] Persist window size and position in SQLite (`app_settings`) and restore on next launch
- [ ] "Always on top" toggle (useful for airing schedule while watching)
- [ ] Mini-compact mode: shrink window to a narrow sidebar showing only airing countdown and quick sync button

---

### Statistics — Annual wrap-up

- [x] Year-in-review stats page (selectable year)
- [x] Totals for that year: completed anime, episodes watched, chapters read, mean score
- [x] Top 3 genres of the year, top studio, most-watched weekday
- [x] "First anime completed in {year}" and "Last anime completed in {year}"
- [x] Shareable summary card (generate image or formatted text for sharing)

---

### Opening / Ending theme player

- [ ] Integrate [AnimeThemes.moe](https://animethemes.moe) API (free, no auth required)
- [ ] In `MediaDetailsPanel`, add "Themes" section listing all OP/ED entries
- [ ] Play audio via `<audio>` element or Tauri-side fetch
- [ ] Show theme name, type (OP/ED), artist, episode range
- [ ] Favourite themes list (stored locally)

---

### Loading skeletons

Currently loading states show bare text or nothing.

- [x] `MediaCardSkeleton` component: grey shimmer placeholder matching card size
- [x] `PanelSkeleton`: full-panel shimmer for detail drawers while data loads
- [x] Apply in: Library initial load, Search results, Schedule load, People panels
- [x] Use CSS animation (`@keyframes shimmer`) — no extra dependency

---

### Manga chapter notifications via external service

AniList API does not provide manga airing/release schedules.

- [ ] Research: MangaUpdates RSS, MangaDex API, or Kitsu API for chapter release tracking
- [ ] Design: store a `manga_notification_overrides` table mapping `media_id → external_service_id`
- [ ] Background polling when app is open; no Workmanager equivalent needed on desktop
- [ ] Notify when new chapter available for a tracked manga
- [ ] Toggle per-manga in edit modal

---

## 🔵 P4 — Ambitious / Long-Horizon

> These ideas are grounded extensions of existing P3 features. Each one takes a working concept and pushes it into a distinct, much larger product surface. Estimated effort is high (weeks), but all are technically feasible within Tauri + Preact.

### Anime Music Hub (evolution of Opening / Ending theme player)

The P3 OP/ED player adds a "Themes" section inside `MediaDetailsPanel`. This takes it further: a dedicated music experience built into MiyoList, inspired by Spotify's UI paradigm.

**New surface:** `src/features/music/MusicSurface.tsx`

- [ ] Persistent mini-player bar at the bottom of the app shell (like Spotify's playback bar) — shows current track, artist, progress scrubber, prev/next/play/pause
- [ ] Dedicated **Music tab** in navigation with full-screen player and queue view
- [ ] **Library integration**: "Now Watching" smart playlist auto-populated from currently-watching anime (OPs/EDs for shows in your watchlist)
- [ ] **Playlists**: create and name custom theme playlists; stored locally in SQLite (`music_playlists`, `music_playlist_tracks` tables)
- [ ] **Favourites shelf** — quick access to starred themes, grouped by OP / ED / Insert Song
- [ ] **Discovery shelf** — "Themes from trending anime this season" section pulling from AnimeThemes + Discovery surface
- [ ] **Artist page** — clicking an artist name shows all their anime themes indexed in AnimeThemes, with a mini bio from AniList `Staff` query
- [ ] **Lyrics support** — integrate [LRCLIB](https://lrclib.net/) (free, no auth) for synced lyrics overlay on the full-screen player
- [ ] **Queue management** — drag-to-reorder queue, shuffle, repeat-one / repeat-all modes
- [ ] **Theme video mode** — AnimeThemes provides `.webm` theme videos; offer a toggle to play video instead of audio-only on desktop
- [ ] Rust side: `search_themes(query)`, `get_themes_for_media(media_id)`, `get_themes_for_artist(slug)` — thin proxies to AnimeThemes REST API

---

### Built-in Video Player (evolution of Desktop-exclusive: Media player integration)

The P3 media player integration detects VLC/mpv/MPC-HC via window title polling and auto-increments progress. This takes it further: MiyoList becomes its own video player — no external app required.

**New surface:** `src/features/player/PlayerSurface.tsx`  
**Rust module:** `src-tauri/src/player/mod.rs`

- [ ] **Desktop player** — embed a video playback surface using Tauri's `webview`-native `<video>` element or the `mpv` IPC socket as a headless backend (no UI of mpv, just the engine); support `.mkv`, `.mp4`, `.webm`
- [ ] **Open file** — "Watch locally" button in `MediaDetailsPanel` → file picker → auto-match against library entry; increment progress on completion
- [ ] **Episode auto-advance** — if multiple episodes exist in the same folder, automatically queue next episode and increment progress
- [ ] **Playback controls overlay** — fullscreen-friendly HUD: timeline scrubber, volume, subtitle track selector, audio track selector, chapter markers
- [ ] **Subtitle support** — load embedded subtitles or external `.srt`/`.ass` files; selectable track in HUD
- [ ] **Remember position** — store last playback position per `(media_id, episode)` in SQLite; resume prompt on reopen
- [ ] **Picture-in-Picture** — use Tauri window API to spawn a compact floating player window; dismiss without losing position
- [ ] **Android player** — on mobile, open the system video intent (`ACTION_VIEW`) with the file URI, falling back to a built-in `<video>` fullscreen surface; progress sync same as desktop
- [ ] **Streaming via direct URL** — paste a direct `.mp4` / `.m3u8` URL (e.g. from a CDN) into the player; no torrent/piracy infrastructure, just a URL input
- [ ] **Torrent-free integration** — explicitly out of scope; the player is for locally owned files and direct URLs only (keep the project ToS-safe)
- [ ] Rust side: if using mpv IPC — `spawn_mpv_ipc()`, `mpv_seek(position)`, `mpv_get_position() -> f64`, `mpv_set_subtitle_track(id)`

---

## 🟣 P5 — Moonshots

> Speculative ideas that would fundamentally change what MiyoList is. No implementation details yet — these are vision statements to revisit if the project reaches a mature stage.

### Taste Graph & Compatibility Score

- [ ] Build a local **taste vector** from the user's completed list: genre weights, studio affinity, score distribution, pacing preferences (episode count vs score correlation)
- [ ] Compare vectors between two users (viewer + any AniList user) → generate a **Taste Compatibility %** score shown in `UserPanel`
- [ ] "You'd probably enjoy…" shelf on Discovery: media scored high by users with similar taste vectors, not yet in the viewer's list
- [ ] All computation is local — no server, no data leaving the device

### Local-Only Custom Library (AniList-independent entries)

For titles that simply don't exist on AniList — doujin works, indie productions, obscure OVAs, fan projects, or any media the user wants to track privately. Fully local, never synced.

**New Rust module:** `src-tauri/src/custom_media/mod.rs`
**New frontend:** `src/features/library/CustomEntryEditModal.tsx`

- [ ] New SQLite table `custom_media` — user-created titles stored entirely on-device: `id` (local UUID), `title`, `title_romanji`, `type` (Anime/Manga/LN/Other), `cover_path` (local image), `description`, `episode_count`, `chapter_count`, `volume_count`, `status` (Releasing/Finished/Unknown), `created_at`
- [ ] New table `custom_media_list_entries` — mirrors `media_list_entries` schema but references `custom_media.id`; no `dirty` flag — local-only by design
- [ ] **"Add custom title" button** in the library header (visually distinct from normal sync "+"); opens `CustomEntryEditModal`
- [ ] Modal fields: title (required), type, cover image (file picker → copied to app data dir), total episodes/chapters/volumes, description, personal status, score, progress, notes
- [ ] Custom entries appear in the regular library views (Anime / Manga / LN) **intermixed** with AniList entries; tagged with a small 🏠 local badge so they're distinguishable
- [ ] `MediaDetailsPanel` for custom titles shows a local-only variant — no AniList links, no streaming chips, no relations; just user-supplied data
- [ ] Edit and delete work purely locally; no AniList mutation, no dirty-flag queue
- [ ] **Export / Import** — custom titles included in the existing backup/export flow (JSON or SQLite snapshot) so they survive reinstalls
- [ ] Custom titles are **excluded from all AniList sync operations** at the Rust layer (separate table path, never touched by `sync_user_lists` or `push_dirty_entries`)
- [ ] Optional: attach a local folder path to a custom title → feeds into the P4 built-in video player for playback

---

## 📋 Schema migration checklist (for P0 items)

When bumping `SCHEMA_VERSION` from 5 → 6 in `db/mod.rs`:

```sql
-- v6 additions
ALTER TABLE media_list_entries ADD COLUMN progress_volumes INTEGER NOT NULL DEFAULT 0;
ALTER TABLE media_list_entries ADD COLUMN start_date TEXT;
ALTER TABLE media_list_entries ADD COLUMN completed_date TEXT;
ALTER TABLE media_list_entries ADD COLUMN repeat INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS notification_overrides (
    media_id INTEGER PRIMARY KEY,
    enabled  INTEGER NOT NULL DEFAULT 1,  -- 0 = muted, 1 = inherit global, 2 = forced on
    discord_enabled INTEGER NOT NULL DEFAULT 1
);
```

---

## 🗂 File creation / modification map

| Feature | Frontend file(s) | Rust file(s) |
|---|---|---|
| Entry delete + dates | `shared/components/EntryEditModal.tsx` | `commands/mod.rs`, `anilist/mod.rs`, `db/mod.rs` |
| Relations in details | `features/media/MediaDetailsPanel.tsx` | `anilist/mod.rs`, `models/mod.rs` |
| Characters/Staff in details | `features/media/MediaDetailsPanel.tsx` | `anilist/mod.rs`, `models/mod.rs` |
| Recommendations | `features/media/MediaDetailsPanel.tsx` | `anilist/mod.rs`, `models/mod.rs` |
| External links | `features/media/MediaDetailsPanel.tsx`, `shared/types/app.ts` | `anilist/mod.rs`, `models/mod.rs` |
| Schedule card view | `features/schedule/ScheduleSurface.tsx` | — |
| Discovery/Trending | `features/discovery/DiscoverySurface.tsx` (NEW) | `commands/mod.rs`, `anilist/mod.rs` |
| Social: follow/feed | `features/social/` (NEW) | `commands/mod.rs`, `anilist/mod.rs` |
| Heatmap year/day | `features/statistics/StatisticsSurface.tsx` | `commands/mod.rs`, `db/mod.rs` |
| Global airing schedule | `features/schedule/ScheduleSurface.tsx` | `commands/mod.rs`, `anilist/mod.rs` |
| Score format | `shared/components/EntryEditModal.tsx`, `features/library/LibrarySurface.tsx` | `commands/mod.rs`, `db/mod.rs` |
| Custom lists | `shared/components/EntryEditModal.tsx` | `commands/mod.rs`, `anilist/mod.rs` |
| About dialog | `features/settings/AboutDialog.tsx` (NEW) | — |
| Discord RPC | `features/settings/SettingsSurface.tsx` | `discord/mod.rs` (NEW), `lib.rs` |
| System tray | `App.tsx` | `lib.rs`, Tauri config |
| Auto-updater | `shared/components/UpdateDialog.tsx` (NEW) | `lib.rs`, `Cargo.toml` |
| Keyboard shortcuts | `App.tsx`, `app/navigation.ts` | — |
| Media player detect | `features/settings/SettingsSurface.tsx` | `player/mod.rs` (NEW) |
| Loading skeletons | `shared/components/Skeleton.tsx` (NEW) | — |
| Onboarding | `features/onboarding/OnboardingSurface.tsx` (NEW) | `commands/mod.rs` |
| OP/ED themes | `features/media/MediaDetailsPanel.tsx` | `commands/mod.rs` (AnimeThemes proxy) |
