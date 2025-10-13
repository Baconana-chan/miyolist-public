# 🎌 Welcome to MiyoList!# 🎉 Welcome to MiyoList!



<div align="center">## 🌟 Current Version: v1.5.0-dev (Release Candidate)



**Modern AniList Client - Track your anime & manga with style****Target Release:** v1.0.0 "Aoi (葵)" - [Read about version naming](docs/VERSION_NAMING.md)



![Version](https://img.shields.io/badge/Version-v1.5.0--dev-orange)---

![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-blue)

## 📚 Quick Navigation

**Target Release:** v1.0.0 "Aoi (葵)" - [Learn about version naming](docs/VERSION_NAMING.md)

### For Users

[🌐 Website](https://miyo.my) • [📦 Releases](https://github.com/Baconana-chan/miyolist-public/releases) • [📚 Documentation](docs/)👉 **[Main README](README.md)** - Feature overview, download links, comparison table  

👉 **[Quick Start Guide](docs/QUICKSTART.md)** - Get started in 5 minutes  

</div>👉 **[Website](https://miyo.my)** - Official MiyoList website  

👉 **[Download](https://github.com/Baconana-chan/miyolist-public/releases)** - Latest releases

---

### For Developers

## 🚀 Quick Navigation👉 **[Setup Guide](docs/SETUP_COMPLETE.md)** - Development environment setup  

👉 **[OAuth Configuration](docs/OAUTH_SETUP.md)** - AniList API setup  

### 👤 For Users👉 **[TODO List](docs/TODO.md)** - Development roadmap  

- 📖 **[Main README](README.md)** - Feature overview, comparison table, download links👉 **[Release Summary](RELEASE_CANDIDATE_SUMMARY.md)** - v1.5.0-dev milestone

- ⚡ **[Quick Start Guide](docs/QUICKSTART.md)** - Get started in 5 minutes

- 🌐 **[Official Website](https://miyo.my)** - Visit miyo.my---

- 📦 **[Download Latest](https://github.com/Baconana-chan/miyolist-public/releases)** - Windows & Android

## ✅ What's Included in v1.5.0-dev

### 👨‍💻 For Developers

- 🛠️ **[Setup Guide](docs/SETUP_COMPLETE.md)** - Development environment setup### 🏗️ Architecture

- 🔐 **[OAuth Configuration](docs/OAUTH_SETUP.md)** - AniList API setup- ✅ Clean feature-based structure

- 📋 **[TODO List](docs/TODO.md)** - Development roadmap- ✅ Separation of concerns (models, services, UI)

- 📊 **[Release Summary](RELEASE_CANDIDATE_SUMMARY.md)** - v1.5.0-dev milestone- ✅ Hive for local storage

- ✅ Supabase for cloud sync

---- ✅ GraphQL for AniList API



## ✨ What's New in v1.5.0-dev (Release Candidate)### 📱 Features Implemented

- ✅ OAuth2 authentication with AniList

### 🔥 Critical Features- ✅ User profile display

- ✅ **Notification System** - In-app notifications from AniList (all types)- ✅ Anime/Manga list viewing

- ✅ **Airing Schedule** - Episode countdowns & today's releases- ✅ Status filtering (Watching, Completed, etc.)

- ✅ **Advanced Global Search** - All media types with adult content filter- ✅ Favorites display

- ✅ **Trending & Activity Feed** - Discover popular content- ✅ Manga-style UI design

- ✅ **Pagination System** - Handles 2000+ titles smoothly (50 items/page)- ✅ Cross-platform support (Windows & Android)

- ✅ **Cache Management** - Image cache with customizable limits (100MB-5GB)

### 🎨 Design

### 📊 Performance Improvements- ✅ Dark theme with manga aesthetics

- ⚡ **40x Faster** initial load with pagination- ✅ Custom colors (Red & Blue accents)

- 🖼️ **2000+ Images** cached for offline viewing- ✅ Google Noto Sans font

- 📦 **Customizable Cache** - 6 size options (100MB to 5GB)- ✅ Panel-style cards with shadows

- 🔄 **Auto-Refresh** - Updates every minute for accurate countdowns- ✅ Responsive layouts



---### 📦 Code Quality

- ✅ No compilation errors

## 🎯 What Makes MiyoList Special?- ✅ Type-safe models with Hive

- ✅ Clean code structure

| Feature | MiyoList | AniList Web | Other Clients |- ✅ Proper error handling foundations

|---------|----------|-------------|---------------|- ✅ Generated files ready

| **Offline Support** | ✅ Full | ❌ None | ⚠️ Limited |

| **Pagination** | ✅ 50/page | ❌ All at once | ⚠️ Varies |## ⚠️ CRITICAL: Next Steps

| **Image Caching** | ✅ 2000+ | ❌ None | ⚠️ Limited |

| **Bulk Operations** | ✅ Yes | ❌ No | ⚠️ Rarely |### 1. Add Your AniList Client ID

| **Privacy Control** | ✅ Local/Cloud | ❌ Always online | ⚠️ Varies |

| **Manga-styled UI** | ✅ Beautiful | ❌ Standard | ⚠️ Varies |**YOU MUST DO THIS or authentication won't work!**



---1. Go to: https://anilist.co/settings/developer

2. Create new client with redirect URL: `miyolist://auth`

## 🏗️ Architecture Overview3. Copy your Client ID

4. Open: `lib/core/constants/app_constants.dart`

### Core Technologies5. Replace:

- **Flutter 3.9.2+** - Cross-platform framework   ```dart

- **Hive** - Local NoSQL database (instant access)   static const String anilistClientId = 'YOUR_ANILIST_CLIENT_ID';

- **Supabase** - Cloud backup (optional)   ```

- **GraphQL** - AniList API integration   With your actual ID:

- **OAuth2** - Secure authentication   ```dart

   static const String anilistClientId = '12345'; // Your real ID

### Design Principles   ```

- 🔒 **Local-First** - Data stored locally for instant access

- 📱 **Offline-Ready** - Full functionality without internet### 2. Setup Supabase Database

- ☁️ **Smart Sync** - Optional cloud backup with conflict resolution

- 🎨 **Manga-Inspired** - Beautiful dark theme with kaomoji**Required for cloud sync to work!**

- 🔐 **Privacy-Focused** - Choose local-only or cloud-synced profiles

1. Go to: https://your-project-id.supabase.co

---2. Click "SQL Editor"

3. Copy contents of `supabase_schema.sql`

## 📱 Feature Highlights4. Paste and run

5. Verify 4 tables created:

### List Management   - `users`

- Complete anime & manga tracking (including light novels)   - `anime_lists`

- Multiple view modes (Grid, List, Compact)   - `manga_lists`

- Advanced filtering & sorting   - `favorites`

- Bulk operations (status changes, scoring, deletion)

- Custom lists support### 3. (Windows Only) Register URL Scheme

- Edit entries (score, progress, dates, notes, rewatches)

**For deep linking to work on Windows:**

### Discovery & Updates

- Airing schedule with countdown timers1. Build your app first (or use for production)

- Trending anime & manga2. Edit `windows/miyolist-protocol.reg`

- Activity feed from AniList community3. Update path to your .exe

- Advanced global search4. Run as Administrator

- Studio categorization

For development, you can skip this step initially.

### Sync & Privacy

- Local-first architecture## 🚀 Run Your App

- Supabase cloud sync (optional)

- Privacy profiles (local-only or public)### Android

- Selective sync (choose what to sync)```bash

- Conflict resolution (5 merge strategies)flutter run -d android

- Auto-sync with 2-minute delay```



### User Experience### Windows

- Manga-styled dark theme```bash

- Kaomoji system (expressive states)flutter run -d windows

- Loading states (smooth animations)```

- Empty states (helpful guidance)

- Pull-to-refresh## 📚 Documentation Available

- Crash reporting

All documentation is in the project root:

---

- **README.md** - Complete documentation

## 🎯 Path to v1.0.0 "Aoi (葵)"- **QUICKSTART.md** - Quick setup guide

- **SETUP_COMPLETE.md** - Detailed setup instructions

### Current Status: v1.5.0-dev (Release Candidate) ✅- **OAUTH_SETUP.md** - OAuth troubleshooting

All critical features implemented and tested.- **GRAPHQL_EXAMPLES.md** - API query examples

- **COMMANDS.md** - Useful command reference

### Remaining Tasks for Official Release:- **TODO.md** - Feature roadmap

- ⚠️ **Unit Tests** - Target 60%+ coverage- **PROJECT_SUMMARY.md** - Project overview

- ⚠️ **Beta Testing** - Community testing program

- ⚠️ **Performance Profiling** - Optimize bottlenecks## 🎯 What Works Right Now

- ⚠️ **Final Polish** - UX review and bug fixes

After completing the setup steps above, you'll be able to:

### Estimated Timeline: 4-6 weeks

1. **Login** - Authenticate with AniList via OAuth2

---2. **View Lists** - See your anime and manga lists

3. **Filter** - Filter by status (Watching, Planning, etc.)

## 🚀 Post-Release Roadmap4. **Browse** - Scroll through your collection

5. **Profile** - View your profile and favorites

### v1.1.0 (Q1 2026)6. **Sync** - Data syncs to local and cloud storage

- Push Notifications (background episode alerts)

- Annual Wrap-up (personalized statistics)## 📋 Quick Test Checklist

- Taste Compatibility Score

- [ ] Added AniList Client ID

### v1.2.0 (Q2 2026)- [ ] Created Supabase tables

- **Manga Chapter Notifications** (via external service)- [ ] Run `flutter run -d [platform]`

  - *Addresses AniList API limitation (no manga airing schedule)*- [ ] See login screen

- AI Companion (personalized recommendations)- [ ] Click "Login with AniList"

- Advanced Analytics- [ ] Authorize the app

- [ ] See your lists

### v1.3.0+ (Future)- [ ] Try filtering by status

- Social Features- [ ] View profile page

- Multi-language Support

- iOS/macOS Support## 🔧 If Something Goes Wrong



📄 **Full Roadmap:** [POST_RELEASE_ROADMAP.md](docs/POST_RELEASE_ROADMAP.md)### Compilation Error?

```bash

---flutter clean

flutter pub get

## 🛠️ Developer Setupflutter pub run build_runner build --delete-conflicting-outputs

```

### Prerequisites

- Flutter SDK 3.9.2+### Authentication Fails?

- An AniList account- Check Client ID is correct

- A Supabase project (optional, for cloud sync)- Verify redirect URL is `miyolist://auth`

- Make sure no extra spaces in constants file

### Quick Setup

### Database Error?

```bash- Verify SQL script ran successfully

# Clone the repository- Check all tables exist in Supabase

git clone https://github.com/Baconana-chan/miyolist-public.git- Review Supabase logs

cd miyolist-public

### Lists Don't Show?

# Install dependencies- Make sure you have entries in your AniList account

flutter pub get- Wait for initial sync to complete

- Check console logs for errors

# Generate Hive adapters

flutter pub run build_runner build --delete-conflicting-outputs## 🎨 Customization Ideas



# Run the app### Change App Colors

flutter runEdit `lib/core/theme/app_theme.dart`:

``````dart

static const Color accentRed = Color(0xFFYOURCOLOR);

### ⚠️ IMPORTANT: Configuration```



#### 1. Add Your AniList Client ID### Change App Name

1. Go to [AniList Developer Settings](https://anilist.co/settings/developer)- Android: `android/app/src/main/AndroidManifest.xml`

2. Create new client with redirect URL: `miyolist://auth`- Windows: `windows/runner/main.cpp`

3. Copy your Client ID

4. Open `lib/core/constants/app_constants.dart`### Add Features

5. Replace `YOUR_ANILIST_CLIENT_ID` with your actual IDCheck `TODO.md` for a comprehensive list of features to add!



#### 2. Setup Supabase (Optional)## 📊 Project Stats

**Required only if you want cloud sync:**

1. Run SQL commands from `supabase_schema.sql`- **Lines of Code**: ~3000+

2. Verify 4 tables created: `users`, `anime_lists`, `manga_lists`, `favorites`- **Files Created**: 30+

- **Dependencies**: 30+

📖 **Detailed Setup:** [OAuth Setup Guide](docs/OAUTH_SETUP.md)- **Platforms Supported**: 2 (Android, Windows)

- **Time to Set Up**: ~10 minutes (after reading docs)

---

## 🌟 What Makes This Special

## 📚 Documentation Index

1. **Manga-Inspired Design** - Unique aesthetic

### User Guides2. **Smart Caching** - Fast and offline-capable

- 📖 [Quick Start Guide](docs/QUICKSTART.md)3. **Cross-Device Sync** - Work on any device

- 🔐 [Privacy Feature](docs/PRIVACY_FEATURE.md)4. **Optimized API Usage** - Respects rate limits

- 🎨 [Theme System](docs/THEME_SYSTEM.md)5. **Clean Architecture** - Easy to extend

- 📊 [Statistics Page](docs/STATISTICS_PAGE.md)6. **Well Documented** - Comprehensive guides



### Developer Docs## 🚀 Next Features to Add

- ✅ [Setup Complete](docs/SETUP_COMPLETE.md)

- 🔐 [OAuth Setup](docs/OAUTH_SETUP.md)Priority order from TODO.md:

- 📝 [GraphQL Examples](docs/GRAPHQL_EXAMPLES.md)

- 💻 [Available Commands](docs/COMMANDS.md)1. **Edit Dialog** - Let users edit entries

- 🔄 [Conflict Resolution](docs/CONFLICT_RESOLUTION.md)2. **Search** - Find anime/manga

- 📋 [TODO List](docs/TODO.md)3. **Add to List** - Add new entries

4. **Statistics** - Show user stats

### Feature Docs5. **Notifications** - Episode reminders

- 🔔 [Notification System](docs/NOTIFICATION_SYSTEM.md)

- 🎬 [Airing Schedule](docs/AUTO_REFRESH.md)## 💡 Tips for Success

- 🔍 [Advanced Search](docs/FILTERING_SORTING.md)

- 📦 [Custom Lists](docs/CUSTOM_LISTS.md)1. **Read the Docs** - Everything is documented

- 🖼️ [Offline Images](docs/OFFLINE_IMAGE_CACHING.md)2. **Start Small** - Get login working first

- 🚨 [Crash Reporting](docs/CRASH_REPORTING.md)3. **Test Often** - Use hot reload frequently

4. **Check Logs** - They're your best friend

### Release Docs5. **Ask for Help** - Open issues on GitHub

- 📊 [Release Candidate Summary](RELEASE_CANDIDATE_SUMMARY.md)

- 📝 [Update Summary (Oct 12)](UPDATE_SUMMARY_OCT12.md)## 🎓 Learning Resources

- 🎌 [Version Naming Explanation](docs/VERSION_NAMING.md)

- Flutter Docs: https://flutter.dev/docs

---- AniList API: https://anilist.gitbook.io/anilist-apiv2-docs/

- Supabase Docs: https://supabase.com/docs

## 💡 Key Features Explained- Hive Docs: https://docs.hivedb.dev/



### 🔔 Why In-App Notifications?## 🤝 Contributing

MiyoList provides comprehensive in-app notifications from AniList, including:

- Episode airing alertsWant to improve MiyoList?

- Activity notifications (likes, comments, follows)

- Forum updates1. Fork the repository

- Media updates2. Create a feature branch

3. Make your changes

**Note:** For background push notifications, see v1.1.0+ roadmap.4. Submit a pull request



### 📄 Why Pagination?See TODO.md for ideas on what to work on!

For users with 2000+ titles in their list:

- **Before:** Slow initial load (all items at once)## 📞 Support

- **After:** Instant load (50 items per page) → **40x faster**

Need help?

### 🖼️ Why Cache Management?

- Offline image viewing (2000+ images)1. Check the documentation files

- Customizable limits (100MB to 5GB)2. Review troubleshooting sections

- Auto-cleanup of old cache (30+ days)3. Search for similar issues

- User control over storage4. Open a new issue with details:

   - Platform (Windows/Android)

### 🌐 Why Privacy Profiles?   - Error message

**Private (Local-only):**   - Steps to reproduce

- Maximum privacy   - What you've tried

- No cloud storage

- Single-device usage## 🎉 You're Ready to Start!



**Public (Cloud-synced):**Your project is fully set up and ready to run. Just:

- Cross-device sync

- Backup to Supabase1. Add your AniList Client ID

- Social features (future)2. Setup Supabase database

3. Run the app

---4. Enjoy tracking your anime and manga!



## 🤝 Contributing**Have fun building your AniList client!** 🎌



Contributions are welcome! Ways to help:---



- 🐛 **Report Bugs** - [Open an issue](https://github.com/Baconana-chan/miyolist-public/issues)## Quick Commands Reminder

- 💡 **Suggest Features** - Share your ideas

- 🔧 **Submit PRs** - Code contributions appreciated```bash

- 📖 **Improve Docs** - Help others get started# Run on Android

- ⭐ **Star the Repo** - Show your support!flutter run -d android



---# Run on Windows  

flutter run -d windows

## 📜 License

# Clean and rebuild

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.flutter clean && flutter pub get



---# Generate files

flutter pub run build_runner build --delete-conflicting-outputs

## ⚠️ Disclaimer

# Check for errors

MiyoList is an **unofficial** third-party client and is **not affiliated with AniList**. All anime/manga data is provided by the [AniList API](https://anilist.co/).flutter analyze

```

Use at your own discretion. Please respect AniList's [Terms of Service](https://anilist.co/terms).

---

---

*Project created: October 10, 2025*

## 💖 Support & Contact*Status: Ready for Development*

*Version: 0.1.0*

- 🌐 **Website:** [miyo.my](https://miyo.my)

- 📦 **Releases:** [GitHub Releases](https://github.com/Baconana-chan/miyolist-public/releases)**Happy Coding!** ✨

- 🐛 **Issues:** [GitHub Issues](https://github.com/Baconana-chan/miyolist-public/issues)
- 📧 **Contact:** Open an issue for support

---

<div align="center">

**Made with ❤️ by the MiyoList team**

🌸 *Blue skies ahead* 🌸

**MiyoList v1.5.0-dev → v1.0.0 "Aoi (葵)"**

[⬆ Back to Top](#-welcome-to-miyolist)

</div>
