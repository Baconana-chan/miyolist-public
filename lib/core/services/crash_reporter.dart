import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Service for crash reporting and logging
/// 
/// Tracks app lifecycle and detects unexpected crashes by checking if the app
/// was properly closed in the previous session. Logs errors and provides
/// crash reports that users can share with developers.
class CrashReporter {
  static final CrashReporter _instance = CrashReporter._internal();
  factory CrashReporter() => _instance;
  CrashReporter._internal();

  File? _logFile;
  File? _sessionFile;
  bool _initialized = false;
  String? _sessionId;
  
  static const String _logFileName = 'app_logs.txt';
  static const String _sessionFileName = 'session.txt';
  static const int _maxLogSize = 5 * 1024 * 1024; // 5MB max log size
  static const int _maxLogFiles = 3; // Keep last 3 log files

  /// Initialize crash reporter
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _logFile = File('${logsDir.path}/$_logFileName');
      _sessionFile = File('${logsDir.path}/$_sessionFileName');

      // Generate session ID
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Rotate logs if needed
      await _rotateLogs();

      _initialized = true;
      await log('CrashReporter initialized - Session ID: $_sessionId', level: LogLevel.info);
    } catch (e) {
      debugPrint('❌ Failed to initialize CrashReporter: $e');
    }
  }

  /// Check if previous session crashed
  Future<bool> didCrashInLastSession() async {
    if (!_initialized) await initialize();
    
    try {
      if (await _sessionFile!.exists()) {
        final content = await _sessionFile!.readAsString();
        final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
        
        if (lines.isEmpty) return false;
        
        // Check if we have ERROR or FATAL logs in the session
        bool hasErrorLogs = false;
        bool hasClosed = false;
        
        for (final line in lines) {
          if (line.contains('SESSION_CLOSED')) {
            hasClosed = true;
          }
          if (line.contains('[ERROR]') || line.contains('[FATAL]')) {
            hasErrorLogs = true;
          }
        }
        
        // Only consider it a crash if:
        // 1. Session didn't close gracefully AND
        // 2. There were actual error/fatal logs
        return !hasClosed && hasErrorLogs;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking crash status: $e');
      return false;
    }
  }

  /// Get crash report from last session
  Future<String?> getLastCrashReport() async {
    if (!_initialized) await initialize();

    try {
      if (await _logFile!.exists()) {
        final content = await _logFile!.readAsString();
        final lines = content.split('\n');
        
        // Find last session's logs
        final lastSessionLogs = <String>[];
        bool inLastSession = false;
        
        for (var i = lines.length - 1; i >= 0; i--) {
          final line = lines[i];
          
          if (line.contains('Session ID:')) {
            if (inLastSession) break; // Found previous session start
            inLastSession = true;
          }
          
          if (inLastSession) {
            lastSessionLogs.insert(0, line);
          }
        }
        
        if (lastSessionLogs.isEmpty) return null;
        
        // Format crash report
        final report = StringBuffer();
        report.writeln('═══════════════════════════════════════');
        report.writeln('    MIYOLIST CRASH REPORT');
        report.writeln('═══════════════════════════════════════');
        report.writeln('');
        report.writeln('Platform: ${Platform.operatingSystem}');
        report.writeln('Version: ${Platform.operatingSystemVersion}');
        report.writeln('');
        report.writeln('─── Last Session Logs ───');
        report.writeln('');
        report.writeln(lastSessionLogs.join('\n'));
        report.writeln('');
        report.writeln('═══════════════════════════════════════');
        
        return report.toString();
      }
    } catch (e) {
      debugPrint('❌ Error getting crash report: $e');
    }
    
    return null;
  }

  /// Mark session start
  Future<void> markSessionStart() async {
    if (!_initialized) await initialize();

    try {
      await _sessionFile!.writeAsString(
        'SESSION_START|$_sessionId|${DateTime.now().toIso8601String()}\n',
        mode: FileMode.write,
      );
      await log('Session started', level: LogLevel.info);
    } catch (e) {
      debugPrint('❌ Error marking session start: $e');
    }
  }

  /// Mark graceful shutdown
  Future<void> markGracefulShutdown() async {
    if (!_initialized) return;

    try {
      await log('Graceful shutdown', level: LogLevel.info);
      await _sessionFile!.writeAsString(
        'SESSION_CLOSED|$_sessionId|${DateTime.now().toIso8601String()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('❌ Error marking shutdown: $e');
    }
  }

  /// Log a message
  Future<void> log(
    String message, {
    LogLevel level = LogLevel.debug,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!_initialized) return;

    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final levelStr = level.name.toUpperCase().padRight(5);
      
      final logMessage = StringBuffer();
      logMessage.write('[$timestamp] [$levelStr] $message');
      
      if (error != null) {
        logMessage.write('\nError: $error');
      }
      
      if (stackTrace != null) {
        logMessage.write('\nStack trace:\n$stackTrace');
      }
      
      logMessage.write('\n');

      // Write to file
      await _logFile!.writeAsString(
        logMessage.toString(),
        mode: FileMode.append,
      );

      // Also print in debug mode
      if (kDebugMode) {
        debugPrint(logMessage.toString().trim());
      }

      // Check if log rotation needed
      final fileSize = await _logFile!.length();
      if (fileSize > _maxLogSize) {
        await _rotateLogs();
      }
    } catch (e) {
      debugPrint('❌ Error writing log: $e');
    }
  }

  /// Rotate log files when they get too large
  Future<void> _rotateLogs() async {
    try {
      if (!await _logFile!.exists()) return;

      final directory = _logFile!.parent;
      
      // Rename existing log files
      for (var i = _maxLogFiles - 1; i >= 1; i--) {
        final oldFile = File('${directory.path}/app_logs_$i.txt');
        final newFile = File('${directory.path}/app_logs_${i + 1}.txt');
        
        if (await oldFile.exists()) {
          if (i == _maxLogFiles - 1) {
            await oldFile.delete(); // Delete oldest
          } else {
            await oldFile.rename(newFile.path);
          }
        }
      }
      
      // Rename current log to _1
      if (await _logFile!.exists()) {
        await _logFile!.rename('${directory.path}/app_logs_1.txt');
      }
      
      // Create new empty log file
      _logFile = File('${directory.path}/$_logFileName');
      await _logFile!.create();
      
    } catch (e) {
      debugPrint('❌ Error rotating logs: $e');
    }
  }

  /// Get all log files for debugging
  Future<List<File>> getAllLogFiles() async {
    if (!_initialized) await initialize();

    final directory = _logFile!.parent;
    final logFiles = <File>[];
    
    // Current log
    if (await _logFile!.exists()) {
      logFiles.add(_logFile!);
    }
    
    // Archived logs
    for (var i = 1; i <= _maxLogFiles; i++) {
      final file = File('${directory.path}/app_logs_$i.txt');
      if (await file.exists()) {
        logFiles.add(file);
      }
    }
    
    return logFiles;
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    try {
      final logFiles = await getAllLogFiles();
      for (final file in logFiles) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Recreate empty log file
      await _logFile!.create();
      await log('Logs cleared by user', level: LogLevel.info);
    } catch (e) {
      debugPrint('❌ Error clearing logs: $e');
    }
  }

  /// Get logs directory path
  Future<String> getLogsDirectory() async {
    if (!_initialized) await initialize();
    return _logFile!.parent.path;
  }

  /// Get formatted logs from current session (for debug dialog)
  Future<String> getCurrentSessionLogs() async {
    if (!_initialized) await initialize();

    try {
      if (await _logFile!.exists()) {
        final content = await _logFile!.readAsString();
        final lines = content.split('\n');
        
        // Find current session's logs
        final currentSessionLogs = <String>[];
        bool inCurrentSession = false;
        
        for (final line in lines) {
          if (line.contains('Session ID: $_sessionId')) {
            inCurrentSession = true;
          }
          
          if (inCurrentSession && line.trim().isNotEmpty) {
            currentSessionLogs.add(line);
          }
        }
        
        if (currentSessionLogs.isEmpty) {
          return 'No logs available for current session.';
        }
        
        // Format logs
        final report = StringBuffer();
        report.writeln('═══════════════════════════════════════');
        report.writeln('    MIYOLIST SESSION LOGS');
        report.writeln('═══════════════════════════════════════');
        report.writeln('');
        report.writeln('Platform: ${Platform.operatingSystem}');
        report.writeln('Version: ${Platform.operatingSystemVersion}');
        report.writeln('Session ID: $_sessionId');
        report.writeln('');
        report.writeln('─── Logs ───');
        report.writeln('');
        report.writeln(currentSessionLogs.join('\n'));
        report.writeln('');
        report.writeln('═══════════════════════════════════════');
        
        return report.toString();
      }
    } catch (e) {
      debugPrint('❌ Error getting session logs: $e');
      return 'Error loading logs: $e';
    }
    
    return 'No logs file found.';
  }
}

/// Log levels
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}
