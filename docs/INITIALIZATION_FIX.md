# Initialization Error Fixes

## Overview
Fixed two critical initialization errors that were preventing the application from starting properly.

## Issues Fixed

### 1. Zone Mismatch Error ✅

**Problem:**
```
Zone mismatch.
The Flutter bindings were initialized in a different zone than is now being used.
```

**Root Cause:**
- `runApp()` was called inside an `async` callback within `runZonedGuarded()`
- Flutter expects `ensureInitialized()` and `runApp()` to be called in the same zone

**Solution:**
Changed the zone callback from `async` to synchronous:

```dart
// BEFORE (incorrect)
runZonedGuarded(() async {
  runApp(MyApp(...));
}, ...);

// AFTER (correct)
runZonedGuarded(() {
  runApp(MyApp(...));
}, ...);
```

**Key Points:**
- `WidgetsFlutterBinding.ensureInitialized()` is called BEFORE `runZonedGuarded()`
- `runApp()` is called synchronously inside the zone
- All async initialization (Supabase, storage, etc.) happens BEFORE the zone
- The zone only catches runtime errors, not initialization errors

### 2. MaterialLocalizations Not Found ✅

**Problem:**
```
No MaterialLocalizations found.
MyApp widgets require MaterialLocalizations to be provided by a Localizations widget ancestor.
```

**Root Cause:**
- `CrashReportDialog.showIfNeeded()` was called in `initState()`
- At that point, MaterialApp hadn't finished building
- No Material context available for `showDialog()`

**Solution:**
Used `WidgetsBinding.instance.addPostFrameCallback()` to defer crash check:

```dart
// BEFORE (incorrect)
@override
void initState() {
  super.initState();
  _checkForCrash();
}

Future<void> _checkForCrash() async {
  await CrashReportDialog.showIfNeeded(context, widget.crashReporter);
}

// AFTER (correct)
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkForCrash();
  });
}

void _checkForCrash() {
  CrashReportDialog.showIfNeeded(context, widget.crashReporter);
}
```

**Key Points:**
- Post-frame callback ensures MaterialApp is fully built
- Crash dialog shows AFTER the UI is ready
- No more async in initState (not needed here)

## Initialization Order

Correct order of operations in `main()`:

1. ✅ `WidgetsFlutterBinding.ensureInitialized()` - First, before everything
2. ✅ Initialize CrashReporter
3. ✅ Set up global error handlers
4. ✅ Initialize WindowManager (desktop)
5. ✅ Initialize LocalStorage
6. ✅ Initialize Supabase
7. ✅ Initialize ImageCache
8. ✅ `runZonedGuarded()` with synchronous callback
9. ✅ `runApp()` inside the zone

## Testing

### Before Fix:
```
[ERROR] Flutter Error: Zone mismatch...
[FATAL] Unhandled Error: No MaterialLocalizations found...
```

### After Fix:
```
[INFO] Session started
✅ Supabase initialized successfully
✅ Application running normally
```

## Impact

**Before:**
- ❌ Crash report dialog on every startup
- ❌ Zone mismatch warning in console
- ❌ MaterialLocalizations error
- ⚠️ Unreliable error handling

**After:**
- ✅ Clean startup with no errors
- ✅ Proper zone isolation for error handling
- ✅ Crash dialog shows only when needed
- ✅ All Material widgets work correctly

## Related Documentation

- [Flutter Zone Documentation](https://api.flutter.dev/flutter/dart-async/runZonedGuarded.html)
- [Flutter Bindings](https://api.flutter.dev/flutter/widgets/WidgetsFlutterBinding-class.html)
- [Post Frame Callbacks](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html)

## Version

- **Fixed in:** v1.3.0
- **Date:** October 11, 2025
- **Related Features:** Crash Reporter, Error Handling
