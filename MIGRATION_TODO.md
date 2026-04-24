# MiyoList Migration TODO

## 1. What the Flutter project already has

The Flutter project in `miyolist-main` is not a prototype anymore. It is a fairly mature desktop/mobile AniList client with these implemented subsystems:

- AniList OAuth authentication and token storage.
- Anime, manga, and light novel list management.
- Local-first persistence via Hive.
- Optional cloud sync via Supabase.
- Search and media details pages.
- Airing schedule and release tracking.
- Notifications, including airing-related flows.
- Activity history tracking and statistics.
- Social/community features.
- Offline image caching and cache management.
- Theme customization and UI settings.

### Practical assessment

Strengths:

- The app is already structured around services and feature modules.
- A large part of the product is already local-first.
- AniList integration appears to be the real source of truth; Supabase is mostly an auxiliary layer.
- There is enough feature coverage to define a serious migration roadmap instead of guessing.

Weak points / rewrite pressure:

- Supabase introduced architectural complexity that is no longer wanted.
- There are multiple overlapping auth approaches in docs and code, which suggests the auth flow evolved over time.
- Some features are tightly coupled to Flutter-specific UI and state patterns, so they need redesign rather than direct porting.
- The current desktop app ships AniList client credentials in code, which is acceptable only with clear understanding that a desktop secret is not truly secret.

## 1.1. Legacy product problems that must not survive the rewrite

These points come from real user pain in the old app and should be treated as hard requirements for the rewrite, not as optional polish.

### A. Desktop login was unreliable on Windows

Observed old behavior:

- Browser auth opened.
- Auth flow depended on a website bridge hosted separately from the app.
- That bridge could not reliably complete a dynamic return flow back into the application.
- Callback did not return correctly to the Windows app.
- User had to manually copy code from the callback URL and paste it into the app.
- Some users still could not log in even after trying both paths.

Rewrite requirement:

- Remove the web middleware dependency entirely for desktop auth.
- Use a fully local localhost callback handled by the app itself.
- Windows login must have one primary happy path that is tested first-class.
- Manual code entry can exist only as a fallback, not as a normal flow.
- The auth UX must clearly explain what is happening and what failed.
- The app must detect callback timeout/failure and offer recovery actions instead of leaving the user stuck.

### B. Users explicitly want a true no-cloud mode

Observed expectation:

- Some users want Taiga-like local tracking with AniList sync but no social features and no cloud storage layer.
- Users want confidence that cache and app data are not silently pushed online.

Rewrite requirement:

- The new app should be local-first by design, not just local-capable.
- There should be no separate cloud backend for app data.
- Optional AniList synchronization should be clearly distinguished from local app storage.
- Social features should be strictly AniList-native if they remain at all.

### C. Airing page UX needed more flexible presentation

Observed request:

- Users want airing items to be viewable as cards, similar to newly added sections, with quick episode increment/decrement actions.

Rewrite requirement:

- The schedule/airing module should support more than one presentation mode.
- Card view should be part of the planned schedule UI, not a post-hoc afterthought.
- Quick progress actions from airing cards should be part of the interaction design.

### D. Desktop media-player tracking is a valid future direction

Observed expectation:

- Users are interested in Taiga-like detection of media played in desktop players such as VLC and mpv, with list updates synced to AniList.

Rewrite requirement:

- Do not promise this in MVP.
- Keep the new architecture open for desktop integration features later.
- Design the local event/history model so playback-derived progress updates can be added without reworking the whole app.

## 2. Target architecture for the new Tauri app

Target principle:

- `AniList <-> User`
- No `Supabase` in the runtime architecture.

Recommended split:

- Frontend: Preact + TypeScript.
- Native/backend layer: Tauri + Rust.
- Persistent storage: SQLite in the Tauri layer.
- Secure token storage: OS credential store via Tauri plugin or native secure storage integration.
- Caching: SQLite metadata + filesystem cache for images and exports.

### What should disappear completely

- Public profile sync.
- Cloud backup/sync settings.
- Supabase schema, sync jobs, and conflict resolution against cloud state.
- Social features that only make sense with your own app-side backend.

