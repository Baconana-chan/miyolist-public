# MiyoList Changelog - Version 1.5.0+5

**Release Date:** October 13, 2025  
**Release Name:** Development Build  
**Previous Version:** 1.1.2+3

---

## 🎉 Major New Features

### 📺 Activity Feed & Airing Schedule
- **Today's Releases Section**: See all anime releasing today at a glance
- **Upcoming Episodes List**: Never miss an episode with the comprehensive schedule
- **Real-Time Countdown Timers**: Exact countdown to next episode release
- **Auto-Refresh**: Updates every minute automatically
- **Default Home Tab**: Activity feed is now the first tab you see

### 🔍 Advanced Global Search
- **Multi-Category Search**: Search across anime, manga, characters, staff, and studios simultaneously
- **Adult Content Filter**: Toggle 18+ content visibility
- **Advanced Filters**: 
  - Format filters (TV, Movie, OVA, ONA, etc.)
  - Genre selection
  - Year range
  - Status filters
  - Score range
- **Search History**: Quick access to recent searches
- **Smart Results**: Intelligent ranking and relevance sorting

### 🔒 Privacy & Profile System
- **Public/Private Profiles**: Choose who can see your profile
- **Tab Visibility Control**: Show/hide Anime, Manga, Novel tabs independently
- **Granular Sync Settings**: 
  - Sync anime list
  - Sync manga list
  - Sync favorites
  - Sync user profile
  - Selective sync for privacy
- **Cloud Sync Toggle**: Full control over data synchronization

### 📊 Statistics & Analytics
- **Watch Time Tracking**: Total hours spent watching anime
- **Episode Counters**: Track episodes watched, planning, dropped
- **Genre Distribution**: Beautiful charts showing your favorite genres
- **Format Breakdown**: See your preferences (TV, Movie, OVA, etc.)
- **Score Analytics**: 
  - Average score
  - Mean score
  - Score distribution charts
- **Completion Rates**: Track your completion percentage
- **Top Genres**: Discover your most-watched genres

### 🐛 Crash Reporting System
- **Automatic Detection**: Catches and logs crashes automatically
- **Detailed Reports**: Comprehensive crash logs with stack traces
- **Privacy-Focused**: All reports anonymous and optional
- **Session Tracking**: Track app sessions and stability metrics
- **User-Controlled**: Choose when to send reports

### 🔄 App Update System
- **Automatic Checks**: Checks for updates on startup (configurable)
- **GitHub Integration**: Fetches latest releases from miyolist-public repository
- **Changelog Display**: See what's new before updating
- **Direct Download Links**: One-click download from GitHub
- **Reminder System**: 
  - Skip version option
  - Remind later (1/3/7/14/30 days)
  - Manual check anytime
- **Version Comparison**: Smart semantic versioning (major.minor.patch)
- **Settings Integration**: Full control in Profile settings

---

## ✨ Improvements & Enhancements

### 🎨 UI/UX Improvements
- **Status Filter Badges**: Show item counts for each status (Watching: 12, Completed: 45, etc.)
- **ALL Status Filter**: New filter to show all items regardless of status
- **Theme Customization**: Dark theme with accent colors
- **View Modes**: Grid, List, and Compact views for all media types
- **Responsive Design**: Better layouts for different screen sizes
- **Loading States**: Beautiful loading animations and empty states
- **Rich Text Support**: Markdown rendering with clickable AniList links

### 💾 Data Management
- **Image Cache System**: 
  - Configurable size limits (up to 2GB)
  - Auto-cleanup when limit exceeded
  - Manual cache clearing
  - Cache statistics display
- **Three-Tier Caching**: Hive → Supabase → AniList for optimal performance
- **Offline-First**: Works without internet, syncs when online
- **Conflict Resolution**: Smart handling of sync conflicts

### 🔗 Rich Text & Links
- **Markdown Support**: Full markdown rendering in descriptions
- **Clickable Links**: 
  - Anime links: `anime/12345`
  - Manga links: `manga/67890`
  - Character links: `character/11111`
  - User links: `user/username`
  - External URLs: Full support
- **Deep Linking**: Navigate directly to details pages

### 🚀 Performance
- **Rate Limiting**: Protects AniList API from overuse
- **Smart Caching**: Reduces API calls and improves speed
- **Lazy Loading**: Load data only when needed
- **Optimized Queries**: Efficient GraphQL queries
- **Memory Management**: Better resource handling

---

## 🛠️ Technical Updates

