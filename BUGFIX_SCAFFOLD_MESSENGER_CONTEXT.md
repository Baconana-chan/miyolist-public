# 🐛 Bug Fix: ScaffoldMessenger Context Issue

**Date**: October 13, 2025  
**Issue**: `Looking up a deactivated widget's ancestor is unsafe`  
**File**: `lib/features/media_details/presentation/pages/media_details_page.dart`

---

## 🔍 Problem Description

### Error Message
```
Unhandled Exception: Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference 
to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's 
didChangeDependencies() method.
```

### Root Cause
The app was calling `ScaffoldMessenger.of(context)` after async operations (`await`) inside dialog callbacks. By the time the async operation completed, the widget tree could have been disposed, making the context invalid.

### Affected Functions
1. `_showAddDialog()` - Adding new entries to list
2. `_showEditDialog()` - Editing/deleting existing entries
3. `_launchTrailer()` - Opening YouTube trailer
4. `_launchUrl()` - Opening external URLs

---

## ✅ Solution

### Pattern Applied
Save a reference to `ScaffoldMessenger` **before** any async operations:

```dart
// ❌ WRONG - Context may be invalid after await
Future<void> someAsyncFunction() async {
  await someAsyncOperation();
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Done')),
    );
  }
}

// ✅ CORRECT - Save reference before async
Future<void> someAsyncFunction() async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  await someAsyncOperation();
  
  if (mounted) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Done')),
    );
  }
}
```

---

## 🔧 Changes Made

### 1. `_launchTrailer()` (Line ~1262)
**Before**:
```dart
Future<void> _launchTrailer() async {
  if (_media!.trailer == null) return;

  final url = Uri.parse('https://www.youtube.com/watch?v=${_media!.trailer}');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open trailer')),
      );
    }
  }
}
```

**After**:
```dart
Future<void> _launchTrailer() async {
  if (_media!.trailer == null) return;

  final url = Uri.parse('https://www.youtube.com/watch?v=${_media!.trailer}');
  
  // Save ScaffoldMessenger before async operations
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Could not open trailer')),
      );
    }
  }
}
```

### 2. `_launchUrl()` (Line ~1815)
**Before**:
```dart
Future<void> _launchUrl(String urlString) async {
  final url = Uri.parse(urlString);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $urlString')),
      );
    }
  }
}
```

**After**:
```dart
Future<void> _launchUrl(String urlString) async {
  final url = Uri.parse(urlString);
  
  // Save ScaffoldMessenger before async operations
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Could not open $urlString')),
      );
    }
  }
}
```

### 3. `_showAddDialog()` (Line ~1827)
**Changes**:
- Added `final scaffoldMessenger = ScaffoldMessenger.of(context);` at the beginning
- Replaced 3 occurrences of `ScaffoldMessenger.of(context)` with `scaffoldMessenger`:
  - Success case: "✓ Added to list"
  - Error case: "Failed to add: $e"

### 4. `_showEditDialog()` (Line ~1923)
**Changes**:
- Added `final scaffoldMessenger = ScaffoldMessenger.of(context);` at the beginning
- Replaced 4 occurrences of `ScaffoldMessenger.of(context)` with `scaffoldMessenger`:
  - Update success: "✓ Updated successfully"
  - Update error: "Failed to update: $e"
  - Delete success: "✓ Removed from list"
  - Delete error: "Failed to delete: $e"

---

## 🧪 Testing

### Verification Steps
1. ✅ `flutter analyze` - No errors (only deprecation warnings)
2. ✅ Pattern applied to all 4 affected functions
3. ✅ All `ScaffoldMessenger.of(context)` after `await` now use saved reference

### Test Scenarios
- [ ] Add new anime/manga to list
- [ ] Edit existing entry
- [ ] Delete entry from list
- [ ] Open trailer link
- [ ] Open external URL (MyAnimeList, etc.)
- [ ] Test with slow network (to trigger async delays)

---

## 📚 Best Practices

### Rule: Save Context-Dependent References Before Async
When using inherited widgets in async functions, always save the reference before any `await`:

```dart
// Services to save before async operations:
final navigator = Navigator.of(context);
final scaffoldMessenger = ScaffoldMessenger.of(context);
final theme = Theme.of(context);
final mediaQuery = MediaQuery.of(context);

// Then use the saved references after await
await someAsyncOperation();

if (mounted) {
  scaffoldMessenger.showSnackBar(...);
  navigator.pop();
}
```

### Why This Works
1. **Context capture**: Reference is captured while widget is still mounted
2. **ScaffoldMessenger lifetime**: It's a separate object that survives widget disposal
3. **Safe disposal**: Even if widget is disposed, the messenger still exists
4. **mounted check**: Still need `if (mounted)` for `setState()` calls

---

## 🔍 Related Issues

### Similar Patterns in Project
Check these locations for similar issues:
- Dialog callbacks with async operations
- Navigator.pop() after async
- Theme.of(context) after async
- MediaQuery.of(context) after async

### Prevention
- Always use `final messenger = ScaffoldMessenger.of(context)` before async
- Add lint rule to detect this pattern (if available)
- Code review checklist: "Are inherited widgets accessed after await?"

---

## ✅ Status

- [x] Issue identified
- [x] Root cause analyzed
- [x] Fix implemented (4 functions)
- [x] Code analyzed (no errors)
- [ ] Tested in app
- [ ] Documentation updated

---

**Resolution**: All instances of `ScaffoldMessenger.of(context)` after async operations have been fixed by saving the reference before any `await` statements.

_Bug fix completed: October 13, 2025_
