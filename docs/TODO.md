# TODO List - MiyoList

**Last Updated:** October 12, 2025  
**Current Version:** v1.5.0-dev  
**Target Release:** v1.0.0 "Aoi (葵)"

---

## 🎯 Release Strategy

### Version Naming Convention
Starting with v1.0.0, MiyoList uses **named versions** instead of standard semantic versioning:
- **v1.0.0 "Aoi (葵)"** - Official release (Blue/Hollyhock - symbolizing new beginnings)
- **v1.x.x-dev** - Development versions (v1.1.0-dev through v1.5.0-dev are pre-release builds)
- Future major releases will follow this naming pattern with meaningful Japanese names

### Path to v1.0.0 "Aoi"
This TODO is structured to guide development towards **v1.0.0 "Aoi (葵)" official release**:
- **v1.4.0-dev** (Completed): Core features polished (view modes, bulk operations)
- **v1.5.0-dev** (Current Release Candidate): Critical features complete (notifications, airing schedule, search)
- **v1.0.0 "Aoi (葵)"** (Official Release): Fully tested, polished, production-ready

### Post-Release (v1.1.0+)
Features that enhance the app but aren't critical for launch are documented in:
- 📄 [POST_RELEASE_ROADMAP.md](./POST_RELEASE_ROADMAP.md) - Social features, AI companion, advanced analytics

---

## ✅ Completed Features (v1.3.0)

