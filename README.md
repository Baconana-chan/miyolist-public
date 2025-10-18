# 🎌 MiyoList - Unofficial AniList Client

<div align="center">
A modern, manga-styled AniList client for Windows, Linux, macOS, and Android, built with Flutter. Track your anime and manga lists with style, featuring local caching with Hive and cloud sync with Supabase.

**Track your anime & manga with style**

![Flutter](https://img.shields.io/badge/Flutter-3.35.5-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS%20%7C%20Android-green)
[![Version](https://img.shields.io/badge/Version-v1.1.0%20Botan-ff69b4)](https://github.com/Baconana-chan/miyolist/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/Baconana-chan/miyolist/ci.yml?label=CI)](https://github.com/Baconana-chan/miyolist/actions)

[**🌐 Website**](https://miyo.my) • [**📦 Download**](https://github.com/Baconana-chan/miyolist/releases) • [**📚 Docs**](docs/) • [**🐛 Report Bug**](https://github.com/Baconana-chan/miyolist/issues)
</div>

---

## ✨ Why MiyoList?

MiyoList is an **unofficial AniList client** that elevates your anime and manga tracking with:

- 🎨 **Manga-Inspired Design**: Beautiful dark theme with manga panel aesthetics.
- 🔐 **AniList OAuth2**: Secure authentication via AniList.
- 📱 **Cross-Platform**: Works on Windows, Linux, macOS, and Android.
- 💾 **Local Storage**: Fast access with Hive database.
- ☁️ **Cloud Sync**: Seamless synchronization via Supabase (public profiles only).
- 🔒 **Privacy Control**: Choose between private (local-only) or public (cloud-synced) profiles.
- 🚫 **Adult Content Filtering**: Respects AniList 18+ content settings.
- ⏱️ **Smart Rate Limiting**: Prevents API spam (30 requests/minute).
- 📊 **List Management**: Easy anime and manga tracking with bulk operations and custom lists.
- ⭐ **Favorites**: View your favorite anime, manga, characters, staff, and studios.
- ⚡ **Offline Support**: Full functionality without an internet connection.
- 🔄 **Smart Sync**: Intelligent cloud backup with conflict resolution.
- 🔔 **Real-time Updates**: Airing schedules, trending feed, and episode countdowns.

---

## 🚀 Key Features

### � Social & Community
- ✅ **Following System**: Follow users and view their profiles.
- ✅ **Friend System**: Mutual follows with friend requests and management.
- ✅ **Activity Feed**: Like, reply, and post your own text activities.
- ✅ **Activity Interactions**: Subscribe to activities and track engagement.
- ✅ **Donator Badges**: Display AniList supporter status with special badges.

### �📊 List Management
- ✅ Complete anime & manga tracking (including light novels).
- ✅ Multiple view modes (Grid, List, Compact).
- ✅ Advanced filtering & sorting (by status, score, progress, date).
- ✅ Bulk operations (status changes, scoring, deletion).
- ✅ Custom lists support for flexible organization.
- ✅ Edit entries with all fields (score, progress, dates, notes, rewatches).
- ✅ Pagination for smooth handling of 2000+ titles (50 items/page).

### 🔔 Stay Updated
- ✅ Airing schedule with countdown timers.
- ✅ Trending feed to discover popular anime & manga.
- ✅ Activity feed to track AniList community activity.
- ✅ Today's releases with quick access to airing episodes.
- ✅ Auto-refresh every minute for accurate countdowns.

### 🔍 Discovery
- ✅ Advanced global search across all media types.
- ✅ Adult content filter respecting AniList 18+ settings.
- ✅ Studio categorization for browsing by animation studios.
- ✅ Favorites display (anime, manga, characters, staff, studios).

### ☁️ Sync & Privacy
- ✅ Local-first architecture with Hive for instant access.
- ✅ Supabase cloud sync for backup & cross-device access.
- ✅ Privacy profiles: private (local-only) or public (cloud-synced).
- ✅ Selective sync to control what data syncs (anime, manga, favorites, profile).
- ✅ Conflict resolution with 5 merge strategies (Last-Write-Wins, Prefer Local/Cloud/AniList, Manual).
- ✅ Auto-sync with a 2-minute delay after edits.

### 🎨 User Experience
- ✅ Manga-styled dark theme with authentic aesthetics.
- ✅ Kaomoji system for expressive empty states & loading indicators.
- ✅ Image caching for offline viewing (2000+ images).
- ✅ **Offline Content Settings**: Choose exactly what content to cache (lists, favorites, characters, staff, banners, trending, search results).
- ✅ Cache management with customizable size limits (100MB-5GB).
- ✅ Smooth loading animations and pull-to-refresh.
- ✅ Crash reporting with automatic error detection & export.
- ✅ **Enhanced Push Notifications**: Better notification handling across platforms.

---

## 📥 Installation

### Platforms
- 🪟 **Windows 10/11**: Download `.exe` installer or portable `.zip`.
- 🤖 **Android 8.0+**: Download `.apk` file.
- 🐧 **Linux (x64)**: Download `.tar.gz` (automatically built via GitHub Actions).
- 🍎 **macOS**: Download `.dmg` (automatically built via GitHub Actions).

### Quick Start
1. Download the appropriate version from [GitHub Releases](https://github.com/Baconana-chan/miyolist/releases).
2. Install and launch MiyoList.
3. Sign in with your AniList account (OAuth2).
4. Choose privacy profile (Private or Public).
5. Start tracking your anime & manga!

### Platform-Specific Installation

#### Linux
```bash
tar -xzf miyolist-linux-x64.tar.gz
cd miyolist
./miyolist
```

#### macOS
1. Open `miyolist-macos.dmg`
2. Drag MiyoList to Applications folder
3. Right-click → Open (first time only, to bypass Gatekeeper)

📖 **Detailed Setup**: [Quick Start Guide](docs/QUICKSTART.md)
🤖 **CI/CD Info**: [GitHub Actions Setup](GITHUB_ACTIONS.md)

---

## 🛠️ For Developers

### Prerequisites
- Flutter SDK 3.35.5 or higher.
- An AniList account.
- A Supabase project (optional, for cloud sync).
- **JDK 17** (for Android builds).

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Baconana-chan/miyolist.git
   cd miyolist
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure AniList OAuth2**
   - Go to [AniList Settings - Developers](https://anilist.co/settings/developer).
   - Create a new API Client with:
     - **Name**: MiyoList (or your preferred name).
     - **Redirect URL**:
       - Android: `miyolist://auth`
       - Windows: `miyolist://auth` (requires custom URL scheme registration)
       - Development: `http://localhost:8080/auth`
   - Copy your **Client ID**.
   - Open `lib/core/constants/app_constants.dart` and replace:
     ```dart
     static const String anilistClientId = 'YOUR_CLIENT_ID_HERE';
     ```

4. **Configure Android Deep Linking**
   Verify `android/app/src/main/AndroidManifest.xml` contains:
   ```xml
   <activity android:name=".MainActivity" ...>
       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data android:scheme="miyolist" android:host="auth" />
       </intent-filter>
   </activity>
   ```

5. **Configure Windows Deep Linking**
   - Create a registry file `miyolist-protocol.reg`:
     ```reg
     Windows Registry Editor Version 5.00
     [HKEY_CLASSES_ROOT\miyolist]
     @="URL:MiyoList Protocol"
     "URL Protocol"=""
     [HKEY_CLASSES_ROOT\miyolist\shell]
     [HKEY_CLASSES_ROOT\miyolist\shell\open]
     [HKEY_CLASSES_ROOT\miyolist\shell\open\command]
     @="\"C:\\Path\\To\\Your\\miyolist.exe\" \"%1\""
     ```
   - Replace the path with your actual executable path.
   - Run the file as Administrator.

6. **Generate Hive Type Adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   This generates adapter files: `user_model.g.dart`, `anime_model.g.dart`, `media_list_entry.g.dart`.

7. **Supabase Database Setup**
   Run these SQL commands in your Supabase SQL Editor:
   ```sql
   -- Users table
   CREATE TABLE users (
       id BIGINT PRIMARY KEY,
       name TEXT NOT NULL,
       avatar TEXT,
       banner_image TEXT,
       about TEXT,
       created_at TIMESTAMPTZ,
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );

   -- Anime lists table
   CREATE TABLE anime_lists (
       id BIGINT PRIMARY KEY,
       user_id BIGINT NOT NULL REFERENCES users(id),
       media_id BIGINT NOT NULL,
       status TEXT NOT NULL,
       score DOUBLE PRECISION,
       progress INT DEFAULT 0,
       repeat INT,
       notes TEXT,
       started_at TIMESTAMPTZ,
       completed_at TIMESTAMPTZ,
       updated_at TIMESTAMPTZ,
       synced_at TIMESTAMPTZ DEFAULT NOW(),
       media JSONB
   );

   -- Manga lists table
   CREATE TABLE manga_lists (
       id BIGINT PRIMARY KEY,
       user_id BIGINT NOT NULL REFERENCES users(id),
       media_id BIGINT NOT NULL,
       status TEXT NOT NULL,
       score DOUBLE PRECISION,
       progress INT DEFAULT 0,
       progress_volumes INT,
       repeat INT,
       notes TEXT,
       started_at TIMESTAMPTZ,
       completed_at TIMESTAMPTZ,
       updated_at TIMESTAMPTZ,
       synced_at TIMESTAMPTZ DEFAULT NOW(),
       media JSONB
   );

   -- Favorites table
   CREATE TABLE favorites (
       user_id BIGINT PRIMARY KEY REFERENCES users(id),
       data JSONB NOT NULL,
       synced_at TIMESTAMPTZ DEFAULT NOW()
   );

   -- Create indexes for better performance
   CREATE INDEX idx_anime_lists_user_id ON anime_lists(user_id);
   CREATE INDEX idx_manga_lists_user_id ON manga_lists(user_id);
   ```

8. **Row Level Security (Optional but Recommended)**
   ```sql
   -- Enable RLS
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   ALTER TABLE anime_lists ENABLE ROW LEVEL SECURITY;
   ALTER TABLE manga_lists ENABLE ROW LEVEL SECURITY;
   ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

   -- Allow users to read/write their own data
   CREATE POLICY "Users can view own data" ON users FOR SELECT USING (true);
   CREATE POLICY "Users can update own data" ON users FOR ALL USING (true);
   CREATE POLICY "Users can view own anime lists" ON anime_lists FOR SELECT USING (true);
   CREATE POLICY "Users can manage own anime lists" ON anime_lists FOR ALL USING (true);
   CREATE POLICY "Users can view own manga lists" ON manga_lists FOR SELECT USING (true);
   CREATE POLICY "Users can manage own manga lists" ON manga_lists FOR ALL USING (true);
   CREATE POLICY "Users can view own favorites" ON favorites FOR SELECT USING (true);
   CREATE POLICY "Users can manage own favorites" ON favorites FOR ALL USING (true);
   ```

### Running the App
- **Android**:
  ```bash
  flutter run -d android
  ```
- **Windows**:
  ```bash
  flutter run -d windows
  ```

### Building for Release
- **Android APK**:
  ```bash
  flutter build apk --release
  ```
- **Windows Executable**:
  ```bash
  flutter build windows --release
  ```

### Project Structure
```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── anime_model.dart
│   │   └── media_list_entry.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── anilist_service.dart
│   │   ├── local_storage_service.dart
│   │   └── supabase_service.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── pages/
│   │           └── login_page.dart
│   ├── anime_list/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── anime_list_page.dart
│   │       └── widgets/
│   │           └── media_list_card.dart
│   └── profile/
│       └── presentation/
│           └── pages/
│               └── profile_page.dart
└── main.dart
```

### Architecture
- **Local-First**: Data stored locally with Hive for instant access.
- **Cloud Sync**: Supabase syncs data across devices (public profiles only).
- **Clean Architecture**: Feature-based structure with clear separation of concerns.
- **State Management**: Provider pattern.
- **Optimized API**: Reduces AniList API calls using cached data.

---

## 📚 Documentation

### User Guides
- [Quick Start Guide](docs/QUICKSTART.md): Get up and running fast.
- [Privacy Feature](docs/PRIVACY_FEATURE.md): Privacy profiles explained.
- [Theme System](docs/THEME_SYSTEM.md): UI customization.
- [Statistics Page](docs/STATISTICS_PAGE.md): Track your watching habits.

### Developer Docs
- [Setup Complete](docs/SETUP_COMPLETE.md): What's already configured.
- [OAuth Setup](docs/OAUTH_SETUP.md): AniList OAuth2 configuration.
- [GraphQL Examples](docs/GRAPHQL_EXAMPLES.md): AniList API queries.
- [Available Commands](docs/COMMANDS.md): Useful Flutter commands.
- [Conflict Resolution](docs/CONFLICT_RESOLUTION.md): Sync strategies.
- [TODO List](docs/TODO.md): Development roadmap.

### Feature Docs
- [Notification System](docs/NOTIFICATION_SYSTEM.md): In-app alerts.
- [Airing Schedule](docs/AUTO_REFRESH.md): Episode tracking.
- [Advanced Search](docs/FILTERING_SORTING.md): Search & filters.
- [Custom Lists](docs/CUSTOM_LISTS.md): List organization.
- [Offline Images](docs/OFFLINE_IMAGE_CACHING.md): Image caching.
- [Offline Content Settings](OFFLINE_CONTENT_SETTINGS.md): Flexible content caching.
- [Java 17 Upgrade](JAVA_17_UPGRADE.md): Android build improvements.
- [Crash Reporting](docs/CRASH_REPORTING.md): Error handling.

---

## 🎯 Roadmap

### v1.1.0 "Botan (牡丹)" (Current Release) 🌸
- [x] Social features (Following System).
- [x] Friend System with mutual follows and friend requests.
- [x] Activity interactions (like, reply, post).
- [x] Donator badges for AniList supporters.
- [x] Offline content settings (7 content types).
- [x] Java 17 upgrade for Android builds.
- [x] Enhanced push notifications for Windows and Android.
- [x] Multiple bug fixes and performance improvements.

### v1.5.0-dev (Previous) ✅
- [x] Airing schedule with countdowns.
- [x] Trending & activity feed.
- [x] Advanced global search.
- [x] Notification system (in-app).
- [x] Pagination for large lists.
- [x] Cache management UI.

### v1.0.0 "Aoi (葵)" (First Official Release) 🎊
- [x] Unit tests (60%+ coverage).
- [x] Beta testing program.
- [x] Performance optimization.
- [x] Final polish & bug fixes.
- [x] Named version release (Blue/Hollyhock - symbolizing new beginnings).

### v1.2.0+ (Future) 🔮
- [ ] Push notifications for background episode alerts.
- [ ] Annual wrap-up with personalized statistics.
- [ ] Taste compatibility score.
- [ ] Advanced social features (comments, threads).

### v1.3.0+ (Long-term) 🌟
- [ ] Manga chapter notifications (via external service due to AniList API limitations).
- [ ] AI companion for personalized recommendations.
- [ ] Advanced analytics dashboard.
- [ ] Multi-language support.

📄 **Full Roadmap**: [POST_RELEASE_ROADMAP.md](docs/POST_RELEASE_ROADMAP.md) • [TODO.md](docs/TODO.md)

---

## 🌟 Why Choose MiyoList?

| Feature                      | MiyoList          | AniList Web       | AL-chan           | Taiga             | AniHyou           |
|------------------------------|-------------------|-------------------|-------------------|-------------------|-------------------|
| **Offline Support**          | ✅ Full           | ❌ None           | ⚠️ Limited        | ✅ Full           | ⚠️ Limited        |
| **Pagination**               | ✅ 50/page        | ⚠️ Infinite scroll| ❌ No             | ✅ Yes            | ❌ No             |
| **Image Caching**            | ✅ 2000+ images   | ❌ None           | ⚠️ Basic          | ✅ Full           | ⚠️ Basic          |
| **Offline Content Control**  | ✅ 7 types        | ❌ None           | ❌ None           | ⚠️ Basic          | ❌ None           |
| **Airing Schedule**          | ✅ With countdowns| ✅ Yes            | ✅ Yes            | ✅ Yes            | ✅ Yes            |
| **Bulk Operations**          | ✅ Yes            | ❌ No             | ❌ No             | ⚠️ Limited        | ❌ No             |
| **Conflict Resolution**      | ✅ 5 strategies   | ❌ None           | ❌ None           | ⚠️ Basic          | ❌ None           |
| **Privacy Control**          | ✅ Local/Cloud    | ❌ Always online  | ❌ Cloud only     | ✅ Local only     | ❌ Cloud only     |
| **Custom Lists**             | ✅ Full support   | ✅ Yes            | ✅ Yes            | ❌ No             | ✅ Yes            |
| **Manga-styled UI**          | ✅ Unique theme   | ❌ Standard       | ✅ Anime-styled   | ❌ Standard       | ✅ Material       |
| **Cross-Platform**           | ✅ Win/Android    | ✅ Web            | ✅ Android        | ✅ Windows        | ✅ Android/iOS    |
| **Push Notifications**       | ✅ Yes (v1.1.0)   | ❌ None           | ✅ Yes            | ❌ No             | ✅ Yes            |
| **Social Features**          | ✅ Yes (v1.1.0)   | ✅ Full           | ⚠️ Basic          | ⚠️ Basic          | ✅ Full           |
| **Friend System**            | ✅ Yes (v1.1.0)   | ✅ Yes            | ⚠️ Basic          | ❌ No             | ✅ Yes            |
| **Activity Feed**            | ✅ Yes (v1.1.0)   | ✅ Full           | ⚠️ Basic          | ❌ No             | ✅ Full           |
| **MAL Integration**          | 🔜 Future         | ❌ No             | ❌ No             | ✅ Yes            | ❌ No             |
| **iOS Support**              | 🔜 Future         | ✅ Yes (Web)      | ❌ No             | ❌ No             | ✅ Yes            |
| **Anime Tracking**           | ✅ Advanced       | ✅ Full           | ✅ Full           | ✅ Full           | ✅ Full           |
| **Manga Tracking**           | ✅ Advanced       | ✅ Full           | ✅ Full           | ❌ No             | ✅ Full           |
| **Statistics Dashboard**     | ✅ Comprehensive  | ✅ Advanced       | ⚠️ Basic          | ✅ Detailed       | ✅ Good           |
| **Open Source**              | ✅ MIT License    | ❌ Proprietary    | ✅ GPL-3.0        | ✅ GPL-3.0        | ✅ GPL-3.0        |

**Legend:** ✅ Full Support | ⚠️ Partial/Limited | ❌ Not Available | 🔜 Planned

**Our Strengths:**
- 🎯 **Offline-First** - Best offline support among all clients with granular control
- ⚡ **Performance** - Pagination handles 2000+ titles smoothly
- 🔄 **Sync Flexibility** - Unique local/cloud choice with conflict resolution
- 🎨 **Unique UI** - Manga-inspired aesthetics
- 📦 **Bulk Operations** - Efficient multi-item management
- 👥 **Social Features** - Following, friends, and activity interactions (v1.1.0)

**Where We're Growing:**
- 📱 iOS support in future releases
- 🔗 MAL integration consideration for v2.0+
- 🌐 Advanced social features (threads, detailed comments)

**Why This Matters:**
We focus on **performance, privacy, and user control** - features that matter for power users with large libraries. With v1.1.0 "Botan", we've added comprehensive social features while maintaining our core strengths in offline functionality and performance.

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:
- 🐛 **Report Bugs**: [Open an issue](https://github.com/Baconana-chan/miyolist/issues).
- 💡 **Suggest Features**: Share your ideas.
- 🔧 **Submit PRs**: Code contributions appreciated.
- 📖 **Improve Docs**: Help others get started.
- ⭐ **Star the Repo**: Show your support!

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

---

## ⚠️ Disclaimer

MiyoList is an **unofficial** third-party client and is **not affiliated with AniList**. All anime/manga data is provided by the [AniList API](https://anilist.co/). Use at your own discretion and respect AniList's [Terms of Service](https://anilist.co/terms).

---

## 💖 Support

- 🌐 **Website**: [miyo.my](https://miyo.my)
- 📦 **Releases**: [GitHub Releases](https://github.com/Baconana-chan/miyolist/releases)
- 🐛 **Issues**: [GitHub Issues](https://github.com/Baconana-chan/miyolist/issues)
- 📧 **Contact**: Open an issue for support

---

<div align="center">
**Made with ❤️ by Baconana-chan**

[⬆ Back to Top](#-miyolist---unofficial-anilist-client)
</div>