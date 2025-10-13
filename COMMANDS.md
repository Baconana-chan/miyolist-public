# ⚡ Quick Commands Reference

## Essential Commands

### 1. Generate Required Files (DO THIS FIRST!)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Run on Android
```bash
flutter run -d android
```

### 3. Run on Windows
```bash
flutter run -d windows
```

### 4. Clean Build
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Check for Errors
```bash
flutter analyze
```

### 6. Format Code
```bash
flutter format .
```

## Build Commands

### Android APK (Debug)
```bash
flutter build apk --debug
```

### Android APK (Release)
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### Windows (Debug)
```bash
flutter build windows --debug
```

### Windows (Release)
```bash
flutter build windows --release
```

## Development Commands

### Hot Reload
- Press `r` in terminal while app is running
- Or save file in IDE

### Hot Restart
- Press `R` in terminal
- Or press Shift+R in IDE

### Show Logs
```bash
flutter logs
```

### List Devices
```bash
flutter devices
```

### Doctor Check
```bash
flutter doctor -v
```

## Dependency Commands

### Install Dependencies
```bash
flutter pub get
```

### Update Dependencies
```bash
flutter pub upgrade
```

### Check Outdated
```bash
flutter pub outdated
```

### Add Package
```bash
flutter pub add package_name
```

### Remove Package
```bash
flutter pub remove package_name
```

## Build Runner Commands

### Generate Once
```bash
flutter pub run build_runner build
```

### Generate with Cleanup
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Watch Mode (Auto-generate on save)
```bash
flutter pub run build_runner watch
```

### Clean Generated Files
```bash
flutter pub run build_runner clean
```

## Testing Commands

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/widget_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
```

## Git Commands

### Initial Commit
```bash
git add .
git commit -m "Initial commit"
```

### Create Branch
```bash
git checkout -b feature/your-feature
```

### Push to Remote
```bash
git push origin main
```

## Troubleshooting Commands

### Clear Cache
```bash
flutter clean
flutter pub cache repair
```

### Reset to Clean State
```bash
flutter clean
rm pubspec.lock
rm -rf .dart_tool
flutter pub get
```

### Update Flutter
```bash
flutter upgrade
```

### Check Flutter Issues
```bash
flutter doctor
flutter doctor -v
```

## Supabase Commands (SQL)

### Create Tables
Run `supabase_schema.sql` in SQL Editor

### Check Tables
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

### View Table Data
```sql
SELECT * FROM users LIMIT 10;
SELECT * FROM anime_lists LIMIT 10;
```

### Clear All Data (Careful!)
```sql
TRUNCATE users, anime_lists, manga_lists, favorites CASCADE;
```

## Common Workflows

### Starting Fresh
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### After Code Changes
```bash
# Hot reload (just press 'r' in terminal)
# Or save file if using IDE
```

### After Model Changes
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Before Commit
```bash
flutter analyze
flutter test
flutter format .
git add .
git commit -m "Your message"
```

### Preparing Release
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release
flutter build windows --release
```

## Platform-Specific Commands

### Android Only

#### Check Connected Devices
```bash
adb devices
```

#### View Android Logs
```bash
adb logcat
```

#### Install APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Uninstall App
```bash
adb uninstall com.example.miyolist
```

### Windows Only

#### Register URL Scheme
```bash
# Run as Administrator
reg import windows/miyolist-protocol.reg
```

#### Check Registry
```bash
reg query HKEY_CLASSES_ROOT\miyolist
```

## Performance Commands

### Profile App
```bash
flutter run --profile
```

### Analyze Size
```bash
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

### Check Performance
```bash
flutter run --trace-startup
```

## Code Generation Tips

### When to Run build_runner
- After creating/modifying models with `@HiveType`
- After adding/removing `@HiveField` annotations
- After any changes to files with `part '*.g.dart'`
- When you see "Target of URI hasn't been generated" errors

### Watch Mode Benefits
- Automatically generates files on save
- No need to manually run build_runner
- Great for development
- Use: `flutter pub run build_runner watch`

## Quick Fixes

### Problem: "Target of URI not found"
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problem: "Package not found"
```bash
flutter clean
flutter pub get
```

### Problem: "Build failed"
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Problem: "Plugin not registered"
```bash
flutter clean
flutter pub get
```

## Useful Aliases (Optional)

Add these to your shell profile (.bashrc, .zshrc, etc.):

```bash
alias frun='flutter run'
alias fbuild='flutter build'
alias fclean='flutter clean && flutter pub get'
alias fgen='flutter pub run build_runner build --delete-conflicting-outputs'
alias ftest='flutter test'
alias fanalyze='flutter analyze'
alias fformat='flutter format .'
```

Then you can use:
```bash
fgen  # Instead of flutter pub run build_runner build --delete-conflicting-outputs
frun  # Instead of flutter run
```

## Remember

1. **Always** run build_runner after model changes
2. **Always** flutter clean when things get weird
3. **Always** flutter pub get after adding dependencies
4. **Save often** to use hot reload
5. **Check logs** when errors occur

## Documentation Shortcuts

- **Full Guide**: README.md
- **Quick Start**: QUICKSTART.md
- **OAuth Help**: OAUTH_SETUP.md
- **API Examples**: GRAPHQL_EXAMPLES.md
- **Feature Ideas**: TODO.md
- **This File**: COMMANDS.md

---

*Tip: Bookmark this file for quick reference!*
