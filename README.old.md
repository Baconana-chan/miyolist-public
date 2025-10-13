# MiyoList - Unofficial AniList Client

A modern, manga-styled AniList client for Windows and Android built with Flutter. Track your anime and manga lists with style, featuring local caching with Hive and cloud sync with Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-green)

## Features

- 🎨 **Manga-Inspired Design** - Beautiful dark theme with manga panel aesthetics
- 🔐 **AniList OAuth2** - Secure authentication via AniList
- 📱 **Cross-Platform** - Works on Windows and Android
- 💾 **Local Storage** - Fast access with Hive database
- ☁️ **Cloud Sync** - Seamless synchronization via Supabase (public profiles only)
- 🔒 **Privacy Control** - Choose between private (local-only) or public (cloud-synced) profiles
- � **Adult Content Filtering** - Respects AniList 18+ content settings
- ⏱️ **Smart Rate Limiting** - Prevents API spam (30 requests/minute)
- �📊 **List Management** - Easy anime and manga tracking
- ⭐ **Favorites** - View your favorite anime, manga, characters, staff, and studios
- 👤 **Profile Page** - Display your AniList profile info
- ⚡ **Offline Support** - Full functionality without internet connection

## Prerequisites

Before you begin, ensure you have:
- Flutter SDK 3.9.2 or higher
- An AniList account
- A Supabase project (already configured)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd miyolist
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure AniList OAuth2

1. Go to [AniList Settings - Developers](https://anilist.co/settings/developer)
2. Create a new API Client
3. Fill in the details:
   - **Name**: MiyoList (or your preferred name)
   - **Redirect URL**: 
     - For Android: `miyolist://auth`
     - For Windows: `miyolist://auth` (requires custom URL scheme registration)
     - Alternative for development: `http://localhost:8080/auth`

4. Copy your **Client ID**
5. Open `lib/core/constants/app_constants.dart`
6. Replace `YOUR_ANILIST_CLIENT_ID` with your actual Client ID:

```dart
static const String anilistClientId = 'YOUR_CLIENT_ID_HERE';
```

### 4. Configure Android Deep Linking

The project is already configured for the `miyolist://auth` scheme. To verify, check:

**`android/app/src/main/AndroidManifest.xml`** should contain:

```xml
<activity
    android:name=".MainActivity"
    ...>
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="miyolist" android:host="auth" />
    </intent-filter>
</activity>
```

### 5. Configure Windows Deep Linking

For Windows, you need to register the custom URL scheme:

1. Create a registry file `miyolist-protocol.reg`:

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

2. Replace the path with your actual executable path
3. Run the file as Administrator

### 6. Generate Hive Type Adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates the necessary adapter files for Hive:
- `user_model.g.dart`
- `anime_model.g.dart`
- `media_list_entry.g.dart`

### 7. Supabase Database Setup

The app is already configured to use your Supabase instance. Now you need to create the required tables:

#### Run these SQL commands in your Supabase SQL Editor:

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

### 8. Row Level Security (Optional but Recommended)

Enable RLS for security:

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

## Running the App

### Android

```bash
flutter run -d android
```

### Windows

```bash
flutter run -d windows
```

## Building for Release

### Android APK

```bash
flutter build apk --release
```

### Windows Executable

```bash
flutter build windows --release
```

## Project Structure

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

## Architecture

- **Local First**: Data is stored locally with Hive for instant access
- **Cloud Sync**: Supabase syncs data across devices (public profiles only)
- **Privacy Control**: Users choose between private (local-only) or public (cloud-synced) profiles
- **Optimized API**: Reduces AniList API calls by using cached data
- **Clean Architecture**: Feature-based structure with clear separation of concerns

## Privacy Profiles

### 🔒 Private Profile
- All data stored locally on device
- No cloud synchronization
- Complete offline functionality
- Perfect for single-device usage and maximum privacy

### 🌐 Public Profile  
- Local storage + cloud backup
- Cross-device synchronization
- Social features (coming soon)
- Perfect for multi-device users

**Learn more:** See [Privacy Feature Documentation](docs/PRIVACY_FEATURE.md)

## API Flow

1. **Login**: Authenticate via AniList OAuth2
2. **Profile Selection**: Choose private or public profile
3. **Initial Sync**: Fetch all lists and profile data from AniList
4. **Local Storage**: Save everything to Hive database
5. **Cloud Backup** (public only): Sync to Supabase for cross-device access
6. **Regular Use**: Read from local/Supabase, only update AniList when editing

## Documentation

- 📖 [Quick Start Guide](docs/QUICKSTART.md) - Get up and running fast
- ✅ [Setup Complete](docs/SETUP_COMPLETE.md) - What's already configured
- 🔐 [OAuth Setup](docs/OAUTH_SETUP.md) - AniList OAuth2 configuration
- 📝 [GraphQL Examples](docs/GRAPHQL_EXAMPLES.md) - AniList API queries
- 💻 [Available Commands](docs/COMMANDS.md) - Useful Flutter commands
- 🔒 [Privacy Feature](docs/PRIVACY_FEATURE.md) - Privacy profiles explained
- 📋 [TODO List](docs/TODO.md) - Upcoming features
- 📊 [Project Summary](docs/PROJECT_SUMMARY.md) - Technical overview

## Known Issues & TODOs

- [ ] Implement edit dialog for list entries
- [ ] Add search functionality
- [ ] Implement pull-to-refresh
- [ ] Add manga list support (similar to anime)
- [ ] Implement offline mode indicator
- [ ] Add statistics page
- [ ] Implement notification system
- [ ] Add custom lists support

## Technologies Used

- **Flutter** - Cross-platform framework
- **Hive** - Fast local NoSQL database
- **Supabase** - Backend as a Service (PostgreSQL)
- **GraphQL** - AniList API communication
- **OAuth2** - Secure authentication
- **Google Fonts** - Noto Sans for manga aesthetics

## Contributing

Contributions are welcome! Please feel free to submit pull requests.

## License

This project is unofficial and not affiliated with AniList. Use at your own discretion.

## Support

For issues and questions, please open an issue on GitHub.

---

**Note**: Remember to keep your AniList Client ID and Supabase credentials secure. Never commit them to public repositories!