### Product guarantees for the rewrite

- Local app data must stay local unless the user explicitly triggers AniList synchronization.
- The app must remain fully usable without any app-owned cloud backend.
- Login and sync failures must degrade cleanly and explain the next step.
- Desktop UX should be treated as the primary platform, not a side effect of mobile-first assumptions.

### What should be redesigned, not copied 1:1

- Auth flow.
- Notification scheduling.
- Offline image cache.
- Search and local cache strategy.
- Settings model.

## 3. Feature map: migrate / redesign / drop

### Must migrate in MVP

- AniList OAuth login/logout.
- Local user/session persistence.
- Anime list.
- Manga list.
- Light novel list.
- Search across AniList.
- Media details pages.
- Edit list entry fields: status, score, progress, notes, dates, repeats.
- Filters, sorting, and multiple list views.
- Airing schedule / upcoming episodes.
- Adult content filter.
- Core settings.
- Basic notifications for airing episodes.
- Basic statistics based on local data.

### Good candidates for phase 2

- Activity history heatmap.
- Rich statistics and chart export.
- Offline image caching and cache manager.
- Custom themes.
- Welcome/onboarding flows.
- Better desktop-specific UX: shortcuts, context actions, deeper system integration.

### Likely to drop or heavily redesign

- Supabase sync.
- Public profiles.
- Friend system.
- Following system that depends on app-side social storage.
- App-side social feed.

### Can still exist without Supabase if redefined as AniList-only

- AniList notifications.
- AniList activity viewing.
- AniList user profile viewing.
- AniList favorites browsing.

These are fine if they are treated as direct AniList client features, not app-native social features.

## 4. Migration priorities for the Tauri project

## Phase 0. Foundation

- [x] Replace the default Tauri starter UI in `src/App.tsx` with app shell scaffolding.
- [ ] Decide the frontend stack additions now: router, query/cache layer, state management, form layer, chart library.
- [x] Add a typed domain folder structure in the frontend.
- [x] Add Rust modules for auth, database, AniList API, notifications, filesystem cache, and settings.
- [x] Define a single IPC boundary between Preact and Rust commands.
- [ ] Introduce error model and logging strategy from day one.
- [x] Define explicit non-functional requirements: reliable Windows auth, local-only runtime, graceful offline behavior, and clear sync-error UX.

> **Phase 0 status:** Mostly complete. Remaining: error/logging strategy, router/state decisions.

Suggested frontend structure:

- `src/app`
- `src/features/auth`
- `src/features/library`
- `src/features/search`
- `src/features/media`
- `src/features/schedule`
- `src/features/settings`
- `src/features/statistics`
- `src/shared`

Current frontend stack status:

- Tailwind 4 is now integrated as the primary styling layer.
- The initial shell and shared surface components have been migrated away from large custom CSS blocks to utility-first styling.

Suggested Rust structure:

- `src-tauri/src/auth`
- `src-tauri/src/anilist`
- `src-tauri/src/db`
- `src-tauri/src/settings`
- `src-tauri/src/notifications`
- `src-tauri/src/cache`
- `src-tauri/src/models`
- `src-tauri/src/commands`

## Phase 1. Data model and local persistence

- [x] Audit Flutter Hive models and convert them into an explicit SQLite schema.
- [x] Separate remote AniList models from local app models.
- [x] Design tables for:
- [x] `app_settings`
- [x] `auth_session`
- [x] `media_cache`
- [x] `media_list_entries`
- [x] `user_profile_cache`
- [x] `search_history`
- [x] `notification_settings`
- [x] `airing_cache`
- [x] `statistics_snapshots` or derived queries if snapshots are not needed.
- [x] Add migrations from the start instead of ad-hoc schema creation.
- [x] Decide which data is canonical from AniList and which is purely local UI metadata.

Current phase 1 status:

- Initial SQLite schema and migration bootstrap are implemented in the Tauri layer.
- Database initialization and schema overview are exposed to the frontend through Tauri commands.
- The shell now displays live local database status so future phases build on a visible persistence foundation.

Important schema rule:

- Do not recreate old Supabase tables locally just because they already exist. Model the data for the local product, not for legacy sync compatibility.

## Phase 2. Auth and AniList client

- [x] Rebuild AniList OAuth for desktop inside Tauri.
- [x] Prefer a Tauri-side callback listener or a controlled external browser flow.
- [x] Store access token in secure storage, not plain SQLite.
- [x] Add token refresh / expiry handling if AniList flow requires it.
- [x] Implement a unified AniList GraphQL client in Rust.
- [x] Add central rate limiting and retry/backoff logic in Rust.
- [x] Treat Windows as the reference auth platform and test it before secondary platforms.
- [x] Add timeout detection, "open browser again", and "paste code manually" recovery paths.
- [x] Instrument auth failures so callback, exchange, and storage failures are distinguishable in logs and UI.
- [x] Remove the old website bridge assumption and target fully local localhost-based auth.
- [x] Define command APIs for frontend consumption:
  - [x] `login` / `logout` (`prepare_auth_request`, `clear_access_token`)

  - [x] `get_viewer`
  - [x] `search_media`
  - [x] `get_media_details`
  - [x] `get_user_lists` (`sync_user_lists`)
  - [x] `update_list_entry`

Security note:

- If AniList supports PKCE, use it.
- If AniList requires a client secret, keep the exchange in Rust and document clearly that a desktop-distributed secret is still extractable.

Auth UX rule:

- Manual code entry is a fallback path only. The default experience must complete without the user touching the callback URL.

Current phase 2 auth status:

- The app now generates a localhost-based AniList auth request plan in the Tauri layer.
- OAuth `state` is generated locally and persisted in `auth_session`.
- The auth screen now reflects the local callback strategy and explicitly shows that no website bridge is used.
- AniList configuration now targets `.env` / runtime environment variables instead of hardcoded secrets.
- A first GraphQL foundation exists in Rust with env-backed endpoint configuration and a `viewer` query path.

## Phase 3. Library management MVP

- [x] Build the main layout with sidebar/top navigation.
- [x] Implement tabs or sections for anime, manga, and light novels.
- [x] Implement local hydration from SQLite on startup.
- [x] Implement pull/import from AniList into local storage (`sync_user_lists` command).
- [x] Implement editing of entry status, score, progress, notes (`update_list_entry` + `EntryEditModal`).
- [x] Implement filters by status (status tabs + `get_list_entries` with status param).
- [x] Implement sorting.
- [x] Implement search within local library.
- [x] Implement at least two view modes first, not all of them immediately (list view done).
- [x] Add optimistic UI for entry edits (local write before AniList sync).
- [x] Ensure every local edit remains valid even if AniList sync fails or is delayed (`is_dirty` flag).

> **Phase 3 status:** Complete.

Recommended product rule for local-first behavior:

- User actions write to local storage immediately.
- AniList update happens after local commit.
- Failed remote updates are surfaced as retryable sync issues against AniList only.

## Phase 4. Search and media details

- [x] Implement global search against AniList (`search_media` command + `SearchSurface`).
- [x] Cache search results and media metadata locally (upserted into `media_cache` on sync).
- [x] Build media details page with overview, cover, banner, genres, status, format, studios, relations, and user list state.
- [x] Support quick add/update from search results and detail page (`AddModal` + `add_to_library` command).
- [x] Reuse a normalized local media cache instead of scattering media blobs across multiple stores.

> **Phase 4 status:** Complete.

## Phase 5. Schedule and notifications

- [ ] Port airing schedule logic.
- [ ] Store upcoming episode data locally.
- [ ] Add background refresh logic appropriate for Tauri desktop constraints.
- [ ] Implement native desktop notifications.
- [ ] Support actions such as “mark episode watched” if the Tauri notification stack allows it reliably.
- [ ] Add notification settings and per-category toggles.
- [ ] Add schedule view modes from the start: list view and card view.
- [ ] Design airing cards with quick progress controls such as plus/minus episode update.
- [ ] Keep schedule interactions usable even when the app is temporarily offline.

Important redesign point:

- Replace Flutter background-task assumptions with explicit Tauri-compatible scheduling. Do not assume mobile-style background execution exists on desktop.

