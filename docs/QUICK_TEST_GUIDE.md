# 🚀 Quick Test Guide - Privacy Feature

## ⚡ Fast Track Testing (15 minutes)

### Prerequisites
```bash
# Ensure no errors
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Test 1: Private Profile (5 min)

### Steps:
1. **Launch app** → Login with AniList
2. **Select** → 🔒 **Private Profile**
3. **Wait** → Data loads
4. **Navigate** → Profile page
5. **Verify** → Badge shows "🔒 Private Profile" (blue)

### ✅ Success Criteria:
- Badge is blue with lock icon
- No cloud sync occurs
- Lists display correctly
- No errors in console

---

## Test 2: Public Profile (5 min)

### Steps:
1. **Clear data** → Logout or reinstall
2. **Login** → AniList OAuth
3. **Select** → 🌐 **Public Profile**
4. **Wait** → Data syncs to cloud
5. **Navigate** → Profile page
6. **Verify** → Badge shows "🌐 Public Profile" (red)

### ✅ Success Criteria:
- Badge is red with globe icon
- Cloud sync completes
- Lists display correctly
- Data in Supabase (optional check)

---

## Test 3: Switch Profiles (5 min)

### From Private to Public:
1. **Navigate** → Profile → ⚙️ Settings
2. **Select** → Public Profile radio
3. **Click** → Save
4. **Wait** → Cloud sync
5. **Verify** → Badge updates to 🌐

### From Public to Private:
1. **Navigate** → Profile → ⚙️ Settings
2. **Select** → Private Profile radio
3. **Read** → Warning dialog
4. **Confirm** → Switch to Private
5. **Verify** → Badge updates to 🔒

### ✅ Success Criteria:
- Warning shows for Public → Private
- Badge updates immediately
- Success message appears
- No crashes

---

## 🐛 Quick Checks

### If Something Fails:

**No badge showing?**
```dart
// Check settings exist
final settings = localStorageService.getUserSettings();
print(settings);  // Should not be null
```

**Cloud sync not working?**
```dart
// Verify Supabase config in app_constants.dart
print(AppConstants.supabaseUrl);
print(AppConstants.supabaseAnonKey);
```

**App crashes on switch?**
```bash
# Check console for errors
# Look for Hive or Supabase errors
```

---

## 📊 Quick Results

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| Private Profile | ☐ | ☐ | |
| Public Profile | ☐ | ☐ | |
| Switch Private→Public | ☐ | ☐ | |
| Switch Public→Private | ☐ | ☐ | |

---

## ✅ All Tests Pass?

**Great!** Feature is working correctly.

**Next Steps:**
1. Test on real device (not emulator)
2. Test offline behavior
3. Try multi-device sync (public only)
4. Check performance and responsiveness

---

## 🆘 Need Help?

- See: `TESTING_CHECKLIST.md` for detailed tests
- See: `PRIVACY_FEATURE.md` for how it works
- See: `PRIVACY_VISUAL_GUIDE.md` for diagrams
- Check console for error messages

---

**Time Required:** 15 minutes
**Difficulty:** Easy
**Platforms:** Windows and/or Android
