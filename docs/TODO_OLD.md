# TODO List - MiyoList

**Last Updated:** January 2025  
**Current Version:** v1.3.0

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
- [x] Conflict resolution ✨ NEW! (v1.3.0)
  - Three-way merge support (Local vs Cloud vs AniList)
  - 5 resolution strategies (Last-Write-Wins, Prefer Local/Cloud/AniList, Manual)
  - Beautiful side-by-side comparison UI
  - Automatic conflict detection on sync
  - Metadata tracking (timestamps, device info, source)
  - Field-level conflict identification
  - SQL migration for Supabase
  - Documentation: [CONFLICT_RESOLUTION.md](./CONFLICT_RESOLUTION.md)
- [x] Selective sync ✨ NEW! (v1.3.0)
  - Per-category sync control (Anime List, Manga List, Favorites, User Profile)
  - UI in Privacy Settings dialog
  - Checkbox controls for each category
  - Warning when all categories disabled
  - Respects user preferences during sync
  - All enabled by default (backward compatible)

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

### Detail Pages ✨ NEW!
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

### Navigation & UX ✨ NEW!
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

---

## � High Priority

### Critical Features
- [ ] Pull-to-refresh
  - Priority: **High**
  - Status: Not started
  - Effort: Low
  - Description: Refresh data by pulling down in lists

- [x] Conflict resolution ✨ NEW!
  - Priority: **High**
  - Status: **Completed** (v1.3.0)
  - Effort: High
  - Description: ✅ Intelligent sync conflict resolution
  - Features:
    - Three-way merge support (Local vs Cloud vs AniList)
    - 5 resolution strategies (Last-Write-Wins, Prefer Local/Cloud/AniList, Manual)
    - Beautiful side-by-side comparison UI
    - Automatic conflict detection on sync
    - Metadata tracking (timestamps, device info, source)
    - Field-level conflict identification
    - SQL migration for Supabase
  - Documentation: [CONFLICT_RESOLUTION.md](./CONFLICT_RESOLUTION.md)

- [x] Crash reporting ✨
  - Priority: **High**
  - Status: **Completed** (v1.3.0)
  - Effort: Low
  - Description: ✅ Track crashes with intelligent detection
  - Features:
    - Session tracking (graceful vs crash)
    - Automatic crash detection on restart
    - Crash report dialog with copy-to-clipboard
    - Comprehensive logging system (5 levels)
    - Log rotation (5MB max, 3 files kept)
    - Global error handlers (Flutter + async)
    - Stack trace capture
    - Privacy-focused (no personal data)
  - Documentation: [CRASH_REPORTING.md](./CRASH_REPORTING.md)

---

## 📱 Core Features

### List Management
- [ ] Bulk operations
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Select multiple entries and perform actions

- [x] Custom lists
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Create custom collections beyond default statuses

- [x] Sorting options
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Sort by title, score, updated date, etc.

### UI Improvements
- [ ] Loading skeletons
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Better loading states with skeleton screens

- [ ] Empty states
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Friendly messages when lists are empty

- [ ] View modes
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Grid view, list view, compact view

- [ ] Dark/Light themes
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Currently only dark theme (manga style)

### Data & Sync
- [ ] Selective sync
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Choose what to sync (e.g., only anime, not manga)

---

## 🎯 Nice to Have

### Statistics & Analytics
- [ ] Statistics page
  - Priority: **High** ↑
  - Status: Not started
  - Effort: Medium
  - Description: Show user stats (total watched, mean score, genre distribution, etc.)

- [ ] Charts and graphs
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Visual representation of stats (pie charts, bar graphs, trends)

- [ ] Watch history timeline
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Visual timeline of watching history

### Notifications
- [ ] Notification system
  - Priority: Medium ↑
  - Status: Not started
  - Effort: High
  - Description: Notify about new episodes, updates

- [ ] Airing schedule
  - Priority: Medium ↑
  - Status: Not started
  - Effort: Medium
  - Description: Show when next episode airs (calendar view)

### User Experience
- [ ] View modes
  - Priority: Medium ↑
  - Status: Not started
  - Effort: Medium
  - Description: Grid view, list view, compact view for lists

- [ ] Dark/Light themes
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Currently only dark theme (manga style)

- [ ] Custom themes
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: User-customizable color schemes

- [ ] Widgets (Windows/Android)
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: Home screen widgets for quick access

---

## 🌐 Social Features (Public Profile Only)

