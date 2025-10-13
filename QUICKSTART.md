# 🚀 Quick Start Guide for MiyoList

This guide will help you set up and run MiyoList on your Windows or Android device.

## Step-by-Step Setup

### 1️⃣ Prerequisites Check

✅ Flutter SDK installed (version 3.9.2+)  
✅ Android Studio (for Android builds)  
✅ Visual Studio 2022 (for Windows builds)  
✅ AniList account  
✅ Supabase project created  

### 2️⃣ Get Your AniList Client ID

1. **Login to AniList**
   - Go to https://anilist.co/settings/developer

2. **Create API Client**
   - Click "Create New Client"
   - Fill in the form:
     ```
     Name: MiyoList
     Redirect URL: miyolist://auth
     ```
   - Click "Save"

3. **Copy Client ID**
   - You'll see your Client ID displayed
   - Copy this value

4. **Update the App**
   - Open `lib/core/constants/app_constants.dart`
   - Replace this line:
     ```dart
     static const String anilistClientId = 'YOUR_ANILIST_CLIENT_ID';
     ```
   - With your actual Client ID:
     ```dart
     static const String anilistClientId = '12345'; // Your actual ID
     ```

### 3️⃣ Setup Supabase Database

Your Supabase project is already configured in the app, but you need to create the database tables.

1. **Open Supabase Dashboard**
   - Go to https://your-project-id.supabase.co

2. **Run SQL Script**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"
   - Copy the contents of `supabase_schema.sql` file
   - Paste into the editor
   - Click "Run"

3. **Verify Tables Created**
   - Go to "Table Editor"
   - You should see: `users`, `anime_lists`, `manga_lists`, `favorites`

### 4️⃣ Generate Required Files

Run this command in your project directory:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `user_model.g.dart`
- `anime_model.g.dart`
- `media_list_entry.g.dart`

### 5️⃣ Running the App

#### For Android:

1. Connect your Android device or start an emulator
2. Run:
   ```bash
   flutter run -d android
   ```

#### For Windows:

1. Ensure Windows development is set up
2. Run:
   ```bash
   flutter run -d windows
   ```

### 6️⃣ First Time Usage

1. **Launch the App**
   - You'll see the login screen

2. **Login with AniList**
   - Click "Login with AniList"
   - Browser will open
   - Authorize the app
   - You'll be redirected back

3. **Wait for Sync**
   - The app will fetch your lists
   - This may take a moment on first login
   - All data is cached locally

4. **Start Using!**
   - Browse your anime/manga lists
   - Edit entries
   - View your profile

## 🔧 Troubleshooting

### "Invalid Client ID" Error
- Double-check your Client ID in `app_constants.dart`
- Make sure there are no extra spaces
- Verify it matches the one in AniList Developer Settings

### Redirect Not Working on Windows
- Run `windows/miyolist-protocol.reg` as Administrator
- Update the path in the .reg file to point to your exe
- Restart your browser

### Database Errors
- Make sure you ran the SQL script in Supabase
- Check that all 4 tables were created
- Verify RLS policies are enabled

### Build Errors
- Run `flutter clean`
- Run `flutter pub get`
- Run the build_runner command again

### "Target of URI hasn't been generated" Error
- This is normal before running build_runner
- Run: `flutter pub run build_runner build --delete-conflicting-outputs`
- The error will disappear

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest (automatically set by Flutter)
- No additional setup needed after manifest configuration

### Windows
- Requires Windows 10 or later
- For deep linking in production:
  1. Build your app: `flutter build windows --release`
  2. Note the exe location: `build\windows\x64\runner\Release\miyolist.exe`
  3. Edit `windows/miyolist-protocol.reg` with the full path
  4. Run the .reg file as Administrator

## 🎨 Customization

### Changing Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color accentRed = Color(0xFFE63946); // Change this
static const Color accentBlue = Color(0xFF457B9D); // And this
```

### Changing App Name
1. Android: `android/app/src/main/AndroidManifest.xml`
   ```xml
   android:label="Your App Name"
   ```
2. Windows: `windows/runner/main.cpp`
   ```cpp
   Win32Window::Point(1280, 720), "Your App Name"
   ```

### Changing Icon
- Replace `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Use https://appicon.co/ to generate icons

## 🆘 Still Need Help?

1. Check the main README.md for detailed documentation
2. Read OAUTH_SETUP.md for OAuth troubleshooting
3. Check Supabase logs in the dashboard
4. Open an issue on GitHub with:
   - Platform (Windows/Android)
   - Error message
   - Steps to reproduce

## 🎉 You're Ready!

Once everything is set up, you should be able to:
- ✅ Login with AniList
- ✅ View your anime and manga lists
- ✅ Update progress and scores
- ✅ View your profile and favorites
- ✅ Sync across devices

Enjoy tracking your anime and manga with style! 🎌