### Dependencies Added
- **package_info_plus ^8.3.1**: App version detection
- **path_provider**: File system access
- **shared_preferences**: Key-value storage
- **fl_chart**: Statistics visualization
- **flutter_local_notifications**: Notification support

### Architecture Improvements
- **Service Layer Pattern**: Clean separation of concerns
- **Feature-First Structure**: Better code organization
- **State Management**: Improved BLoC patterns
- **Error Handling**: Comprehensive error catching and reporting
- **Logging System**: Detailed debug and error logs

### Code Quality
- **Type Safety**: Strong typing throughout
- **Null Safety**: Full null-safety compliance
- **Code Documentation**: Comprehensive inline docs
- **Test Coverage**: ~45-50% coverage (49/55+ tests passing)

---

## 🐞 Bug Fixes

### Critical Fixes
- ✅ ScaffoldMessenger context error in filter dialogs
- ✅ Status filter showing incorrect counts
- ✅ Planned anime not appearing in calendar
- ✅ Duplicate parameters in UserSettings
- ✅ Import path errors in update system
- ✅ Unnecessary awaits on synchronous methods

### Minor Fixes
- ✅ Theme persistence across restarts
- ✅ Image cache overflow issues
- ✅ Sync conflict edge cases
- ✅ Search result ranking
- ✅ Date formatting inconsistencies

---

## 📚 Documentation

### New Documentation
- **APP_UPDATE_SYSTEM.md**: Complete update system guide (1000+ lines)
- **CHANGELOG_v1.5.0.md**: This changelog
- **About Dialog**: Updated with all new features

### Updated Documentation
- **TODO.md**: Marked completed features
- **README.md**: Updated feature list
- **API Documentation**: GraphQL query examples

---

## 🔜 Coming Soon (v2.0.0 Roadmap)

### Planned Features
1. **AI Companion** 🤖
   - Cute cat mascot with personality
   - Smart recommendations
   - Interactive conversations
   - Using Adorableninana's cat stickers

2. **Social Features** 👥
   - Follow other users
   - Activity feed
   - Comments and reactions
   - Share lists

3. **Advanced Recommendations** 🎯
   - Machine learning-based suggestions
   - Similar anime/manga finder
   - Personalized discovery
   - Trending analysis

4. **Custom Lists** 📝
   - Create custom collections
   - Share with friends
   - Import/export lists
   - Smart list management

5. **Notifications** 🔔
   - Episode release alerts
   - Manga chapter updates
   - Friend activity notifications
   - Custom notification rules

---

## 🙏 Credits & Thanks

### Special Thanks
- **AniList**: For the amazing GraphQL API
- **Supabase**: For backend infrastructure
- **Flutter Team**: For the excellent framework
- **Adorableninana**: For cute cat sticker assets (future AI Companion)
- **Community**: For feedback and bug reports

### Developer
Built with ❤️ by **Baconana-chan**

---

## 📦 Download & Installation

### Requirements
- Windows 10/11 (64-bit)
- 4GB RAM minimum
- 500MB free disk space
- Internet connection for sync features

### Download
- **GitHub Releases**: https://github.com/Baconana-chan/miyolist-public/releases
- **Latest Version**: v1.5.0+5

### Installation
1. Download the installer from GitHub releases
2. Run the `.exe` or `.msix` file
3. Follow installation wizard
4. Launch MiyoList
5. Sign in with AniList account

---

## 🐛 Known Issues

### Current Limitations
- ⚠️ Some deprecated Flutter APIs (non-critical warnings)
- ⚠️ Image cache may grow large without manual cleanup
- ⚠️ First sync can take time with large lists (1000+ entries)

### Workarounds
- Regularly clear image cache in settings
- Use selective sync for large lists
- Enable auto-cleanup in cache settings

---

## 📞 Support & Contact

### Report Issues
- **GitHub Issues**: https://github.com/Baconana-chan/miyolist/issues
- **Bug Reports**: Include version, OS, and steps to reproduce

### Feature Requests
- **GitHub Discussions**: Share your ideas!
- **Roadmap**: Check TODO.md for planned features

### Community
- **Discord**: Coming soon!
- **Reddit**: Coming soon!

---

## 📄 License

MIT License

Copyright (c) 2025 MiyoList Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

**Version**: 1.5.0+5  
**Build Date**: October 13, 2025  
**Status**: Development Build  
**Next Release**: v1.0.0 "Aoi (葵)" - Official Release
