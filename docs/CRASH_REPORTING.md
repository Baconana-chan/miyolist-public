# Crash Reporting System

## Overview

MiyoList includes a built-in crash reporting system that detects unexpected app crashes and allows users to share crash reports with developers. The system distinguishes between graceful shutdowns and unexpected crashes.

## Features

### 1. **Crash Detection**
- Tracks app lifecycle and session state
- Detects if app crashed in previous session
- Shows crash report dialog on next app start
- Distinguishes between user-initiated close and crash

### 2. **Logging System**
- Comprehensive error and event logging
- Log levels: DEBUG, INFO, WARNING, ERROR, FATAL
- Stack trace capture for all errors
- Automatic log rotation (max 5MB per file, keeps last 3)
- Persistent storage in app documents directory

### 3. **Crash Report Dialog**
- Automatically shown after detected crash
- Formatted crash report with session details
- One-click copy to clipboard
- Links to GitHub Issues and Discord
- Beautiful UI with clear instructions

### 4. **Global Error Handling**
- Catches Flutter framework errors
- Catches unhandled async errors
- Logs all errors automatically
- Continues running when possible

## Implementation

### Architecture

```
┌─────────────────┐
│   main.dart     │
│  - Initialize   │
│  - Set handlers │
│  - Zone guard   │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│  CrashReporter      │
│  - Session tracking │
│  - Log management   │
│  - Crash detection  │
└─────────────────────┘
         │
         ▼
┌──────────────────────┐
│  Crash Report Dialog │
│  - Display report    │
│  - Copy to clipboard │
│  - User guidance     │
└──────────────────────┘
```

### Key Components

**`CrashReporter`** (`lib/core/services/crash_reporter.dart`)
- Singleton service for crash tracking
- Methods:
  - `initialize()` - Set up logging system
  - `markSessionStart()` - Mark beginning of session
  - `markGracefulShutdown()` - Mark intentional close
  - `didCrashInLastSession()` - Check for previous crash
  - `getLastCrashReport()` - Get formatted crash report
  - `log()` - Write log entry
  - `clearLogs()` - Delete all log files

**`CrashReportDialog`** (`lib/features/common/widgets/crash_report_dialog.dart`)
- Dialog widget shown after crash detection
- Features:
  - Formatted crash report display
  - Copy to clipboard button
  - Links to reporting channels
  - Selectable text for easy copying

**`main.dart`** Integration
- Initializes crash reporter first
- Sets up global error handlers
- Wraps app in `runZonedGuarded`
- Marks sessions start/end
- Shows crash dialog after first frame

## How It Works

### Session Tracking

1. **App Starts:**
   ```dart
   await crashReporter.initialize();
   await crashReporter.markSessionStart();
   // Writes: SESSION_START|1234567890|2025-10-11T10:30:00.000Z
   ```

2. **Normal Shutdown:**
   ```dart
   await crashReporter.markGracefulShutdown();
   // Writes: SESSION_CLOSED|1234567890|2025-10-11T11:00:00.000Z
   ```

3. **Crash (no shutdown marker written)**

4. **Next Start:**
   ```dart
   final crashed = await crashReporter.didCrashInLastSession();
   // Returns true if last session didn't have CLOSED marker
   ```

### Crash Detection Logic

```dart
Future<bool> didCrashInLastSession() async {
  if (await _sessionFile.exists()) {
    final content = await _sessionFile.readAsString();
    final lines = content.split('\n');
    
    if (lines.isNotEmpty) {
      final lastLine = lines.last.trim();
      // If last session didn't have 'CLOSED' marker, it crashed
      return !lastLine.contains('CLOSED');
    }
  }
  return false;
}
```

### Error Handling

**Flutter Errors:**
```dart
FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  crashReporter.log(
    'Flutter Error: ${details.exception}',
    level: LogLevel.error,
    error: details.exception,
    stackTrace: details.stack,
  );
};
```

**Async Errors:**
```dart
runZonedGuarded(() async {
  // App code
}, (error, stackTrace) {
  crashReporter.log(
    'Unhandled Error: $error',
    level: LogLevel.fatal,
    error: error,
    stackTrace: stackTrace,
  );
});
```

## Usage

### Logging Events

```dart
// Import
import 'package:miyolist/core/services/crash_reporter.dart';

// Log info
await CrashReporter().log(
  'User logged in successfully',
  level: LogLevel.info,
);

// Log warning
await CrashReporter().log(
  'API rate limit approaching',
  level: LogLevel.warning,
);

// Log error with details
await CrashReporter().log(
  'Failed to sync data',
  level: LogLevel.error,
  error: exception,
  stackTrace: stackTrace,
);
```