### Phase 1: Basic Social
- [ ] Friend system
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Add/remove friends, view their lists

- [ ] Following system
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Follow other users, see activity

- [ ] Activity feed
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: See what friends are watching/reading

### Phase 2: Community
- [ ] Comments on lists
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Let friends comment on your lists

- [ ] Recommendations
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Get recommendations from friends

- [ ] Shared lists
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Create collaborative lists with friends

### Phase 3: Advanced
- [ ] Anime clubs
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: Create/join anime clubs

- [ ] Discussion forums
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: Community discussions

- [ ] User reviews
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Write and share reviews for anime/manga

---

## 🎬 User-Generated Content & Activity

### Activity System
- [ ] Activity feed implementation
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Real-time activity tracking (watching, completed, scored)
  - Features:
    - User activity timeline
    - Friends' recent activities
    - Activity notifications
    - Privacy controls per activity type

- [ ] Activity statistics
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Analytics for user activity patterns

### Media Storage (Cloudflare R2)
- [ ] R2 integration for user uploads
  - Priority: Medium
  - Status: Not started
  - Effort: Very High
  - Description: Allow users to upload custom media (screenshots, fan art, reviews)
  - Technical:
    - Cloudflare R2 bucket setup
    - Presigned URLs for secure uploads
    - CDN integration for fast delivery
    - Image optimization and compression

- [ ] Storage quota system
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Free tier with ad-based expansion
  - Features:
    - **Free tier**: 500MB per user
    - **Ad-based expansion**: +50MB per 60-second ad view (mobile only)
    - Quota dashboard in profile
    - Storage usage statistics
    - Auto-cleanup for old/unused files
    - File type restrictions (images, videos)

- [ ] In-app ad integration
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Rewarded video ads for storage expansion
  - Platforms:
    - Mobile only (Android/iOS)
    - AdMob or similar service
    - Fair ad frequency limits
    - Skip option after viewing

---

## 🌐 Marketing Website & Server-Side Features

### Marketing Website
- [ ] Landing page
  - Priority: **High** 
  - Status: Not started
  - Effort: Medium
  - Description: Promotional website for MiyoList
  - Sections:
    - Hero section with app screenshots
    - Feature highlights
    - Download links (Play Store, App Store)
    - Testimonials/reviews
    - FAQ section
    - Blog for updates

- [ ] SEO optimization
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Optimize for search engines
  - Technical:
    - Meta tags and descriptions
    - Sitemap generation
    - Schema.org markup
    - Performance optimization

- [ ] Analytics & tracking
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Track website visitors and conversions
  - Tools:
    - Google Analytics or privacy-focused alternative
    - Conversion tracking (downloads)
    - Heatmaps (optional)

### Server-Side Features (No Full Web App)
- [ ] User profile sharing (read-only)
  - Priority: Medium
  - Status: Not started
  - Effort: Medium
  - Description: Share profile via web link (myolist.com/u/username)
  - Features:
    - Public profile view (if user opted-in)
    - List preview (anime/manga stats)
    - Favorites showcase
    - No editing (mobile app only)

- [ ] List comparison tool
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Compare lists between users on website
  - Features:
    - Compatibility score calculation
    - Shared anime/manga
    - Recommendation suggestions
    - Shareable results link

- [ ] Deep link generator
  - Priority: Low
  - Status: Not started
  - Effort: Low
  - Description: Generate smart deep links from website
  - Use cases:
    - Share specific anime → opens in app
    - Share profile → opens in app
    - QR codes for easy sharing

- [ ] Server-side notifications
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Push notifications via backend service
  - Features:
    - New episode alerts
    - Friend activity notifications
    - Airing schedule reminders
    - Firebase Cloud Messaging (FCM)

- [ ] Moderation dashboard
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Admin panel for content moderation
  - Features:
    - User reports management
    - Content review (uploaded media)
    - Ban/suspend users
    - Analytics dashboard

- [ ] API for third-party integrations
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: RESTful API for external developers
  - Use cases:
    - Discord bots
    - Browser extensions
    - Third-party tools
    - OAuth integration

---

## 🔧 Technical Improvements

### Code Quality
- [ ] Unit tests
  - Priority: **High** ↑
  - Status: Not started
  - Effort: High
  - Description: Test models and services (critical for stability)

- [ ] Widget tests
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Test UI components

- [ ] Integration tests
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Test user flows end-to-end

