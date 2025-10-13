# Crash Reporting - Quick Start

## What is it?

Built-in crash detection system that:
- ✅ Detects when app crashed unexpectedly
- ✅ Shows crash report dialog on next start
- ✅ Allows users to copy and share crash info
- ✅ Logs all errors automatically
- ✅ Privacy-focused (no personal data)

## How to use

### For Users

**If app crashes:**
1. Restart the app
2. A dialog will appear with crash details
3. Click "Copy Report" button
4. Share on GitHub Issues or Discord
5. Done! Developers will investigate

### For Developers

**View logs:**
```dart
final logsDir = await CrashReporter().getLogsDirectory();
// Location: /Documents/miyolist/logs/
```

**Add custom logging:**
```dart
import 'package:miyolist/core/services/crash_reporter.dart';

// Log info
await CrashReporter().log('Something happened', level: LogLevel.info);

// Log error with details
try {
  // code
} catch (e, stackTrace) {
  await CrashReporter().log(
    'Operation failed',
    level: LogLevel.error,
    error: e,
    stackTrace: stackTrace,
  );
}
```

## Architecture

```
App Start → CrashReporter.initialize()
         → Mark session start
         → Set up error handlers
         → Check for previous crash
         → Show dialog if crashed
         
App Close → Mark graceful shutdown

Crash → No shutdown marker
     → Detected on next start
```

## Files

- `crash_reporter.dart` - Main service
- `crash_report_dialog.dart` - UI dialog
- `CRASH_REPORTING.md` - Full documentation
- `CRASH_REPORTING_SUMMARY.md` - Implementation details

## Testing

**Test crash detection:**
```dart
// In any widget
throw Exception('Test crash!');
// Restart app → Dialog should appear
```

## Log Levels

| Level | Use |
|-------|-----|
| DEBUG | Development info |
| INFO | Normal operations |
| WARNING | Potential issues |
| ERROR | Recoverable errors |
| FATAL | Critical crashes |

## Reporting Channels

- **GitHub**: github.com/Baconana-chan/miyolist-public/issues
- **Discord**: discord.gg/miyolist

## Privacy

**We LOG:**
- ✅ Error messages
- ✅ Stack traces
- ✅ Platform info

**We DON'T log:**
- ❌ Passwords
- ❌ User data
- ❌ List contents

## Version

v1.3.0 - Fully implemented ✨