### Core Functionality
- [x] AniList OAuth2 authentication
- [x] Deep linking (miyolist://auth)
- [x] Anime list viewing with filters
- [x] Manga list viewing with filters
- [x] Light Novels separate tab
- [x] Profile page with user info
- [x] Favorites display
- [x] Local storage with Hive
- [x] Cloud sync with Supabase
- [x] Offline-first architecture
- [x] Manga-style UI theme

### Privacy System
- [x] Private profile (local-only)
- [x] Public profile (cloud-synced)
- [x] Profile type selection page
- [x] Privacy settings dialog
- [x] Profile type switching
- [x] Privacy badge on profile
- [x] Conditional cloud sync
- [x] Warning dialogs

### List Management
- [x] Edit list entries (v1.1.2)
  - Status dropdown (context-aware for anime/manga)
  - Score slider (0-10 with 0.5 increments)
  - Progress counter with increment/decrement
  - Start/Finish date pickers
  - Rewatches/Rereads counter
  - Notes field (multiline)
  - Delete entry with confirmation
  - Local storage integration
- [x] Delete from list (via edit dialog)
- [x] Add to list (via MediaDetailsPage)
- [x] Custom lists (v1.2.0)
  - Create custom collections
  - Custom list support in edit dialog
  - AniList custom list integration
- [x] Sorting options (v1.2.0)
  - Sort by title (A-Z / Z-A)
  - Sort by score (high to low / low to high)
  - Sort by updated date (newest / oldest)
  - Sort by progress
  - Per-list sorting preferences

### Sync System (v1.3.0)
- [x] Auto-sync on modifications (v1.1.2)
  - 2-minute delay after last edit
  - Timer resets on new edits
  - Silent background sync
  - Batches multiple changes
- [x] Sync button cooldown (v1.1.2)
  - 1-minute cooldown period
  - Visual countdown in tooltip
  - Loading spinner during sync
  - Grayed out when disabled
- [x] Background sync on app pause (v1.1.2)
  - Syncs when app minimized
  - Syncs pending modifications only
  - Lifecycle observer integration
- [x] Manual sync button (with cooldown)
- [x] Sync status indicator (last sync time in tooltip)
- [x] Conflict resolution ✨ (v1.3.0)
  - Three-way merge support (Local vs Cloud vs AniList)
  - 5 resolution strategies (Last-Write-Wins, Prefer Local/Cloud/AniList, Manual)
  - Beautiful side-by-side comparison UI
  - Automatic conflict detection on sync
  - Metadata tracking (timestamps, device info, source)
  - Field-level conflict identification
  - SQL migration for Supabase
  - Documentation: [CONFLICT_RESOLUTION.md](./CONFLICT_RESOLUTION.md)
- [x] Selective sync ✨ (v1.3.0)
  - Per-category sync control (Anime List, Manga List, Favorites, User Profile)
  - UI in Privacy Settings dialog
  - Checkbox controls for each category
  - Warning when all categories disabled
  - Respects user preferences during sync
  - All enabled by default (backward compatible)

### UI Customization (v1.3.0)
- [x] Tab visibility settings ✨
  - Hide/show Anime, Manga, and Novels tabs
  - Configurable in Privacy Settings
  - Dynamic TabController creation
  - Minimum one tab must be visible
  - Perfect for users who only track one content type
  - Documentation: [TAB_VISIBILITY.md](./TAB_VISIBILITY.md)

- [x] Theme system ✨ NEW!
  - Multiple theme support (Dark, Light, Carrot 🥕)
  - Beautiful theme selector with previews
  - Persistent theme storage in UserSettings
  - Extensible architecture for future themes
  - Smooth theme transitions
  - Color scheme system with ThemeColors abstract class
  - Theme provider for state management
  - **Performance optimization:** 5-minute fetch cooldown prevents redundant API calls on theme change
  - Documentation: [THEME_SYSTEM.md](./THEME_SYSTEM.md), [THEME_PERFORMANCE_FIX.md](./THEME_PERFORMANCE_FIX.md)

### List Filtering & Views (v1.4.0)
- [x] "All" status filter ✨ NEW!
  - View all statuses in single view (Watching, Planning, Completed, Paused, Dropped, Repeating)
  - Beautiful gradient button (Blue → Red) with grid icon
  - Color-coded status indicators on cards (4px left strip)
  - 6 status colors: Green (Current), Blue (Planning), Purple (Completed), Orange (Paused), Red (Dropped), Cyan (Repeating)
  - Selected by default on page open
  - Visual distinction from regular status filters
  - Seamless integration with existing filters
  - Documentation: [ALL_STATUS_FILTER.md](./ALL_STATUS_FILTER.md)

### Search & Discovery
- [x] Global search functionality
  - Search anime, manga, characters, staff, studios
  - Type filters (ALL, ANIME, MANGA, CHARACTER, STAFF, STUDIO)
  - Clean card-based results UI
  - Navigation to detail pages
- [x] In-list search (anime/manga lists)
  - Local search by title
  - Real-time filtering
- [x] Media search service
  - 3-level search (Hive → Supabase → AniList)
  - Intelligent caching
  - Offline-first approach

### Detail Pages
- [x] Media Details Page (fully implemented)
  - Banner image and cover
  - Full description with HTML rendering
  - Statistics (score, popularity, episodes/chapters)
  - Genres and tags
  - Characters section (with "See All" dialog)
  - Staff section
  - Studios (clickable navigation)
  - Relations (sequels, prequels, etc.)
  - Recommendations
  - Add/Edit entry integration
  - External links (official sites, streaming)
- [x] Character Details Page
  - Character info and description
  - Media appearances with roles
  - "See All" dialog for full media list (10-item limit)
  - Voice actors section
  - Navigation to media pages
- [x] Staff Details Page
  - Staff bio and info
  - Works tab (with "See All" dialog)
  - Characters tab (with "See All" dialog)
  - Social media links
  - Navigation to media and character pages
- [x] Studio Details Page
  - Studio info
  - Main Studio / Support tabs
  - Productions grid view
  - Navigation to media pages

### Navigation & UX
- [x] Profile page navigation
  - Click on favorites → navigate to detail pages
  - Character, Staff, Studio, Media navigation
- [x] Global search page (dedicated search UI)
- [x] "See All" dialogs with grid layouts
  - Optimized card sizing (140px width)
  - Adaptive column count
  - Smooth scrolling
- [x] About dialog in profile
  - Acknowledgments and credits
  - Technology stack listing
  - License information
  - External links (GitHub, AniList, etc.)

### Error Handling & Polish
- [x] Rate limiting protection (30 req/min)
- [x] Error recovery UI (retry buttons)
- [x] Loading states (spinners, skeletons)
- [x] Adult content filtering
- [x] Image caching (cached_network_image)
- [x] Responsive layouts
- [x] Overflow protection (Flexible widgets)
- [x] Crash reporting (v1.3.0)
  - Session tracking (graceful vs crash)
  - Automatic crash detection on restart
  - Crash report dialog with copy-to-clipboard
  - Comprehensive logging system (5 levels)
  - Log rotation (5MB max, 3 files kept)
  - Global error handlers (Flutter + async)
  - Stack trace capture
  - Privacy-focused (no personal data)
  - Documentation: [CRASH_REPORTING.md](./CRASH_REPORTING.md)

### Bug Fixes & Stability (v1.4.0)
- [x] Startup error fixes ✨ UPDATED!
  - Fixed zone mismatch error (removed async from runZonedGuarded callback)
  - Fixed MaterialLocalizations error (used WidgetsBinding.addPostFrameCallback)
  - Proper initialization order (bindings → services → zone → app)
  - Crash dialog shows only after MaterialApp is ready
  - Clean startup without errors or warnings
  - Documentation: [INITIALIZATION_FIX.md](./INITIALIZATION_FIX.md)

---

## ✅ Completed Features (v1.5.0-dev - Release Candidate)

### Critical Release Features
- [x] Notification system ⭐
  - Priority: **CRITICAL**
  - Status: **Completed** ✅
  - Effort: High
  - Description: In-app notifications from AniList
  - Features:
    - All AniList notification types (Airing, Activity, Forum, Follows, Media)
    - Tab-based filtering (All, Airing, Activity, Forum, Follows, Media)
    - Unread count badge
    - Notification settings (enable/disable per category)
    - Smart link handling (app for media, browser for forum/users)
    - Pull-to-refresh
    - Kaomoji states (loading, error, empty)
    - GraphQL API integration
    - Hive storage for settings
  - Dependencies: url_launcher
  - Benefits: User engagement, timely updates
  - Documentation: [NOTIFICATION_SYSTEM.md](./NOTIFICATION_SYSTEM.md)
  - **Completed in v1.5.0-dev**
  - **Note:** This is for in-app notifications from AniList. For push notifications, see v1.1.0+ roadmap.

- [x] Airing schedule ⭐
  - Priority: **CRITICAL**
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Show when next episode airs for user's watching list
  - Features:
    - Activity tab as default home screen
    - Today's releases section (horizontal scroll)
    - Upcoming episodes list (vertical)
    - Episode countdown timers (days/hours/minutes)
    - Auto-refresh every minute
    - Integration with user's anime list
    - Beautiful card-based UI
    - Episode numbers display
    - Direct navigation to anime details
    - Kaomoji empty states
  - Dependencies: None (uses existing services)
  - Benefits: Never miss episodes, timely viewing
  - Documentation: [AUTO_REFRESH.md](./AUTO_REFRESH.md)
  - **Completed in v1.5.0-dev**

- [x] Advanced global search ⭐
  - Priority: **HIGH**
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Enhanced search with adult content filtering
  - Features:
    - Type filters (All, Anime, Manga, Character, Staff, Studio)
    - Adult content filter (respects AniList settings)
    - Clean card-based UI
    - Navigation to detail pages
    - Search history (future)
  - Benefits: Better discovery, safe browsing
  - **Completed in v1.5.0-dev**

- [x] Trending & Activity feed ⭐
  - Priority: **HIGH**
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Discover trending anime & manga, view AniList activity
  - Features:
    - Trending anime & manga sections
    - Activity feed (community posts)
    - Beautiful card layouts
    - Pull-to-refresh
    - Integration with Activity tab
  - Benefits: Content discovery, community engagement
  - **Completed in v1.5.0-dev**

- [x] Pagination for large lists ⭐
  - Priority: **HIGH**
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Lazy loading for lists with 2000+ entries
  - Features:
    - 50 items per page
    - Scroll detection (500px from bottom)
    - Smooth loading with 100ms delay
    - Loading indicator at list end
    - Scroll position preservation
    - Reset on filter/status change
  - Benefits: Instant load times, smooth scrolling
  - **Completed in v1.5.0-dev**

- [x] Cache management ⭐
  - Priority: **MEDIUM**
  - Status: **Completed** ✅
  - Effort: Low
  - Description: Image cache controls with size limits
  - Features:
    - Clear all cache button
    - Clear old cache (30+ days)
    - Customizable size limits (100MB-5GB)
    - Cache statistics display
    - File count & size info
    - Success notifications
  - Benefits: Storage control, performance optimization
  - **Completed in v1.5.0-dev**

---

## 🔥 High Priority (v1.0.0 "Aoi" - Official Release)

### Testing & Quality Assurance

- [ ] Unit tests 🔧
  - Priority: **CRITICAL**
  - Status: **In Progress** ⚙️ (38/55+ tests passing)
  - Effort: Very High
  - Description: Comprehensive test coverage
  - Progress:
    - ✅ Test dependencies added (mockito 5.4.4, bloc_test 9.1.7)
    - ✅ ConflictResolver tests (11/11) ✅
    - ✅ MediaSearchService tests (14/14) ✅
    - ✅ SupabaseService tests (13/13) ✅ - Graceful degradation
    - ⚠️ LocalStorageService tests (0/15) - Requires refactoring
    - 📝 AniListService tests - Base structure created, needs service refactoring
    - ⏳ Current coverage: ~35-40%
    - ⏳ Target: 60%+ code coverage
  - See: [UNIT_TESTING_SESSION_SUMMARY.md](../UNIT_TESTING_SESSION_SUMMARY.md)  
    - 🔧 Fixing compilation errors in tests
    - ⏳ Running tests and reaching 60%+ coverage
  - Target: 60%+ code coverage
  - Types: Unit, Widget, Integration tests
  - **Required for v1.0 "Aoi" release**

- [ ] Beta testing program 🔧
  - Priority: **HIGH**
  - Status: Not started
  - Effort: Medium
  - Description: Community testing before official release
  - **Required for v1.0 "Aoi" release**

### Post-Release Features (v1.1.0+)

- [ ] Push Notifications ⭐ NEW!
  - Priority: **High**
  - Status: Not started
  - Effort: Very High
  - Description: Background push notifications for episodes and updates
  - Features:
    - Episode release notifications (with custom timing: on air, 1h/3h/6h/12h/24h after)
    - Media update notifications (new episodes added, status changes)
    - Activity notifications (likes, comments, follows)
    - Rich notifications with cover images
    - Tap notification to open media/activity in app
    - Notification sound customization
    - Quiet hours (DND mode with time range)
    - Per-anime notification settings
    - Notification history
    - Background service for periodic checks
    - Battery optimization handling
  - Dependencies: flutter_local_notifications, workmanager (background tasks)
  - Benefits: Never miss episodes, real-time engagement
  - Platforms: Windows (10/11 notifications), Android, iOS (when implemented)
  - **Post-release feature (v1.1.0)**
  - **Advantage over AniList:** Web doesn't have push notifications!

- [ ] Manga Chapter Notifications via External Service ⭐ NEW!
  - Priority: **High**
  - Status: Not started
  - Effort: High
  - Description: Manga chapter release notifications via third-party service integration
  - Reason: AniList API doesn't support manga airing schedules (anime-only)
  - Potential Services:
    - MangaUpdates API (chapter release tracking)
    - Kitsu API (manga progress tracking)
    - Custom aggregator service
    - RSS feed integration
  - Features:
    - Track manga from user's reading list
    - New chapter release notifications
    - Multiple source support (MangaDex, MangaPlus, etc.)
    - Notification preferences per manga
    - Integration with in-app notification system
    - Fallback to manual tracking if service unavailable
  - Dependencies: http, flutter_local_notifications
  - Benefits: Complete notification coverage (anime + manga)
  - **Post-release feature (v1.2.0)**
  - **Fills AniList API gap:** Manga chapter tracking unavailable in AniList

---

## 🎯 Medium Priority (v1.0 "Aoi" Polish)

- [ ] App update system ⭐
  - Priority: **CRITICAL**
  - Status: Not started
  - Effort: Medium
  - Description: Check and install new app versions
  - Features:
    - Version check on startup
    - Update notification dialog
    - Changelog display
    - Direct download link (GitHub releases)
    - Optional auto-update
    - Update reminder settings
  - Dependencies: package_info_plus, url_launcher
  - Benefits: Easy updates, user retention
  - **Required for v1.0 release**

### Important UX Improvements
- [x] Pull-to-refresh ⭐
  - Priority: **High**
  - Status: **Completed** ✅
  - Effort: Low
  - Description: Refresh data by pulling down in lists
  - Benefits: Standard mobile UX pattern, easier sync trigger
  - Implementation: RefreshIndicator widget around GridView with AlwaysScrollableScrollPhysics
  - Features:
    - Fetches latest data from AniList
    - Reloads local data
    - Shows success notification
    - Works even with few items (AlwaysScrollableScrollPhysics)
    - Custom colors (blue accent)

- [x] Statistics page ⭐
  - Priority: **High**
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Show user stats (total watched, mean score, genre distribution, etc.)
  - Details:
    - Total anime/manga watched/read
    - Total episodes watched
    - Mean score
    - Genre distribution (pie chart)
    - Score distribution (bar graph)
    - Top genres/studios
    - Time spent (calculated from episodes)
  - Benefits: User engagement, data visualization
  - Dependencies: fl_chart package

### Quality Assurance
- [x] Unit tests ⚙️ **In Progress (49/55+ tests passing)**
  - Priority: **High**
  - Status: ✅ **4/7 services completed**
  - Effort: High
  - Description: Test coverage for critical services
  - Completed:
    - ✅ ConflictResolver (11/11 tests) - ~80% coverage
    - ✅ MediaSearchService (14/14 tests) - ~75% coverage
    - ✅ SupabaseService (13/13 tests) - Graceful degradation
    - ✅ AniListService (11/11 tests) - GraphQL integration
  - In Progress:
    - ⏳ LocalStorageService (requires refactoring)
  - Target coverage: 60%+ (current: ~45-50%)
  - Benefits: Code reliability, easier refactoring
  - **Required for v1.0 release**

- [ ] Beta testing program
  - Priority: **High**
  - Status: Not started
  - Effort: Medium
  - Description: Recruit beta testers for pre-release
  - Features:
    - TestFlight / Beta channel
    - Feedback collection system
    - Bug reporting form
    - User survey
  - Benefits: Real-world testing, bug discovery
  - **Required before v1.0 release**

---

## 📱 Core Features (v1.4.0 - v1.5.0)

### Discovery & Exploration
- [x] Advanced global search ⭐ NEW!
  - Priority: **High**
  - Status: **Completed** ✅
  - Effort: High
  - Description: Enhanced search with filters and sorting
  - Features:
    - Advanced filters (genre, year, season, format, status)
    - Sort options (popularity, score, trending, alphabetical)
    - Filter by score range
    - Filter by episodes/chapters count
    - Search history
    - Recent searches
    - Beautiful filter dialog UI
  - Benefits: Better content discovery
  - Documentation: [ADVANCED_SEARCH.md](./ADVANCED_SEARCH.md)
  - **Completed in v1.5.0**

- [ ] Global Airing Schedule (AniChart alternative) ⭐ NEW!
  - Priority: **Medium**
  - Status: Not started
  - Effort: Very High
  - Description: Complete airing schedule for ALL anime (not just user's list)
  - Features:
    - Calendar view (day/week/month)
    - Grid layout with time slots
    - Filter by day of week
    - Filter by season (Winter, Spring, Summer, Fall)
    - Filter by year
    - Search within schedule
    - Episode countdown for all anime
    - Quick add to list from schedule
    - Studio filter
    - Format filter (TV, OVA, Movie, etc.)
    - Sort by popularity/score
    - Airing status indicator (Currently Airing, Not Yet Aired)
    - Time zone support
    - Export to calendar (iCal format)
    - Notification setup from schedule
  - Benefits: Complete anime calendar, content discovery, planning ahead
  - Similar to: AniChart.net, LiveChart.me
  - **Post-release feature (v1.2.0+)**

- [x] Trending & Activity feed ⭐
  - Priority: **High**
  - Status: **Completed** ✅
  - Effort: High
  - Description: Show trending content and community activity
  - Features:
    - Trending Anime (Top 10)
    - Trending Manga (Top 10)
    - Newly Added Anime (Top 10)
    - Newly Added Manga (Top 10)
    - Activity tab in navigation (already implemented)
    - Refresh on pull-to-refresh
    - Horizontal scrollable sections
    - Direct navigation to media details
    - Color-coded sections (Blue for anime, Red for manga, Purple/Orange for newly added)
  - Benefits: Content discovery, community engagement
  - **Completed in v1.5.0**

### List Management
- [x] Bulk operations ✨ NEW!
  - Priority: Medium
  - Status: **Completed** ✅
  - Effort: High
  - Description: Select multiple entries and perform actions
  - Features:
    - Multi-select mode (long press to activate)
    - Bulk status change
    - Bulk delete with confirmation
    - Bulk score update
    - Selection indicators (blue border, checkmarks)
    - Select all functionality
  - Benefits: Faster list management
  - Implementation: BulkEditDialog with 3 actions, selection mode UI in all card types

### UI Improvements
- [x] Loading skeletons ✨ NEW!
  - Priority: Medium
  - Status: **Completed** ✅
  - Effort: Low
  - Description: Better loading states with skeleton screens
  - Benefits: Perceived performance improvement
  - Implementation: ShimmerLoading widget with animated gradients, MediaCardSkeleton for grid view
  - Features:
    - Animated shimmer effect during loading
    - Mimics actual card layout
    - 12 skeleton cards displayed during initial load
    - Smooth animation with 1.5s duration

- [x] Empty states ✨ NEW!
  - Priority: Medium
  - Status: **Completed** ✅
  - Effort: Low
  - Description: Friendly messages when lists are empty
  - Benefits: Better UX for new users
  - Implementation: EmptyStateWidget with context-aware messages
  - Features:
    - Different states for search, filters, specific status, new users
    - Clear action buttons (Clear Search, Clear Filters)
    - Helpful descriptions and guidance
    - Icon-based visual feedback

- [x] View modes ✨ NEW!
  - Priority: Medium
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Grid view, list view, compact view
  - Benefits: User preference customization
  - Implementation: Three different view modes with persistent storage
  - Features:
    - Grid View: Current card-based grid layout (default)
    - List View: Larger horizontal cards with more details
    - Compact View: Minimal text-focused rows for maximum density
    - Per-category view mode (anime, manga, novel have separate settings)
    - PopupMenu in AppBar for easy switching
    - Persistent storage in UserSettings
    - Smooth transitions between modes

---

## 🎯 Nice to Have (Future Updates)

**Note:** Features in this section are nice-to-have but not critical for v1.0 release. For detailed post-release roadmap, see [POST_RELEASE_ROADMAP.md](./POST_RELEASE_ROADMAP.md).

### Statistics & Analytics
- [ ] Annual wrap-up ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Year in review - user's activity summary
  - Features:
    - Total anime/manga completed in year
    - Total episodes/chapters watched/read
    - Top genres watched
    - Top studios
    - Most watched day of week
    - Longest binge session
    - First/Last anime of year
    - Beautiful shareable image (Instagram/Twitter format)
    - Share to AniList activity feed
    - Export as image (PNG/JPG)
    - Year selector (2025, 2026, etc.)
  - Benefits: User engagement, social sharing, nostalgia
  - Dependencies: image generation library
  - **Post-release feature**

- [ ] Taste compatibility ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Compare lists with other users
  - Features:
    - Compatibility percentage
    - Shared anime/manga
    - Taste comparison (genres, scores)
    - Similar tastes suggestions
    - Compare by specific genres
    - Visual compatibility chart
    - Share compatibility card
  - Benefits: Social feature, user engagement
  - Dependencies: Complex algorithm
  - **Post-release feature**

- [ ] Charts and graphs
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Visual representation of stats (pie charts, bar graphs, trends)
  - Dependencies: fl_chart
  - Features:
    - Genre distribution pie chart
    - Score distribution histogram
    - Watching history timeline
    - Monthly activity heatmap
  - **Post-release feature**

- [ ] Watch history timeline
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Visual timeline of watching history
  - Benefits: Nostalgia, data exploration
  - **Post-release feature**

### Companion & Interaction
- [ ] AI Companion ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: Very High
  - Description: Interactive companion that comments on user actions
  - Features:
    - Character mascot with personality
    - Contextual comments (added to list, completed anime, high score, etc.)
    - Mini-chat interface
    - Sticker-based communication
    - Custom sticker packs
    - Personality customization
    - Reaction to milestones (100 anime, 1000 episodes, etc.)
    - Easter eggs and jokes
    - Toggle on/off in settings
  - Benefits: Fun, engaging, unique feature
  - Dependencies: Custom illustration, sticker assets
  - **Post-release feature**

### User Experience
- [ ] Custom themes
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: User-customizable color schemes
  - Benefits: Personalization
  - **Post-release feature**

- [ ] Battery saver mode ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: Medium
  - Description: Battery saving mode to extend operating time
  - Features:
    - Reduce animation frame rate
    - Disable auto-refresh
    - Reduce image quality/caching
    - Dark mode enforcement
    - Disable background sync
    - Lower brightness recommendations
    - Battery usage statistics
    - Auto-enable when battery low (<20%)
    - Toggle in settings
  - Benefits: Better battery life, mobile-friendly
  - Dependencies: battery_plus, flutter_battery_optimization
  - **Post-release feature (v1.2.0+)**

- [ ] Voice commands & accessibility ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Voice control of the list and navigation through the application
  - Features:
    - Voice navigation ("Open anime list", "Go to profile")
    - Add/update entries by voice ("Mark Attack on Titan as completed")
    - Search by voice ("Search for One Piece")
    - Progress updates ("Set episode 5 for Demon Slayer")
    - Score by voice ("Rate 9 out of 10")
    - TalkBack/screen reader optimization
    - High contrast mode for visually impaired
    - Large text mode
    - Voice feedback for actions
  - Benefits: Accessibility, hands-free control
  - Dependencies: speech_to_text, flutter_tts
  - **Post-release feature (v1.3.0+)**
  - **Accessibility focus:** Important for visually impaired users

- [ ] Widgets (Windows/Android)
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: Home screen widgets for quick access
  - Benefits: Quick access to list
  - **Post-release feature**

- [ ] Offline image viewer
  - Priority: Low
  - Status: Not started
  - Effort: Low
  - Description: Gallery view for all cached images
  - Features:
    - Browse all cached covers
    - Full-screen image viewer
    - Search cached images
    - View image metadata
    - Quick navigation to media
  - Benefits: Offline content exploration
  - **Post-release feature**
  - **Note:** Image caching itself is already implemented (v1.5.0), this adds UI gallery

### Media & Entertainment ⭐ NEW!
- [ ] In-app trailer viewer
  - Priority: Medium
  - Status: Not started
  - Effort: Medium
  - Description: Watch YouTube trailers inside the app
  - Features:
    - Embedded YouTube player
    - Trailer preview on media details page
    - Auto-play trailers (optional)
    - Trailer playlist (all trailers for anime/manga)
    - Picture-in-Picture mode
    - Quality selection (480p, 720p, 1080p)
    - Fullscreen support
  - Benefits: Better user experience, no need to switch apps
  - Dependencies: youtube_player_flutter or similar
  - **Post-release feature (v1.2.0+)**

- [ ] Local media player
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: Built-in video player for local anime/movie files
  - Features:
    - Support multiple formats (MP4, MKV, AVI, etc.)
    - Subtitle support (SRT, ASS, SSA)
    - Playback controls (play, pause, seek, speed)
    - Audio track selection
    - Subtitle track selection
    - Playlist management
    - Continue watching from last position
    - Screenshot capture
    - Fullscreen mode
    - Keyboard shortcuts
    - Link episodes to AniList entries
    - Auto-update progress on AniList
  - Benefits: All-in-one anime tracking and watching app
  - Dependencies: video_player, media_kit, or vlc_flutter
  - **Post-release feature (v1.3.0+)**
  - **Note:** VLC-like functionality, very complex

- [ ] Watch party / Watch together ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: Very High
  - Description: Extension of the local player for viewing with friends
  - Features:
    - Synchronized playback across devices
    - Create/join watch party rooms
    - Real-time chat during playback
    - Emoji reactions
    - Pause/play synchronization
    - Seek synchronization
    - Host controls (kick users, pause all)
    - Voice chat integration (optional)
    - Up to 10 participants per room
    - Screen sharing (host shares video)
    - Watch history for party sessions
  - Benefits: Social watching experience, fun with friends
  - Dependencies: WebRTC, socket.io, agora_rtc_engine (for voice)
  - **Post-release feature (v1.4.0+)**
  - **Requires:** Local media player implementation first

- [ ] Streaming service integration ⭐ NEW!
  - Priority: High
  - Status: Not started
  - Effort: High
  - Description: Integration with streaming services for direct links to episodes
  - Features:
    - Detect where anime is available (Crunchyroll, Funimation, Netflix, etc.)
    - Direct episode links in media details
    - "Watch Now" buttons
    - Deep links to streaming apps
    - Free episode notifications (limited-time offers)
    - Subscription status integration
    - Regional availability check
    - Price comparison across services
    - Browser redirect for web streaming
    - Embed player for free episodes (if API allows)
  - Potential APIs:
    - JustWatch API (availability tracking)
    - Livechart.me (legal streaming links)
    - Because.moe (streaming service lookup)
    - Direct streaming service APIs (requires partnerships)
  - Benefits: Seamless viewing, discover where to watch
  - Dependencies: http, url_launcher, webview_flutter
  - **Post-release feature (v1.2.0+)**
  - **Note:** Legal streaming links only

- [ ] Opening/Ending themes integration
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Listen to anime OP/ED songs inside the app
  - Features:
    - Integration with AnimeThemes.moe API
    - List all OP/ED for anime
    - Audio player with controls
    - Lyrics display (if available)
    - Favorite songs
    - Create playlists
    - Download for offline listening (optional)
    - Link to Spotify/YouTube Music
    - Artist information
    - Song search
  - Benefits: Complete anime experience, music discovery
  - Dependencies: just_audio, AnimeThemes.moe API
  - **Post-release feature (v1.2.0+)**

---

## 🌐 Social Features (Post-Release)

**Note:** All social features are post-release and only available for public profiles.

### Phase 1: Basic Social
- [ ] Friend system
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Add/remove friends, view their lists
  - Features:
    - Friend requests
    - Friend list
    - View friend profiles
    - Friend activity feed

- [ ] Following system
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Follow users without reciprocation
  - Benefits: One-way connections

- [ ] Shared lists with friends ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: Very High
  - Description: Shared lists to view with friends
  - Features:
    - Create shared list with friends
    - Collaborative adding/editing
    - Real-time updates
    - Comment on entries
    - Vote on what to watch next
    - Watch together reminders
    - Shared list statistics
    - Permission levels (owner, editor, viewer)
    - Invite friends to shared list
    - Export shared list
    - Privacy settings (public/private/friends-only)
  - Benefits: Group watching planning, social engagement
  - Dependencies: Supabase (collaborative features), WebSocket
  - **Post-release feature (v1.4.0+)**

### Phase 2: Community
- [ ] Comments on profiles
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Leave comments on user profiles

- [ ] Activity feed
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: See what friends are watching/reading
  - Features:
    - Status updates
    - New entries
    - Score changes
    - Comments

- [ ] Recommendations from friends
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Get recommendations based on friend lists

- [ ] Leaderboards & Rankings ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Leaderboards and competitions between users
  - Features:
    - Global leaderboards (most anime watched, episodes completed)
    - Friend leaderboards (compare with friends only)
    - Monthly/yearly rankings
    - Achievement rankings
    - Genre-specific leaderboards
    - Speed rankings (fastest completion)
    - Score diversity rankings
    - Custom challenges (watch 10 anime this month)
    - Rewards/badges for top rankers
    - Personal ranking history
    - Filter by region/country
  - Benefits: Gamification, competition, motivation
  - **Post-release feature (v1.3.0+)**

### Phase 3: Gamification
- [ ] Achievements & Milestones ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Achievements for various actions with integration into AniList
  - Features:
    - Achievement system (badges, trophies)
    - Milestones (100/500/1000 anime watched)
    - Genre master badges (50+ anime in genre)
    - Binge watcher achievements
    - Early adopter badges
    - Completion rate achievements
    - Score variety achievements (watch all score ranges)
    - **AniList integration:** Update profile description with achievements
    - **AniList integration:** Display achievements as profile status
    - Achievement sharing (social media)
    - Achievement progress tracking
    - Rare/secret achievements
    - Custom achievement icons
    - Achievement notifications
  - Benefits: Gamification, user engagement, motivation
  - Dependencies: Achievement tracking system
  - **Post-release feature (v1.3.0+)**
  - **Note:** Uses AniList profile description for display

- [ ] Watch calendar & planning ⭐ NEW!
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Calendar of plans to view with reminders
  - Features:
    - Create watch schedule (plan to watch X on Y date)
    - Calendar view (day/week/month)
    - Drag-and-drop planning
    - Recurring events (every Saturday)
    - Custom reminders (1h/6h/24h before)
    - Notification for planned watches
    - Integration with airing schedule
    - Suggest free time slots
    - Export to Google Calendar/Outlook
    - Share watch plans with friends
    - Goal tracking (watch 3 anime this week)
    - Auto-reschedule missed watches
  - Benefits: Better planning, motivation, time management
  - Dependencies: flutter_local_notifications, calendar API
  - **Post-release feature (v1.3.0+)**

---

## � Third-Party Integrations (Post-Release)

### Platform Integrations
- [ ] MyAnimeList (MAL) Integration ⭐ NEW!
  - Priority: High
  - Status: Not started
  - Effort: Very High
  - Description: Integration with MyAnimeList
  - Features:
    - **Two-way sync:** Import MAL list to AniList
    - **Two-way sync:** Export AniList list to MAL
    - Automatic synchronization (every 6/12/24 hours)
    - Manual sync button
    - Conflict resolution (choose MAL/AniList/merge)
    - Score conversion (10-point ↔ 100-point)
    - Status mapping (Watching/Reading ↔ Plan to Watch, etc.)
    - Tags/notes sync
    - Progress sync (episodes/chapters)
    - Compare lists (show differences)
    - Merge duplicate entries
    - MAL OAuth authentication
    - Preserve both accounts simultaneously
    - Import history from MAL
    - Batch import/export
  - Benefits: Multi-platform support, user convenience, data portability
  - Dependencies: MAL API v2, http, oauth2
  - **Post-release feature (v1.3.0+)**

- [ ] Kitsu Integration
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Integration with Kitsu anime/manga database
  - Features:
    - Import Kitsu library
    - Export to Kitsu
    - Cross-platform sync
    - Duplicate detection
  - Benefits: Additional platform support
  - **Post-release feature (v1.4.0+)**

- [ ] Trakt Integration
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Sync with Trakt.tv for broader tracking
  - Benefits: Universal media tracking
  - **Post-release feature (v1.5.0+)**

---

## �🔧 Technical Improvements

### Performance
- [x] Image caching ✨ NEW!
  - Priority: **High**
  - Status: **Completed** ✅
  - Effort: Low
  - Description: Automatic image caching with deduplication
  - Features:
    - Auto-cache on view (cached_network_image)
    - Smart deduplication (skip already cached)
    - Progress logging (only new downloads)
    - Persistent cache storage
    - 2267+ images supported
  - Benefits: Faster loading, offline viewing, reduced bandwidth
  - **Completed in v1.5.0**

- [x] Cache management UI ✨ NEW!
  - Priority: Medium
  - Status: **Completed** ✅
  - Effort: Low
  - Description: Manage cached images with UI dialog
  - Features:
    - View cache size and image count
    - Clear all cache button
    - Clear old cache (30+ days) button
    - **Cache size limit setting** (100/250/500/1000/2000/5000 MB)
    - Cache statistics display
    - Confirmation dialogs
    - Success/error notifications
    - Persistent settings in UserSettings
  - Benefits: User control, storage management, prevent unlimited growth
  - **Completed in v1.5.0**
  - **Location:** Profile page → Image Cache icon

- [ ] Image optimization
  - Priority: Medium
  - Status: Not started
  - Effort: Medium
  - Description: Compress and optimize cached images
  - Features:
    - WebP format conversion
    - Compression on cache
    - Thumbnail generation
    - Progressive loading
  - Benefits: Reduced storage usage (30-50% smaller)
  - **Post-release feature**

- [x] Pagination for large lists ✨ NEW!
  - Priority: **High**
  - Status: **Completed** ✅
  - Effort: Medium
  - Description: Lazy loading for list entries (50 items per page)
  - Features:
    - Load initial 50 items instantly
    - Auto-load more on scroll (500px from bottom)
    - Smooth loading indicator at list end
    - **Scroll position preservation** (stays in place when loading)
    - Reset pagination on filter/status change
    - Works with all view modes (Grid, List, Compact)
    - Shows "X of Y" count in console
  - Benefits: Faster initial load, smooth scrolling for 2000+ entries
  - **Completed in v1.5.0**
  - **Critical for users with large lists!**

- [ ] Database optimization
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Optimize Hive box structure and indexes
  - Benefits: Faster queries

### Code Quality
- [ ] Integration tests
  - Priority: Medium
  - Status: Not started
  - Effort: Very High
  - Description: End-to-end testing
  - Benefits: Catch integration bugs

- [ ] Widget tests
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Test UI components
  - Benefits: UI regression prevention

- [ ] Code documentation
  - Priority: Low
  - Status: Partial
  - Effort: Medium
  - Description: Add dartdoc comments to all public APIs
  - Benefits: Better maintainability

---

## 🐛 Known Issues

### High Priority
- None currently

### Medium Priority
- None currently

### Low Priority
- None currently

---

## 📝 Notes

### Architecture Decisions
- **Offline-first:** Local storage is the source of truth
- **Sync strategy:** Cloud sync is optional and respects user privacy
- **Conflict resolution:** Three-way merge with user choice
- **Error handling:** Graceful degradation, never lose user data

### Future Considerations
- **Backend migration:** Consider moving to dedicated backend (currently Supabase)
- **Real-time sync:** WebSocket support for instant updates
- **Desktop optimization:** Keyboard shortcuts, window management
- **Accessibility:** Screen reader support, high contrast themes

---

## 📚 Documentation

### Feature Documentation
- [CONFLICT_RESOLUTION.md](./CONFLICT_RESOLUTION.md) - Three-way merge conflict resolution
- [TAB_VISIBILITY.md](./TAB_VISIBILITY.md) - Hide/show tabs feature
- [THEME_SYSTEM.md](./THEME_SYSTEM.md) - Multiple theme support
- [ALL_STATUS_FILTER.md](./ALL_STATUS_FILTER.md) - "All" status filter
- [CRASH_REPORTING.md](./CRASH_REPORTING.md) - Crash detection and reporting
- [VIEW_MODES_AND_BULK_OPS.md](./VIEW_MODES_AND_BULK_OPS.md) - View modes and bulk operations

### Technical Documentation
- [THEME_PERFORMANCE_FIX.md](./THEME_PERFORMANCE_FIX.md) - Theme change optimization
- [INITIALIZATION_FIX.md](./INITIALIZATION_FIX.md) - Startup error fixes

### Planning Documents
- [POST_RELEASE_ROADMAP.md](./POST_RELEASE_ROADMAP.md) - Features for v1.1.0+
- [POST_RELEASE_FEATURES_EXPANSION.md](../POST_RELEASE_FEATURES_EXPANSION.md) - Extended post-release features (October 13, 2025)

### Release Documentation
- [RELEASE_CANDIDATE_SUMMARY.md](../RELEASE_CANDIDATE_SUMMARY.md) - v1.5.0-dev milestone summary
- [UPDATE_SUMMARY_OCT12.md](../UPDATE_SUMMARY_OCT12.md) - October 12, 2025 updates (manga notifications, version naming)

---

**Legend:**
- ✅ = Completed
- 🔥 = High Priority
- ⭐ = Highly Requested
- 📱 = Mobile-focused
- 🌐 = Social Feature
- 🔧 = Technical
- ⚠️ = Required for v1.0 release

**Version Planning:**
- v1.3.0-dev (Completed): Conflict resolution, Selective sync, Crash reporting
- v1.4.0-dev (Completed): View modes, Bulk operations, Loading states, Empty states
- v1.5.0-dev (Current RC): Notifications, Airing schedule, App updates, Advanced search, Trending feed, Pagination, Cache management
- v1.0.0 "Aoi (葵)" (Official Release): Polished, tested, ready for production
- v1.1.0+ (Post-Release): Push notifications, Annual wrap-up, Taste compatibility
- v1.2.0+ (Post-Release): Battery saver, Streaming integration, Manga chapter notifications
- v1.3.0+ (Post-Release): MAL integration, Achievements, Voice commands, Watch calendar, Leaderboards
- v1.4.0+ (Post-Release): Shared lists, Watch party, AI Companion, Kitsu integration
- v1.5.0+ (Post-Release): Trakt integration, Advanced social features

**Priority for v1.0 "Aoi" Release:**
1. ⚙️ Unit tests (60%+ coverage) - **49/55+ tests passing (~45-50% coverage)**
2. ⚠️ Beta testing program
3. ⚠️ Performance optimization
4. ⚠️ Final polish & bug fixes