- [ ] State management refactor
  - Priority: Low
  - Status: Not started
  - Effort: Very High
  - Description: Consider BLoC or Riverpod (current approach works but could scale better)

### Performance
- [ ] Image caching optimization
  - Priority: Low
  - Status: Partial (using cached_network_image)
  - Effort: Medium
  - Description: Better cache management and memory limits

- [ ] Lazy loading
  - Priority: Medium ↑
  - Status: Not started
  - Effort: Medium
  - Description: Load lists incrementally (pagination)

- [ ] Database optimization
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Optimize Hive queries and indexes

### DevOps
- [ ] CI/CD pipeline
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Automated build and test (GitHub Actions)

- [x] Crash reporting ✨
  - Priority: **High**
  - Status: **Completed** (v1.3.0)
  - Effort: Low
  - Description: ✅ Built-in crash detection and reporting system

- [ ] Analytics
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Privacy-focused usage analytics

---

## 📱 Platform Expansion

### iOS Support
- [ ] iOS configuration
  - Priority: Medium
  - Status: Partial (project exists)
  - Effort: Low
  - Description: Test and finalize iOS deep linking and build

- [ ] App Store preparation
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: Screenshots, description, app store optimization

### Web Support
- [ ] Web OAuth flow
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Handle OAuth redirects for web

- [ ] Web optimizations
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: PWA, responsive design, performance

### Other Platforms
- [ ] macOS support
  - Priority: Low
  - Status: Partial (project exists)
  - Effort: Low
  - Description: Test and optimize for macOS

- [ ] Linux support
  - Priority: Low
  - Status: Partial (project exists)
  - Effort: Low
  - Description: Test and optimize for Linux

---

## 🔒 Privacy Enhancements

### Advanced Privacy
- [ ] Granular privacy controls
  - Priority: Medium
  - Status: Not started
  - Effort: High
  - Description: Choose what's public (e.g., lists public but favorites private)

- [ ] Temporary public mode
  - Priority: Low
  - Status: Not started
  - Effort: Low
  - Description: Switch to public temporarily (time-limited)

- [ ] Privacy audit log
  - Priority: Low
  - Status: Not started
  - Effort: Medium
  - Description: See history of privacy changes and data access

### Data Management
- [ ] Data export
  - Priority: **High** ↑
  - Status: Not started
  - Effort: Medium
  - Description: Export all data to JSON/CSV (GDPR compliance)

- [ ] Data import
  - Priority: Medium
  - Status: Not started
  - Effort: Medium
  - Description: Import from other apps (MAL, Kitsu)

- [ ] Cloud data deletion
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Delete cloud data when switching to private

---

## 📚 Documentation

### User Documentation
- [ ] User guide
  - Priority: Medium
  - Status: Not started
  - Effort: Medium
  - Description: Complete user manual with screenshots

- [ ] FAQ
  - Priority: Medium
  - Status: Not started
  - Effort: Low
  - Description: Common questions and answers

- [ ] Video tutorials
  - Priority: Low
  - Status: Not started
  - Effort: High
  - Description: Video walkthroughs for major features

### Developer Documentation
- [ ] API documentation
  - Priority: Low
  - Status: Partial (inline comments)
  - Effort: Medium
  - Description: Comprehensive API docs with examples

- [ ] Architecture diagrams
  - Priority: Low
  - Status: Not started
  - Effort: Low
  - Description: Visual architecture overview

- [ ] Contributing guide
  - Priority: Low
  - Status: Not started
  - Effort: Low
  - Description: Guide for external contributors

---

## 🐛 Known Issues

### Bugs to Fix
- [ ] None critical reported yet

### Future Investigations
- [ ] Sync conflict handling improvements
- [ ] Large list performance (1000+ entries)
- [ ] Image cache size management
- [ ] Memory usage optimization

---

## 💡 Ideas & Considerations

### Feature Ideas
- [ ] AI-powered anime recommendations
- [ ] Seasonal anime calendar with reminders
- [ ] Compare lists with friends (compatibility score)
- [ ] Achievement system (badges, milestones)
- [ ] Watch party feature (sync watching with friends)
- [ ] Voice actor deep-dive pages
- [ ] Studio deep-dive pages (done!) ✅
- [ ] Character relationship graphs