## Phase 6. Statistics and history

- [ ] Start with derived statistics from local library data.
- [ ] Add totals by status, score distribution, formats, genres, runtime, chapters, and volumes where possible.
- [ ] Port activity history tracking as a purely local event log.
- [ ] Add a heatmap/calendar view after the event log is stable.
- [ ] Add export only after the charts themselves are stable.

## Phase 7. Settings and offline features

- [ ] Port adult content filter.
- [ ] Port UI preferences.
- [ ] Port library visibility preferences.
- [ ] Add image caching only after core flows are stable.
- [ ] Add cache cleanup tools.
- [ ] Add local backup/export and import.
- [ ] Make it explicit in the UI that app data is local and AniList sync is optional user-triggered network behavior.
- [ ] Remove wording that implies any app-owned cloud storage exists.

Local backup should replace cloud backup:

- JSON export/import for user settings and local metadata.
- Optional SQLite backup file export.
- No automatic cloud sync layer.

## Phase 8. Desktop integration features

- [ ] Evaluate future desktop media tracking integrations for players like VLC and mpv.
- [ ] Decide whether detection is file-based, window-title based, player-API based, or plugin-based.
- [ ] Keep this out of MVP unless a narrow and reliable implementation is identified.
- [ ] If implemented later, treat it as a local automation feature that proposes progress updates before syncing them to AniList.

## 5. Explicit Supabase removal checklist

- [ ] Remove Supabase dependencies from the product design.
- [ ] Do not port any Supabase schema as-is.
- [ ] Remove privacy mode options that only toggle cloud behavior.
- [ ] Replace cloud sync settings with local backup settings.
- [ ] Replace cloud conflict resolution with simpler AniList sync-state handling.
- [ ] Remove app-native public social graph features unless they can be mapped directly to AniList APIs.
- [ ] Do not reintroduce any invisible online storage for cache, backups, or profile data.

## 6. Feature mapping from Flutter to Tauri

### Existing Flutter area -> Tauri target

- `auth` -> Tauri auth commands + frontend auth screens.
- `anime_list` -> library module.
- `search` -> AniList search module.
- `media_details` -> media detail module.
- `notifications` -> native notification module + settings UI.
- `statistics` -> local analytics module.
- `settings` -> app settings module.
- `themes` -> deferred customization module.
- `social` -> split into AniList-native viewing features and dropped app-specific network features.

## 7. Recommended implementation order

- [ ] App shell.
- [ ] SQLite schema + migrations.
- [ ] Secure auth/token handling.
- [ ] AniList client and rate limiter.
- [ ] Local library import and rendering.
- [ ] Entry editing.
- [ ] Search.
- [ ] Media details.
- [ ] Airing schedule.
- [ ] Airing card mode with quick actions.
- [ ] Notifications.
- [ ] Settings.
- [ ] Statistics.
- [ ] Offline cache.
- [ ] Backup/export.
- [ ] Desktop player integration research.

## 8. Risks to control early

- [ ] Avoid putting all business logic in the Preact layer; keep AniList, persistence, and scheduling logic in Rust.
- [ ] Avoid porting Flutter widget structure literally; redesign around desktop navigation.
- [ ] Avoid recreating Supabase-era abstractions such as cloud profile modes.
- [ ] Avoid storing tokens in plain frontend storage.
- [ ] Avoid tying list rendering directly to raw AniList responses; normalize the data first.
- [ ] Avoid implementing every feature before the data layer is stable.
- [ ] Avoid shipping an auth flow that works only with manual code copy/paste on Windows.
- [ ] Avoid vague privacy wording; users should immediately understand what is local, what is fetched from AniList, and what is never stored online.

## 9. Definition of success for the first serious Tauri milestone

The first milestone is successful if the new app can:

- authenticate with AniList,
- download the current user lists,
- persist everything locally,
- render anime/manga/novel lists,
- edit list entries and sync changes back to AniList,
- show search and media details,
- show airing schedule,
- work without Supabase entirely.

If this milestone is clean, the rest of the migration becomes incremental rather than architectural.