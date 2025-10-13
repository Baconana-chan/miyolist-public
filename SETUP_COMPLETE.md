# 🚀 Complete Setup Instructions

## Part 1: Prerequisites

Before you begin, make sure you have:
- ✅ Flutter installed (3.9.2 or higher)
- ✅ Android Studio or VS Code
- ✅ Git installed
- ✅ AniList account created
- ✅ Supabase account created

## Part 2: Project Setup

### 1. Clone/Open the Project
Your project is already in: `c:\Users\VIC\flutter_project\miyolist`

### 2. Install Dependencies (Already Done ✓)
```bash
flutter pub get
```

### 3. Generate Required Files ⚠️ CRITICAL
This is **REQUIRED** for the app to compile:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**What this does:**
- Generates `user_model.g.dart`
- Generates `anime_model.g.dart`
- Generates `media_list_entry.g.dart`

**These files are needed for Hive to work!**

### 4. Verify Generation
Check that these files now exist:
- `lib/core/models/user_model.g.dart`
- `lib/core/models/anime_model.g.dart`
- `lib/core/models/media_list_entry.g.dart`

## Part 3: AniList OAuth Setup

### Step 1: Create API Client
1. Login to AniList: https://anilist.co
2. Go to: https://anilist.co/settings/developer
3. Click: **"Create New Client"**

### Step 2: Fill in Details
```
Name: MiyoList
Redirect URL: miyolist://auth
```

**Important Notes:**
- Redirect URL must be EXACTLY `miyolist://auth`
- No trailing slashes
- Case sensitive
- AniList allows only ONE redirect URL per client

### Step 3: Save and Copy
1. Click **"Save"**
2. Your **Client ID** will be displayed
3. Copy this number (it will look like: 12345)

### Step 4: Update App
1. Open: `lib/core/constants/app_constants.dart`
2. Find this line:
   ```dart
   static const String anilistClientId = 'YOUR_ANILIST_CLIENT_ID';
   ```
3. Replace with your actual Client ID:
   ```dart
   static const String anilistClientId = '12345'; // Your actual ID
   ```
4. Save the file

## Part 4: Supabase Setup

### Step 1: Access Your Project
Your Supabase project is at:
- URL: https://your-project-id.supabase.co
- Project is already configured in the app ✓

### Step 2: Create Database Tables
1. Go to your Supabase dashboard
2. Click **"SQL Editor"** in left sidebar
3. Click **"New Query"**
4. Open `supabase_schema.sql` from the project
5. Copy ALL contents
6. Paste into SQL Editor
7. Click **"Run"** or press F5

### Step 3: Verify Tables Created
1. Go to **"Table Editor"** in left sidebar
2. You should see these tables:
   - ✅ `users`
   - ✅ `anime_lists`
   - ✅ `manga_lists`
   - ✅ `favorites`

### Step 4: Check Policies
1. Click on each table
2. Go to **"Policies"** tab
3. Verify RLS is enabled
4. Check that policies exist for SELECT, INSERT, UPDATE, DELETE

**If policies are missing:**
- The SQL script should have created them
- If not, re-run the SQL script
- Or create policies manually (allow public access for now)

## Part 5: Platform-Specific Setup

### For Android Testing

1. **Connect Device or Emulator**
   ```bash
   flutter devices
   ```

2. **Run the App**
   ```bash
   flutter run -d android
   ```

3. **Deep Linking is Already Configured** ✓
   - AndroidManifest.xml has the intent-filter
   - No additional setup needed

### For Windows Testing

1. **Register URL Scheme (REQUIRED for production)**
   
   For development, you can skip this and use localhost redirect.
   
   For production:
   - Open `windows/miyolist-protocol.reg`
   - Update the path to point to your .exe:
     ```reg
     @="\"C:\\Path\\To\\Your\\miyolist.exe\" \"%1\""
     ```
   - Right-click the .reg file
   - Select **"Run as Administrator"**
   - Click **"Yes"** to confirm

2. **Run the App**
   ```bash
   flutter run -d windows
   ```

## Part 6: Testing the Setup

### 1. Launch the App
- You should see the login screen with "MiyoList" title

