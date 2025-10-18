# 🧪 Quick Test Guide - Adult Content & Rate Limiting

## ⚡ Fast Track Testing (20 minutes)

### Prerequisites
```bash
# Ensure everything is up to date
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Test 1: Adult Content Filtering (10 min)

### Setup on AniList

1. **Open AniList** → https://anilist.co
2. **Go to Settings** → Account
3. **Find "18+ Content" checkbox**

### Test A: Disabled (Default)

**Steps**:
1. On AniList: **Uncheck** "18+ Content" → Save
2. Open MiyoList → Login
3. View anime/manga lists
4. Open Profile page

**✅ Success Criteria**:
- No adult titles appear in lists
- All content safe for work
- No 18+ badges/indicators

### Test B: Enabled

**Steps**:
1. On AniList: **Check** "18+ Content" → Save
2. Logout from MiyoList
3. Login again
4. View anime/manga lists

**✅ Success Criteria**:
- Adult titles appear (if in your list)
- All content visible including 18+
- No filtering applied

### Test C: Setting Change

**Steps**:
1. Login with 18+ disabled → Verify content hidden
2. On AniList: Enable 18+ → Save
3. In MiyoList: Logout → Login
4. Verify adult content now visible

**✅ Success Criteria**:
- Settings sync correctly after re-login
- Content visibility changes appropriately

---

## Test 2: Rate Limiting (10 min)

### Normal Usage

**Steps**:
1. Clear app data (optional, for fresh start)
2. Login to MiyoList
3. Navigate through app normally
4. Load anime lists
5. Load manga lists
6. View profile

**✅ Success Criteria**:
- No delays or lag
- Smooth loading
- No rate limit messages in console

### Heavy Usage

**Steps**:
1. Open app
2. Quickly switch between tabs multiple times
3. Refresh lists repeatedly
4. Watch console output

**✅ Success Criteria**:
- App continues working
- Console shows "Rate limit reached. Waiting..." (if > 30 requests)
- No crashes or errors
- App recovers automatically

### Debug Check (Optional)

**Add to AniListService temporarily**:
```dart
// In any page, add this button:
ElevatedButton(
  onPressed: () {
    final stats = widget.anilistService.getRateLimiterStats();
    print('=== Rate Limiter Stats ===');
    print('Current: ${stats['currentRequests']}');
    print('Remaining: ${stats['remainingRequests']}');
    print('Wait time: ${stats['waitTimeMs']}ms');
  },
  child: Text('Check Rate Limit'),
)
```

**✅ Success Criteria**:
- Stats display correctly
- Numbers make sense (0-30 range)
- Wait time is 0 when under limit

---

## 🔍 Visual Checks

### Adult Content Badge

Some adult titles to check (if in your list):
- High School DxD (isAdult: true)
- Prison School (isAdult: true)
- To Love-Ru (isAdult: possibly)

**With 18+ disabled**: These should NOT appear
**With 18+ enabled**: These SHOULD appear

### Console Output

**Normal operation**:
```
✅ No rate limit messages
✅ Smooth API calls
```

**Over 30 requests/minute**:
```
⏳ Rate limit reached. Waiting 5432ms before next request...
✅ Continuing after wait...
```

---

## 📊 Quick Verification

| Test | Pass | Fail | Notes |
|------|------|------|-------|
| 18+ Disabled → Content Hidden | ☐ | ☐ | |
| 18+ Enabled → Content Visible | ☐ | ☐ | |
| Setting Change Syncs | ☐ | ☐ | |
| Normal Usage Smooth | ☐ | ☐ | |
| Heavy Usage Handled | ☐ | ☐ | |
| Rate Limit Logging Works | ☐ | ☐ | |

---

## 🐛 Common Issues

### Issue: Adult content still visible with 18+ disabled

**Solution**:
```bash
1. Double-check AniList settings
2. Ensure "18+ Content" is unchecked
3. Logout from MiyoList completely
4. Clear app data (optional)
5. Login again
```

### Issue: Rate limit messages even with light usage

**Check**:
```bash
1. Verify only one app instance running
2. Check for background sync
3. Review console for duplicate requests
4. Restart app
```

### Issue: App freezes or crashes

**Debug**:
```bash
1. Check console for errors
2. Verify Hive adapters generated correctly
3. Clear app data and retry
4. Check network connection
```

---

## ✅ All Tests Pass?

**Great!** Features are working correctly.

### Next Steps:
1. Test on real device (not just emulator)
2. Try with different AniList accounts
3. Test with large lists (100+ entries)
4. Monitor performance over time

---

## 🆘 Need Help?

- **Adult Content**: See `ADULT_CONTENT_AND_RATE_LIMITING.md` (Section: Adult Content Filtering)
- **Rate Limiting**: See `ADULT_CONTENT_AND_RATE_LIMITING.md` (Section: Rate Limiting)
- **General Issues**: Check console output first

---

## 📝 Test Report Template

```markdown
## Test Results - Adult Content & Rate Limiting

**Date**: _______________
**Platform**: Windows / Android
**Tester**: _______________

### Adult Content Filtering
- [ ] Works with 18+ disabled
- [ ] Works with 18+ enabled
- [ ] Setting changes sync correctly
- [ ] No adult content leaks

### Rate Limiting
- [ ] Normal usage smooth
- [ ] Heavy usage handled
- [ ] Console logging works
- [ ] No 429 errors

### Issues Found
1. _____________________
2. _____________________
3. _____________________

### Notes
_________________________
_________________________
```

---

**Time Required**: 20 minutes
**Difficulty**: Easy
**Platforms**: Windows and/or Android
**Version**: 1.1.0
