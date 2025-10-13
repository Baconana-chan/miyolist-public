# 🎉 Welcome to MiyoList!

## 🌟 Current Version: v1.5.0-dev (Release Candidate)

**Target Release:** v1.0.0 "Aoi (葵)" - [Read about version naming](docs/VERSION_NAMING.md)

---

## 📚 Quick Navigation

### For Users
👉 **[Main README](README.md)** - Feature overview, download links, comparison table  
👉 **[Quick Start Guide](docs/QUICKSTART.md)** - Get started in 5 minutes  
👉 **[Website](https://miyo.my)** - Official MiyoList website  
👉 **[Download](https://github.com/Baconana-chan/miyolist-public/releases)** - Latest releases

### For Developers
👉 **[Setup Guide](docs/SETUP_COMPLETE.md)** - Development environment setup  
👉 **[OAuth Configuration](docs/OAUTH_SETUP.md)** - AniList API setup  
👉 **[TODO List](docs/TODO.md)** - Development roadmap  
👉 **[Release Summary](RELEASE_CANDIDATE_SUMMARY.md)** - v1.5.0-dev milestone

---

## ✅ What's Included in v1.5.0-dev

### 🏗️ Architecture
- ✅ Clean feature-based structure
- ✅ Separation of concerns (models, services, UI)
- ✅ Hive for local storage
- ✅ Supabase for cloud sync
- ✅ GraphQL for AniList API

### 📱 Features Implemented
- ✅ OAuth2 authentication with AniList
- ✅ User profile display
- ✅ Anime/Manga list viewing
- ✅ Status filtering (Watching, Completed, etc.)
- ✅ Favorites display
- ✅ Manga-style UI design
- ✅ Cross-platform support (Windows & Android)

### 🎨 Design
- ✅ Dark theme with manga aesthetics
- ✅ Custom colors (Red & Blue accents)
- ✅ Google Noto Sans font
- ✅ Panel-style cards with shadows
- ✅ Responsive layouts

### 📦 Code Quality
- ✅ No compilation errors
- ✅ Type-safe models with Hive
- ✅ Clean code structure
- ✅ Proper error handling foundations
- ✅ Generated files ready

## ⚠️ CRITICAL: Next Steps

### 1. Add Your AniList Client ID

**YOU MUST DO THIS or authentication won't work!**

1. Go to: https://anilist.co/settings/developer
2. Create new client with redirect URL: `miyolist://auth`
3. Copy your Client ID
4. Open: `lib/core/constants/app_constants.dart`
5. Replace:
   ```dart
   static const String anilistClientId = 'YOUR_ANILIST_CLIENT_ID';
   ```
   With your actual ID:
   ```dart
   static const String anilistClientId = '12345'; // Your real ID
   ```

### 2. Setup Supabase Database

**Required for cloud sync to work!**

1. Go to: https://your-project-id.supabase.co
2. Click "SQL Editor"
3. Copy contents of `supabase_schema.sql`
4. Paste and run
5. Verify 4 tables created:
   - `users`
   - `anime_lists`
   - `manga_lists`
   - `favorites`

### 3. (Windows Only) Register URL Scheme

**For deep linking to work on Windows:**

1. Build your app first (or use for production)
2. Edit `windows/miyolist-protocol.reg`
3. Update path to your .exe
4. Run as Administrator

For development, you can skip this step initially.

## 🚀 Run Your App

### Android
```bash
flutter run -d android
```

### Windows
```bash
flutter run -d windows
```

## 📚 Documentation Available

All documentation is in the project root:

- **README.md** - Complete documentation
- **QUICKSTART.md** - Quick setup guide
- **SETUP_COMPLETE.md** - Detailed setup instructions
- **OAUTH_SETUP.md** - OAuth troubleshooting
- **GRAPHQL_EXAMPLES.md** - API query examples
- **COMMANDS.md** - Useful command reference
- **TODO.md** - Feature roadmap
- **PROJECT_SUMMARY.md** - Project overview

## 🎯 What Works Right Now

After completing the setup steps above, you'll be able to:

1. **Login** - Authenticate with AniList via OAuth2
2. **View Lists** - See your anime and manga lists
3. **Filter** - Filter by status (Watching, Planning, etc.)
4. **Browse** - Scroll through your collection
5. **Profile** - View your profile and favorites
6. **Sync** - Data syncs to local and cloud storage

## 📋 Quick Test Checklist

- [ ] Added AniList Client ID
- [ ] Created Supabase tables
- [ ] Run `flutter run -d [platform]`
- [ ] See login screen
- [ ] Click "Login with AniList"
- [ ] Authorize the app
- [ ] See your lists
- [ ] Try filtering by status
- [ ] View profile page

## 🔧 If Something Goes Wrong

### Compilation Error?
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Authentication Fails?
- Check Client ID is correct
- Verify redirect URL is `miyolist://auth`
- Make sure no extra spaces in constants file

### Database Error?
- Verify SQL script ran successfully
- Check all tables exist in Supabase
- Review Supabase logs

### Lists Don't Show?
- Make sure you have entries in your AniList account
- Wait for initial sync to complete
- Check console logs for errors

## 🎨 Customization Ideas

### Change App Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color accentRed = Color(0xFFYOURCOLOR);
```

### Change App Name
- Android: `android/app/src/main/AndroidManifest.xml`
- Windows: `windows/runner/main.cpp`

### Add Features
Check `TODO.md` for a comprehensive list of features to add!

## 📊 Project Stats

- **Lines of Code**: ~3000+
- **Files Created**: 30+
- **Dependencies**: 30+
- **Platforms Supported**: 2 (Android, Windows)
- **Time to Set Up**: ~10 minutes (after reading docs)

## 🌟 What Makes This Special

1. **Manga-Inspired Design** - Unique aesthetic
2. **Smart Caching** - Fast and offline-capable
3. **Cross-Device Sync** - Work on any device
4. **Optimized API Usage** - Respects rate limits
5. **Clean Architecture** - Easy to extend
6. **Well Documented** - Comprehensive guides

## 🚀 Next Features to Add

Priority order from TODO.md:

1. **Edit Dialog** - Let users edit entries
2. **Search** - Find anime/manga
3. **Add to List** - Add new entries
4. **Statistics** - Show user stats
5. **Notifications** - Episode reminders

## 💡 Tips for Success

1. **Read the Docs** - Everything is documented
2. **Start Small** - Get login working first
3. **Test Often** - Use hot reload frequently
4. **Check Logs** - They're your best friend
5. **Ask for Help** - Open issues on GitHub

## 🎓 Learning Resources

- Flutter Docs: https://flutter.dev/docs
- AniList API: https://anilist.gitbook.io/anilist-apiv2-docs/
- Supabase Docs: https://supabase.com/docs
- Hive Docs: https://docs.hivedb.dev/

## 🤝 Contributing

Want to improve MiyoList?

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See TODO.md for ideas on what to work on!

## 📞 Support

Need help?

1. Check the documentation files
2. Review troubleshooting sections
3. Search for similar issues
4. Open a new issue with details:
   - Platform (Windows/Android)
   - Error message
   - Steps to reproduce
   - What you've tried

## 🎉 You're Ready to Start!

Your project is fully set up and ready to run. Just:

1. Add your AniList Client ID
2. Setup Supabase database
3. Run the app
4. Enjoy tracking your anime and manga!

**Have fun building your AniList client!** 🎌

---

## Quick Commands Reminder

```bash
# Run on Android
flutter run -d android

# Run on Windows  
flutter run -d windows

# Clean and rebuild
flutter clean && flutter pub get

# Generate files
flutter pub run build_runner build --delete-conflicting-outputs

# Check for errors
flutter analyze
```

---

*Project created: October 10, 2025*
*Status: Ready for Development*
*Version: 0.1.0*

**Happy Coding!** ✨