### 2. Click Login
- Click **"Login with AniList"**
- Browser should open
- You'll see AniList authorization page

### 3. Authorize
- Click **"Approve"** on AniList
- Browser should redirect to `miyolist://auth?code=...`
- App should receive the code and login

### 4. Wait for Sync
- App will fetch your data from AniList
- This may take 10-30 seconds depending on list size
- You'll see loading indicator

### 5. Verify Success
- You should see your anime/manga lists
- Try switching between Anime and Manga tabs
- Try filtering by status (Watching, Completed, etc.)
- Click profile icon to see your profile

## Part 7: Troubleshooting

### Problem: Compilation Errors
**Error:** "Target of URI hasn't been generated"
**Solution:** 
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problem: "Invalid Client ID"
**Solutions:**
1. Verify Client ID in `app_constants.dart` is correct
2. No extra spaces or quotes
3. Must be just the number
4. Check it matches AniList developer settings

### Problem: Redirect Not Working (Windows)
**Solutions:**
1. Run .reg file as Administrator
2. Make sure path in .reg file is correct
3. Restart your browser
4. Try using `http://localhost:8080/auth` as redirect URL instead
   - Update in AniList settings
   - Update in app_constants.dart

### Problem: "Database Error"
**Solutions:**
1. Verify SQL script ran successfully
2. Check all 4 tables exist in Supabase
3. Verify RLS policies are enabled
4. Check Supabase logs for errors

### Problem: App Crashes on Login
**Solutions:**
1. Check Supabase is accessible
2. Verify internet connection
3. Check device/emulator logs:
   ```bash
   flutter logs
   ```

### Problem: Lists Not Showing
**Solutions:**
1. Check you have entries in your AniList account
2. Wait longer for sync to complete
3. Check console logs for errors
4. Verify Hive database initialized

## Part 8: Development Tips

### Hot Reload
- Save files to hot reload
- Instant UI updates
- No need to restart app

### Debug Mode
- Press F5 in VS Code
- Set breakpoints in code
- Inspect variables

### Logs
```bash
flutter logs
```
See all console output

### Clean Build
If things get weird:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Check Dependencies
```bash
flutter pub outdated
```
See which packages can be updated

## Part 9: Building for Release

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Windows Executable
```bash
flutter build windows --release
```
Output: `build/windows/x64/runner/Release/`

## Part 10: Next Steps

Once everything is working:

1. **Customize the App**
   - Change colors in `app_theme.dart`
   - Modify app name in manifest files
   - Create custom app icon

2. **Add Features**
   - Check `TODO.md` for ideas
   - Implement edit dialog
   - Add search functionality
   - Create statistics page

3. **Improve UX**
   - Add error messages
   - Improve loading states
   - Add pull-to-refresh
   - Implement offline mode

4. **Prepare for Release**
   - Test thoroughly
   - Add screenshots
   - Write release notes
   - Submit to stores

## 📞 Need Help?

1. **Check Documentation**
   - README.md - Full documentation
   - OAUTH_SETUP.md - OAuth issues
   - GRAPHQL_EXAMPLES.md - API reference
   - TODO.md - Feature ideas

2. **Common Issues**
   - 90% of problems are solved by running build_runner
   - Most auth issues are wrong Client ID
   - Database issues are usually missing tables

3. **Get Support**
   - Open an issue on GitHub
   - Include error messages
   - Describe steps to reproduce
   - Mention your platform (Windows/Android)

## ✅ Setup Checklist

- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Generated Hive adapters (`build_runner`)
- [ ] Added AniList Client ID
- [ ] Created Supabase tables
- [ ] Verified RLS policies
- [ ] (Windows only) Registered URL scheme
- [ ] Tested login flow
- [ ] Verified data syncs
- [ ] Lists display correctly
- [ ] Profile page works

## 🎉 You Did It!

If you completed all steps, you now have:
- ✅ Working AniList authentication
- ✅ Local data storage with Hive
- ✅ Cloud sync with Supabase
- ✅ Beautiful manga-styled UI
- ✅ Cross-platform support

**Enjoy your new AniList client!** 🎌

---

*Last updated: October 10, 2025*
*Project: MiyoList v0.1.0*