### Log Levels

| Level   | Use Case                           | Example                         |
|---------|------------------------------------|---------------------------------|
| DEBUG   | Development info                   | "Button pressed"                |
| INFO    | Normal operations                  | "User logged in"                |
| WARNING | Potential issues                   | "API rate limit near"           |
| ERROR   | Recoverable errors                 | "Failed to fetch data"          |
| FATAL   | Critical unrecoverable errors      | "App crash"                     |

### Crash Report Format

```
═══════════════════════════════════════
    MIYOLIST CRASH REPORT
═══════════════════════════════════════

Platform: windows
Version: Windows 10 Pro

─── Last Session Logs ───

[2025-10-11 10:30:00.000] [INFO ] CrashReporter initialized - Session ID: 1234567890
[2025-10-11 10:30:05.123] [INFO ] Session started
[2025-10-11 10:35:42.456] [ERROR] Failed to sync data
Error: Exception: Network error
Stack trace:
#0      AnimeListPage._syncData (package:miyolist/...)
...

═══════════════════════════════════════
```

## File Structure

```
/app_documents/
  /logs/
    app_logs.txt          # Current session logs
    app_logs_1.txt        # Previous session (rotated)
    app_logs_2.txt        # Older session
    app_logs_3.txt        # Oldest session
    session.txt           # Session state tracker
```

## Configuration

**Log Rotation:**
```dart
static const int _maxLogSize = 5 * 1024 * 1024; // 5MB max per file
static const int _maxLogFiles = 3; // Keep last 3 files
```

**Session File Format:**
```
SESSION_START|{sessionId}|{timestamp}
SESSION_CLOSED|{sessionId}|{timestamp}
```

## User Flow

1. **App crashes unexpectedly**
   - No graceful shutdown marker written
   - Error logged with stack trace

2. **User restarts app**
   - CrashReporter detects missing shutdown marker
   - Retrieves last session logs

3. **Crash dialog appears**
   - Shows formatted crash report
   - Explains what happened
   - Provides copy button and reporting links

4. **User can:**
   - Copy report to clipboard
   - Share on GitHub Issues
   - Share on Discord
   - Close dialog and continue

## Reporting Channels

**GitHub Issues:**
- URL: `github.com/Baconana-chan/miyolist/issues`
- Include crash report in issue description
- Add steps to reproduce if known

**Discord:**
- URL: `discord.gg/miyolist`
- Share in #bug-reports channel
- Paste crash report for analysis

## Privacy Considerations

**What's Logged:**
- Error messages and stack traces
- App events (login, sync, etc.)
- Platform and OS version
- Timestamps

**What's NOT Logged:**
- User credentials or tokens
- Personal data (username, email)
- List contents or preferences
- Network request bodies

## Development

### Testing Crash Detection

```dart
// Simulate crash (force exit without graceful shutdown)
void testCrash() {
  throw Exception('Test crash');
  // Don't call markGracefulShutdown()
}

// Next app start will detect crash
```

### Viewing Logs

```dart
// Get logs directory
final logsDir = await CrashReporter().getLogsDirectory();
print('Logs location: $logsDir');

// Get all log files
final logFiles = await CrashReporter().getAllLogFiles();
for (final file in logFiles) {
  print('Log file: ${file.path}');
}
```

### Clearing Logs

```dart
await CrashReporter().clearLogs();
```

## Future Enhancements

- [ ] Automatic upload to server (opt-in)
- [ ] Crash analytics dashboard
- [ ] Pattern detection (common crashes)
- [ ] Performance metrics logging
- [ ] Memory usage tracking
- [ ] Network request logging (debug mode)
- [ ] User consent for crash reporting
- [ ] Crash frequency tracking
- [ ] Integration with Firebase Crashlytics (optional)

## Troubleshooting

**Dialog not showing:**
- Check if crash was actually detected
- Verify session file exists
- Check logs directory permissions

**Logs too large:**
- Logs auto-rotate at 5MB
- Clear manually if needed
- Reduce logging verbosity

**False positive crashes:**
- Ensure `markGracefulShutdown()` is called
- Check app lifecycle observers
- Verify dispose methods run

## Technical Notes

- **Singleton Pattern**: CrashReporter uses singleton for global access
- **Async-Safe**: All file operations are async
- **Non-Blocking**: Logging doesn't block UI thread
- **Resilient**: Handles file system errors gracefully
- **Cross-Platform**: Works on Windows, Linux, macOS, Android, iOS

## Version

**v1.3.0** - Crash Reporting System
- Initial implementation
- Session tracking
- Crash detection
- Report dialog
- Global error handling
