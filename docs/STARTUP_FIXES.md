# Startup Fixes Documentation

## Overview
This document describes the fixes applied to resolve startup errors in the application.

## Issues Fixed

### 1. Zone Mismatch Error

**Problem:**
```
Flutter Error: Zone mismatch.
The Flutter bindings were initialized in a different zone than is now being used.
```

**Root Cause:**
- `WidgetsFlutterBinding.ensureInitialized()` was called inside `runZonedGuarded()`
- `runApp()` was also called inside the same zone
- Flutter bindings should be initialized before creating any zones

**Solution:**
Moved `ensureInitialized()` and all initialization code outside of `runZonedGuarded()`:

```dart
void main() async {
  // Initialize bindings FIRST, before any zones
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services...
  
  // Only wrap runApp in zone
  runZonedGuarded(() async {
    runApp(MyApp(...));
  }, (error, stackTrace) {
    // Error handling
  });
}
```

**Impact:**
- ✅ Eliminates zone mismatch warning
- ✅ Ensures proper initialization order
- ✅ Maintains error catching functionality

---

### 2. MaterialLocalizations Not Found Error

**Problem:**
```
No MaterialLocalizations found.
MyApp widgets require MaterialLocalizations to be provided by a Localizations widget ancestor.
```

**Root Cause:**
- `CrashReportDialog.showIfNeeded()` was called in `initState()` via `addPostFrameCallback()`
- At that point, `MaterialApp` context wasn't fully initialized
- `showDialog()` requires MaterialLocalizations which come from MaterialApp

**Solution:**
Used `Builder` widget to get proper context after MaterialApp is built:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        // This context has MaterialLocalizations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForCrash(context);
        });
        
        return FutureBuilder<bool>(...);
      },
    ),
  );
}
```

Added safety checks:
```dart
Future<void> _checkForCrash(BuildContext context) async {
  if (_crashCheckCompleted) return;
  _crashCheckCompleted = true;
  
  // Wait for next frame to ensure MaterialApp is fully built
  await Future.delayed(const Duration(milliseconds: 100));
  
  if (!mounted) return;
  await CrashReportDialog.showIfNeeded(context);
}
```

**Impact:**
- ✅ Crash dialog works correctly
- ✅ No MaterialLocalizations errors
- ✅ Proper context hierarchy maintained

---

## Modified Files

### lib/main.dart
- Moved `ensureInitialized()` outside of `runZonedGuarded()`
- Moved all service initialization outside of zone
- Added `Builder` widget inside MaterialApp
- Added `_crashCheckCompleted` flag to prevent duplicate checks
- Added delay and mounted check in `_checkForCrash()`

---

## Testing

### Verified Scenarios
1. ✅ App starts without zone mismatch errors
2. ✅ App starts without MaterialLocalizations errors
3. ✅ Crash dialog shows correctly if previous crash detected
4. ✅ Error handlers work properly
5. ✅ Window manager initializes correctly
6. ✅ Services initialize in correct order

### Test Results
```
✅ Access token found
✅ AniList GraphQL client initialized
✅ Anime list fetched: 2177 entries
✅ Manga list fetched: 240 entries
✅ Background fetch complete

NO ERRORS in console!
```

---

## Best Practices Applied

### 1. Initialization Order
```
1. WidgetsFlutterBinding.ensureInitialized()
2. CrashReporter.initialize()
3. Error handlers setup
4. Window manager (desktop)
5. Services (Storage, Supabase, ImageCache)
6. Zone guard + runApp()
```

### 2. Context Safety
- Always check `mounted` before using context
- Use `Builder` to get proper MaterialApp context
- Add delays when needed for build completion

### 3. Error Handling
- Set up error handlers before running app
- Use zones for async error catching
- Log all errors to crash reporter

---

## Related Documentation
- [Flutter Error Handling](https://docs.flutter.dev/testing/errors)
- [Flutter Zones](https://api.flutter.dev/flutter/dart-async/runZonedGuarded.html)
- [MaterialApp Context](https://api.flutter.dev/flutter/material/MaterialApp-class.html)

---

## Changelog

### v1.3.0 (2025-10-11)
- Fixed zone mismatch error
- Fixed MaterialLocalizations error
- Improved initialization order
- Added proper context handling

---

## Future Improvements
1. Consider using error boundary widgets
2. Add more granular error categories
3. Implement retry logic for failed initializations
4. Add initialization progress indicator
