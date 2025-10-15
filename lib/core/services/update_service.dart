import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for checking and managing app updates from GitHub releases
class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/Baconana-chan/miyolist-public/releases/latest';
  static const String _releasesPageUrl =
      'https://github.com/Baconana-chan/miyolist-public/releases';

  // SharedPreferences keys
  static const String _keyAutoCheckEnabled = 'update_auto_check_enabled';
  static const String _keyLastCheckTime = 'update_last_check_time';
  static const String _keySkippedVersion = 'update_skipped_version';
  static const String _keyReminderInterval = 'update_reminder_interval'; // in days

  /// Check if there's a new version available
  /// Returns UpdateInfo if update available, null otherwise
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      print('[UpdateService] Current version: $currentVersion');

      // Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode != 200) {
        print('[UpdateService] Failed to fetch release info: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      // Parse release data
      final latestVersion = _parseVersion(data['tag_name'] as String? ?? '');
      final releaseUrl = data['html_url'] as String? ?? _releasesPageUrl;
      final changelog = data['body'] as String? ?? 'No changelog available.';
      final publishedAt = DateTime.tryParse(data['published_at'] as String? ?? '');

      // Find download asset (Windows .exe or .msix)
      String? downloadUrl;
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final assetMap = asset as Map<String, dynamic>;
        final name = assetMap['name'] as String? ?? '';
        if (name.endsWith('.exe') || name.endsWith('.msix') || name.endsWith('.zip')) {
          downloadUrl = assetMap['browser_download_url'] as String?;
          break;
        }
      }

      print('[UpdateService] Latest version: $latestVersion');

      // Compare versions
      if (_isNewerVersion(currentVersion, latestVersion)) {
        print('[UpdateService] Update available: $latestVersion');
        return UpdateInfo(
          version: latestVersion,
          currentVersion: currentVersion,
          downloadUrl: downloadUrl ?? releaseUrl,
          releaseUrl: releaseUrl,
          changelog: changelog,
          publishedAt: publishedAt,
        );
      }

      print('[UpdateService] App is up to date');
      return null;
    } catch (e) {
      print('[UpdateService] Error checking for updates: $e');
      return null;
    }
  }

  /// Parse version string (removes 'v' prefix if present)
  String _parseVersion(String versionTag) {
    return versionTag.startsWith('v') ? versionTag.substring(1) : versionTag;
  }

  /// Compare two version strings (e.g., "1.1.2" vs "1.2.0")
  /// Returns true if newVersion is newer than currentVersion
  bool _isNewerVersion(String currentVersion, String newVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = newVersion.split('.').map(int.parse).toList();

      // Pad with zeros if needed
      while (current.length < 3) current.add(0);
      while (latest.length < 3) latest.add(0);

      // Compare major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      print('[UpdateService] Error comparing versions: $e');
      return false;
    }
  }

  /// Check if auto-check is enabled
  Future<bool> isAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoCheckEnabled) ?? true; // Enabled by default
  }

  /// Set auto-check enabled/disabled
  Future<void> setAutoCheckEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheckEnabled, enabled);
  }

  /// Get last check time
  Future<DateTime?> getLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastCheckTime);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Update last check time to now
  Future<void> updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastCheckTime, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get skipped version (user chose "Skip this version")
  Future<String?> getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySkippedVersion);
  }

  /// Set skipped version
  Future<void> setSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySkippedVersion, version);
  }

  /// Clear skipped version
  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySkippedVersion);
  }

  /// Get reminder interval in days (default: 7 days)
  Future<int> getReminderInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderInterval) ?? 7;
  }

  /// Set reminder interval in days
  Future<void> setReminderInterval(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderInterval, days);
  }

  /// Check if should show update reminder
  /// (based on reminder interval and skipped version)
  Future<bool> shouldShowUpdateReminder(UpdateInfo updateInfo) async {
    // Check if this version was skipped
    final skippedVersion = await getSkippedVersion();
    if (skippedVersion == updateInfo.version) {
      return false;
    }

    // Check if enough time has passed since last check
    final lastCheck = await getLastCheckTime();
    if (lastCheck == null) return true;

    final reminderInterval = await getReminderInterval();
    final daysSinceLastCheck = DateTime.now().difference(lastCheck).inDays;

    return daysSinceLastCheck >= reminderInterval;
  }

  /// Get releases page URL
  String getReleasesPageUrl() => _releasesPageUrl;
}

/// Information about available update
class UpdateInfo {
  final String version;
  final String currentVersion;
  final String downloadUrl;
  final String releaseUrl;
  final String changelog;
  final DateTime? publishedAt;

  UpdateInfo({
    required this.version,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseUrl,
    required this.changelog,
    this.publishedAt,
  });

  /// Format changelog for display (parse markdown basics)
  String get formattedChangelog {
    // Simple markdown parsing
    var formatted = changelog;

    // Remove HTML comments
    formatted = formatted.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

    // Convert **bold** to uppercase
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1)!.toUpperCase(),
    );

    return formatted.trim();
  }

  /// Get human-readable time since published
  String get timeSincePublished {
    if (publishedAt == null) return 'Recently';

    final now = DateTime.now();
    final difference = now.difference(publishedAt!);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