### Technical Considerations
- Consider GraphQL subscriptions for real-time updates
- Evaluate BLoC pattern vs current setState approach
- Plan for internationalization (i18n) - multi-language support
- Accessibility improvements (a11y) - screen readers, contrast
- Offline mode improvements - better queue management
- **Cloudflare R2 setup** - storage for user-generated content
- **Backend service** - Node.js/Express or similar for server features
- **CDN configuration** - fast media delivery worldwide
- **Ad SDK integration** - rewarded video ads for mobile
- **Payment gateway** (future) - premium features without ads

### Infrastructure Planning
- **Marketing Website Stack**:
  - Next.js or Astro for static site
  - Tailwind CSS for styling
  - Vercel/Netlify for hosting
  - Cloudflare for CDN & DNS
  
- **Backend Service Stack**:
  - Node.js with Express/Fastify
  - PostgreSQL (Supabase) for data
  - Redis for caching/sessions
  - Cloudflare R2 for object storage
  - Firebase Cloud Messaging for push notifications
  
- **Mobile Ad Platform**:
  - Google AdMob (primary)
  - Unity Ads (alternative)
  - Rewarded video format only
  - Fair usage policy

---

## 📊 Priority Matrix

```
High Priority + Low Effort (Quick Wins):
- Pull-to-refresh
- Crash reporting
- Empty states
- Data export

High Priority + High Effort (Plan Carefully):
- Unit tests
- Conflict resolution
- Statistics page
- Lazy loading/pagination

Low Priority + Quick Wins (Nice to Have):
- Dark/Light toggle
- View modes
- Sorting options
- Privacy audit log

Low Priority + High Effort (Future):
- Social features
- Discussion forums
- State management refactor
- Web optimizations
```

---

## 🎯 Next Sprint Goals

### Sprint 1: Polish & Stability (Current Focus)
- [ ] Add pull-to-refresh to all lists
- [ ] Implement crash reporting
- [ ] Add empty states for lists
- [ ] Write critical unit tests

### Sprint 2: User Experience
- [ ] Better error handling throughout
- [ ] Loading skeletons
- [ ] Statistics page
- [ ] Data export feature

### Sprint 3: Performance
- [ ] Lazy loading for large lists
- [ ] Database optimization
- [ ] Memory usage improvements
- [ ] Image cache management

### Sprint 4: Features
- [ ] Airing schedule
- [ ] Notification system
- [ ] View modes
- [ ] Sorting options

### Sprint 5: Marketing & Infrastructure (Future)
- [ ] Design and launch marketing website
- [ ] Set up Cloudflare R2 storage
- [ ] Implement activity feed system
- [ ] Create public profile sharing (web)

### Sprint 6: Monetization & Growth (Future)
- [ ] Storage quota system implementation
- [ ] Ad SDK integration (mobile)
- [ ] Server-side notifications
- [ ] Analytics and tracking

---

## 📝 Notes

### Development Notes
- All detail pages complete and working! 🎉
- Search functionality fully implemented (local + global)
- Navigation between pages seamless
- About dialog with credits added
- No compilation errors
- Documentation comprehensive

### Recent Achievements
- ✅ MediaDetailsPage with full functionality
- ✅ CharacterDetailsPage with media appearances
- ✅ StaffDetailsPage with works and characters
- ✅ StudioDetailsPage with productions
- ✅ Global search with type filters
- ✅ "See All" dialogs with optimized grids
- ✅ About dialog with acknowledgments
- ✅ Profile navigation to all detail pages

### User Feedback Needed
- Test all detail pages thoroughly
- Validate search performance
- Check navigation flows
- Test on real devices (Android/iOS)
- Gather feature requests from community

### Technical Debt
- Consider pagination for very large result sets (>100 items)
- Add loading states for detail page dialogs
- Implement proper error boundaries
- Add retry logic for failed API calls

### Future Roadmap (Planned)
- 🎬 **Activity System** - Track and share user activities
- 💾 **User Media Storage** - R2-based upload system with quota
- 📱 **Ad Integration** - Rewarded ads for storage expansion (mobile)
- 🌐 **Marketing Website** - Landing page and promotional content
- 🔗 **Web Profile Sharing** - Read-only public profiles
- 🔔 **Push Notifications** - Server-side notification system
- 🛠️ **Backend Services** - API and server-side features

---

**Last Updated:** 2025-10-11  
**Version:** 1.2.0 (Search & Detail Pages Complete) ✅  
**Status:** Production Ready - Testing Phase 🚀  
**Future:** User-Generated Content & Marketing 🎯
