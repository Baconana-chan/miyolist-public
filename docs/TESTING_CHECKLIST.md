# Privacy Feature Testing Checklist

## ✅ Pre-Testing Setup

- [x] Build runner executed successfully
- [x] `user_settings.g.dart` generated
- [x] No compilation errors
- [x] All imports resolved
- [x] Documentation complete

---

## 🧪 Testing Scenarios

### Scenario 1: First-Time Private Profile

**Steps:**
1. [ ] Launch fresh app (clear data if needed)
2. [ ] Click "Login with AniList"
3. [ ] Complete OAuth2 authentication
4. [ ] ProfileTypeSelectionPage appears
5. [ ] Verify both cards are visible
6. [ ] Click "Select" on Private Profile card
7. [ ] Wait for loading to complete

**Expected Results:**
- [ ] No errors during OAuth
- [ ] Private card is highlighted on click
- [ ] Loading spinner appears
- [ ] Data syncs from AniList to Hive
- [ ] **NO** data sent to Supabase
- [ ] Navigate to AnimeListPage successfully
- [ ] Lists display correctly

**Verification:**
```dart
// Check settings
final settings = localStorageService.getUserSettings();
assert(settings?.isPublicProfile == false);
assert(settings?.enableCloudSync == false);
assert(settings?.enableSocialFeatures == false);
```

---

### Scenario 2: First-Time Public Profile

**Steps:**
1. [ ] Launch fresh app (clear data if needed)
2. [ ] Click "Login with AniList"
3. [ ] Complete OAuth2 authentication
4. [ ] ProfileTypeSelectionPage appears
5. [ ] Verify both cards are visible
6. [ ] Click "Select" on Public Profile card
7. [ ] Wait for loading to complete

**Expected Results:**
- [ ] No errors during OAuth
- [ ] Public card is highlighted on click
- [ ] Loading spinner appears
- [ ] Data syncs from AniList to Hive
- [ ] Data syncs from Hive to Supabase
- [ ] Navigate to AnimeListPage successfully
- [ ] Lists display correctly

**Verification:**
```dart
// Check settings
final settings = localStorageService.getUserSettings();
assert(settings?.isPublicProfile == true);
assert(settings?.enableCloudSync == true);
assert(settings?.enableSocialFeatures == true);

// Check Supabase
// Verify data exists in Supabase tables
```

---

### Scenario 3: Profile Page Display

**Private Profile:**
1. [ ] Navigate to Profile page
2. [ ] Verify privacy badge shows "🔒 Private Profile"
3. [ ] Badge is blue color
4. [ ] Settings icon visible in app bar
5. [ ] Profile information displays correctly
6. [ ] Favorites load and display

**Public Profile:**
1. [ ] Navigate to Profile page
2. [ ] Verify privacy badge shows "🌐 Public Profile"
3. [ ] Badge is red color
4. [ ] Settings icon visible in app bar
5. [ ] Profile information displays correctly
6. [ ] Favorites load and display

---

### Scenario 4: Switch Private → Public

**Steps:**
1. [ ] Start with Private profile
2. [ ] Navigate to Profile page
3. [ ] Click Settings icon (⚙️)
4. [ ] PrivacySettingsDialog opens
5. [ ] Select "Public Profile" radio button
6. [ ] Verify cloud sync switches enable automatically
7. [ ] Click "Save"
8. [ ] Wait for cloud sync to complete

**Expected Results:**
- [ ] Dialog opens without errors
- [ ] Radio buttons work correctly
- [ ] Switches auto-enable for public
- [ ] Loading spinner shows during save
- [ ] Cloud sync completes successfully
- [ ] Badge updates to 🌐 Public Profile
- [ ] Success snackbar appears
- [ ] Data uploaded to Supabase

**Verification:**
```dart
// Check updated settings
final settings = localStorageService.getUserSettings();
assert(settings?.isPublicProfile == true);
assert(settings?.enableCloudSync == true);

// Check cloud data
// Verify Supabase has all user data
```

---

### Scenario 5: Switch Public → Private

**Steps:**
1. [ ] Start with Public profile
2. [ ] Navigate to Profile page
3. [ ] Click Settings icon (⚙️)
4. [ ] PrivacySettingsDialog opens
5. [ ] Select "Private Profile" radio button
6. [ ] Verify switches auto-disable
7. [ ] Click "Save"
8. [ ] Warning dialog appears
9. [ ] Read warning message
10. [ ] Click "Switch to Private"

**Expected Results:**
- [ ] Dialog opens without errors
- [ ] Radio buttons work correctly
- [ ] Switches auto-disable for private
- [ ] Warning dialog shows before save
- [ ] Warning explains consequences
- [ ] Badge updates to 🔒 Private Profile
- [ ] Success snackbar appears
- [ ] No more cloud syncs occur
- [ ] Cloud data remains (not deleted)

**Verification:**
```dart
// Check updated settings
final settings = localStorageService.getUserSettings();
assert(settings?.isPublicProfile == false);
assert(settings?.enableCloudSync == false);

// Cloud data should still exist but not update
```

---

### Scenario 6: App Restart Persistence

**Private Profile:**
1. [ ] Select Private profile
2. [ ] Close app completely
3. [ ] Reopen app
4. [ ] Navigate to Profile page
5. [ ] Verify badge still shows 🔒 Private
6. [ ] Check settings dialog shows Private selected

**Public Profile:**
1. [ ] Select Public profile
2. [ ] Close app completely
3. [ ] Reopen app
4. [ ] Navigate to Profile page
5. [ ] Verify badge still shows 🌐 Public
6. [ ] Check settings dialog shows Public selected

**Expected Results:**
- [ ] Settings persist across app restarts
- [ ] Badge displays correct type
- [ ] Settings dialog reflects saved choice

---

### Scenario 7: Offline Behavior

**Private Profile:**
1. [ ] Disable internet connection
2. [ ] Use app normally
3. [ ] View lists
4. [ ] View profile
5. [ ] Edit list item (if implemented)

**Expected Results:**
- [ ] App works fully offline
- [ ] All data accessible
- [ ] No errors from missing connection
- [ ] All features work normally

**Public Profile:**
1. [ ] Disable internet connection
2. [ ] Use app normally
3. [ ] View lists (from cache)
4. [ ] View profile (from cache)
5. [ ] Make changes locally

**Expected Results:**
- [ ] App works offline
- [ ] Data loads from Hive cache
- [ ] Changes saved locally
- [ ] Sync queue builds up
- [ ] No crash from missing network

**Reconnect:**
1. [ ] Enable internet connection
2. [ ] Wait for automatic sync (or trigger manually)
3. [ ] Verify changes uploaded to cloud

---

### Scenario 8: Multi-Device Sync (Public Only)

**Device 1:**
1. [ ] Login with public profile
2. [ ] Add/modify list entries
3. [ ] Wait for sync to complete

**Device 2:**
1. [ ] Login with same account (public profile)
2. [ ] Wait for data to load
3. [ ] Verify changes from Device 1 appear
4. [ ] Make different changes
5. [ ] Wait for sync

**Device 1:**
1. [ ] Refresh or reopen
2. [ ] Verify changes from Device 2 appear

**Expected Results:**
- [ ] Data syncs bidirectionally
- [ ] No data loss
- [ ] Changes appear on both devices
- [ ] No conflicts (last write wins)

---

### Scenario 9: Error Handling

**Network Error During Sync:**
1. [ ] Use public profile
2. [ ] Disable internet mid-sync
3. [ ] Verify app doesn't crash
4. [ ] Check error message (if any)
5. [ ] Re-enable internet
6. [ ] Verify sync resumes

**Supabase Error:**
1. [ ] Use public profile
2. [ ] Temporarily break Supabase config
3. [ ] Try to sync
4. [ ] Verify graceful error handling
5. [ ] Local data remains intact
6. [ ] Fix config
7. [ ] Verify sync resumes

---

### Scenario 10: UI/UX Validation

**ProfileTypeSelectionPage:**
- [ ] Cards render correctly
- [ ] Feature lists readable
- [ ] Colors match theme (blue/red)
- [ ] Icons display correctly
- [ ] Buttons respond to touch
- [ ] Loading states work
- [ ] No UI glitches

**Privacy Badge:**
- [ ] Badge visible on profile
- [ ] Correct icon for type
- [ ] Correct color for type
- [ ] Text readable
- [ ] Updates immediately after switch

**Settings Dialog:**
- [ ] Dialog opens smoothly
- [ ] Radio buttons work
- [ ] Switches toggle correctly
- [ ] Switches disable for private
- [ ] Warning dialog shows correctly
- [ ] Save button works
- [ ] Loading spinner appears
- [ ] Success message shows

---

## 📊 Test Results

### Device/Platform Testing

**Windows:**
- [ ] All scenarios pass
- [ ] Performance acceptable
- [ ] UI renders correctly
- [ ] No crashes

**Android:**
- [ ] All scenarios pass
- [ ] Performance acceptable
- [ ] UI renders correctly
- [ ] No crashes

---

## 🐛 Bug Reports

### Found Issues

| # | Scenario | Issue | Severity | Status |
|---|----------|-------|----------|--------|
| 1 |          |       |          |        |
| 2 |          |       |          |        |
| 3 |          |       |          |        |

---

## ✅ Sign-Off

**Tester:** ___________________
**Date:** _____________________
**Version:** 1.0.0
**Result:** ☐ Pass ☐ Fail

**Notes:**
```
_________________________________________________
_________________________________________________
_________________________________________________
```

---

## 🔄 Regression Testing

After any bug fixes, re-test:
- [ ] Scenario where bug was found
- [ ] Related scenarios
- [ ] All critical paths

---

## 📝 Notes for Developers

### Common Issues to Watch

1. **Settings not persisting:**
   - Check Hive box initialization
   - Verify `saveUserSettings()` called
   - Check for errors in console

2. **Badge not updating:**
   - Verify `setState()` called after switch
   - Check settings reload in `_loadUserData()`

3. **Cloud sync not working:**
   - Verify Supabase credentials
   - Check `enableCloudSync` flag
   - Look for network errors

4. **UI not responsive:**
   - Add loading states
   - Check async/await chains
   - Verify error handling

### Debug Commands

```dart
// Print current settings
final settings = localStorageService.getUserSettings();
print('Is Public: ${settings?.isPublicProfile}');
print('Cloud Sync: ${settings?.enableCloudSync}');

// Force sync
if (localStorageService.isCloudSyncEnabled()) {
  await _syncToCloud();
}

// Clear all data (testing only)
await localStorageService.clearAll();
await Hive.deleteFromDisk();
```

---

## 🎯 Test Coverage Goals

- [ ] 100% scenario coverage
- [ ] Both platforms tested
- [ ] All user paths validated
- [ ] Edge cases handled
- [ ] Error scenarios tested
- [ ] Performance acceptable
- [ ] UI/UX validated

---

**Status:** Ready for Testing
**Priority:** High
**Complexity:** Medium
**Estimated Time:** 2-3 hours
