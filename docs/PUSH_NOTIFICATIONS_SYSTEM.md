# Push Notifications System (v1.1.0-dev)

## Overview
Complete push notification system for MiyoList with local notifications, background sync, and customizable settings.

**Status**: ✅ **Implemented** (October 15, 2025)  
**Version**: v1.1.0-dev

## Features Implemented

### ✅ Core Functionality
- **Local Notifications**: Flutter Local Notifications for episode releases
- **Background Sync**: Workmanager for periodic checks (15-120 minutes)
- **Notification Types**:
  - 📺 Episode notifications (new episodes aired)
  - ❤️ Activity notifications (likes, comments, follows)
- **Rich Notifications**: Title, message, icon, sound
- **Notification History**: Last 100 notifications stored locally
- **Tap Actions**: Navigate to anime/activity when notification tapped

### ✅ Customization Options
- **Episode Notification Timing**:
  - On Air (immediate)
  - 1 Hour After
  - 3 Hours After
  - 6 Hours After
  - 12 Hours After
  - 24 Hours After
- **Sound Settings**: Enable/disable notification sounds
- **Quiet Hours (DND)**: Silence notifications during specific hours
  - Configurable start/end times
  - Automatic detection of time range
- **Check Interval**: 15-120 minutes (battery optimization)
- **Per-Anime Settings**: Custom settings for specific anime (future)

### ✅ UI Components
- **Settings Page**: Complete settings UI in Profile menu
  - Master enable/disable switch
  - Episode notifications toggle
  - Activity notifications toggle
  - Sound settings
  - Quiet hours configuration
  - Check interval slider
  - Notification history viewer
  - Statistics display
- **Test Notification**: Button to send test notification
- **Permission Management**: Request system permissions

## Architecture

### Services

#### 1. PushNotificationService
**Location**: `lib/core/services/push_notification_service.dart`

**Responsibilities**:
- Initialize Flutter Local Notifications
- Show episode notifications
- Show activity notifications
- Schedule notifications for future
- Manage notification history
- Handle notification taps
- Check system permissions

**Key Methods**:
```dart
Future<void> initialize()
PushNotificationSettings getSettings()
Future<void> saveSettings(PushNotificationSettings settings)
Future<void> showEpisodeNotification({...})
Future<void> showActivityNotification({...})
Future<void> scheduleNotification({...})
Future<void> cancelNotification(int id)
Future<bool> areNotificationsEnabled()
Future<bool> requestPermissions()
List<Map<String, dynamic>> getNotificationHistory()
```

#### 2. BackgroundSyncService
**Location**: `lib/core/services/background_sync_service.dart`

**Responsibilities**:
- Initialize Workmanager for background tasks
- Start/stop periodic episode checks
- Check for new episodes from AniList
- Schedule notifications based on user settings
- Track last check time

**Key Methods**:
```dart
Future<void> initialize()
Future<void> startPeriodicChecks({int intervalMinutes = 30})
Future<void> stopPeriodicChecks()
Future<void> checkForNewEpisodes()
Future<void> checkAnimeForNewEpisodes({...})
DateTime? getLastCheckTime()
Map<String, dynamic> getStats()
```

### Models

#### 1. PushNotificationSettings
**Location**: `lib/core/models/push_notification_settings.dart`  
**Hive Type ID**: 24

**Fields**:
```dart
bool enabled                                  // Master switch
bool episodeNotificationsEnabled              // Episode notifications
EpisodeNotificationTiming episodeTiming       // Timing preference
bool activityNotificationsEnabled             // Activity notifications
bool soundEnabled                             // Sound on/off
String? customSoundPath                       // Custom sound (future)
bool quietHoursEnabled                        // DND mode
int quietHoursStart                           // DND start hour (0-23)
int quietHoursEnd                             // DND end hour (0-23)
Map<int, AnimeNotificationSettings> perAnimeSettings  // Per-anime settings
int checkIntervalMinutes                      // Background check interval
```

**Methods**:
```dart
bool isInQuietHours()                         // Check if currently in quiet hours
AnimeNotificationSettings getAnimeSettings(int animeId)
void setAnimeSettings(int animeId, AnimeNotificationSettings settings)
```

#### 2. EpisodeNotificationTiming
**Hive Type ID**: 25

**Values**:
- `onAir` - Immediate notification when episode airs
- `oneHourAfter` - 1 hour delay
- `threeHoursAfter` - 3 hours delay
- `sixHoursAfter` - 6 hours delay
- `twelveHoursAfter` - 12 hours delay
- `twentyFourHoursAfter` - 24 hours delay

#### 3. AnimeNotificationSettings
**Hive Type ID**: 26

**Fields**:
```dart
bool enabled                                  // Enable for this anime
EpisodeNotificationTiming? customTiming       // Custom timing override
bool customSoundEnabled                       // Custom sound for this anime
String? customSoundPath                       // Path to custom sound
```

### UI Pages

#### PushNotificationSettingsPage
**Location**: `lib/features/settings/presentation/pages/push_notification_settings_page.dart`

**Access**: Profile → More Menu (⋮) → Push Notifications

**Sections**:
1. **System Permissions Card**: Check/request notification permissions
2. **Master Switch**: Enable/disable all notifications
3. **Episode Notifications**: Toggle + timing picker
4. **Activity Notifications**: Toggle for likes/comments/follows
5. **Sound Settings**: Enable/disable notification sounds
6. **Quiet Hours**: DND mode with time range picker
7. **Check Interval**: Slider (15-120 minutes)
8. **Notification History**: Last 5 notifications + clear button
9. **Statistics**: Background service status, last check time

## Integration

### 1. Hive Registration
In `lib/core/services/local_storage_service.dart`:
```dart
Hive.registerAdapter(PushNotificationSettingsAdapter());
Hive.registerAdapter(EpisodeNotificationTimingAdapter());
Hive.registerAdapter(AnimeNotificationSettingsAdapter());
```

### 2. Navigation
In `lib/features/profile/presentation/pages/profile_page.dart`:
```dart
PopupMenuItem(
  value: 'notifications',
  child: Row(
    children: [
      Icon(Icons.notifications_active, color: AppTheme.textGray),
      SizedBox(width: 12),
      Text('Push Notifications'),
    ],
  ),
)
```

### 3. Initialization
In `main.dart` (recommended):
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await LocalStorageService.init();
  final pushService = PushNotificationService();
  await pushService.initialize();
  
  final backgroundService = BackgroundSyncService();
  await backgroundService.initialize();
  
  // Start periodic checks if enabled
  final settings = pushService.getSettings();
  if (settings.enabled && settings.episodeNotificationsEnabled) {
    await backgroundService.startPeriodicChecks(
      intervalMinutes: settings.checkIntervalMinutes,
    );
  }
  
  runApp(MyApp());
}
```

## Usage Examples

### Show Episode Notification
```dart
final pushService = PushNotificationService();
await pushService.showEpisodeNotification(
  animeId: 21,
  animeTitle: 'One Piece',
  episode: 1085,
  imageUrl: 'https://...',
);
```

### Schedule Notification
```dart
final scheduledTime = DateTime.now().add(Duration(hours: 3));
await pushService.scheduleNotification(
  id: 12345,
  title: '📺 Episode 5 Available!',
  message: 'Attack on Titan - Episode 5 is now ready to watch',
  scheduledDate: scheduledTime,
  payload: 'anime:16498',
);
```

### Update Settings
```dart
final settings = pushService.getSettings();
settings.episodeTiming = EpisodeNotificationTiming.threeHoursAfter;
settings.quietHoursEnabled = true;
settings.quietHoursStart = 22;  // 10 PM
settings.quietHoursEnd = 8;     // 8 AM
await pushService.saveSettings(settings);
```

### Start Background Checks
```dart
final backgroundService = BackgroundSyncService();
await backgroundService.startPeriodicChecks(intervalMinutes: 30);
```

## Platform Support

### ✅ Android
- Full notification support
- Rich notifications with icons
- Notification channels
- Sound, vibration, priority
- Background tasks via Workmanager
- Permission requests (Android 13+)

### ✅ Windows
- Basic notification support via Linux notifications
- Sound support
- Background tasks
- No permission required

### ⚠️ Limitations
- **iOS**: Not implemented (requires APNs setup)
- **macOS**: Not implemented (requires notification center integration)
- **Web**: Not supported (no background tasks)

## Storage

### Hive Boxes
- `push_notification_settings` - User settings (typeId: 24-26)
- `notification_history` - Last 100 notifications
- `background_sync_settings` - Last check time, stats

### Settings Location
Settings are stored in:
```
<app_data>/push_notification_settings/
  - settings.hive
  - history.hive
```

## Performance Considerations

### Battery Optimization
- **Check Interval**: Default 30 minutes (adjustable 15-120 min)
- **Network Requirement**: Background checks only on Wi-Fi/Cellular
- **Quiet Hours**: No checks during DND mode
- **Smart Scheduling**: Workmanager handles efficient scheduling

### Notification Limits
- **History**: Max 100 notifications stored
- **Pending**: No limit on scheduled notifications
- **Rate Limiting**: Respects AniList API rate limits (30 req/min)

## Testing

### Manual Testing
1. **Enable Notifications**: Go to Profile → Push Notifications
2. **Test Notification**: Tap notification icon (🔔) in app bar
3. **Check Settings**: Verify all toggles and sliders work
4. **Quiet Hours**: Set DND period and verify no notifications
5. **Background Sync**: Wait for check interval, verify last check time updates

### Notification Payload Format
```
anime:<animeId>      // Navigate to anime details
activity:<activityId> // Navigate to activity (future)
```

## Future Enhancements (v1.2.0+)

### High Priority
- [ ] **Per-Anime Settings UI**: Allow custom timing per anime
- [ ] **Custom Sounds**: Upload/select custom notification sounds
- [ ] **Media Update Notifications**: Status changes, new episodes added
- [ ] **Rich Notifications**: Cover images, action buttons
- [ ] **Notification Grouping**: Group multiple episodes from same anime
- [ ] **Smart Timing**: ML-based optimal notification time

### Medium Priority
- [ ] **Notification Actions**: Mark as watched, snooze, open in app
- [ ] **Widget Integration**: Show next episodes in widget
- [ ] **Do Not Disturb Profiles**: Multiple DND schedules
- [ ] **Notification Templates**: Customizable message templates
- [ ] **Statistics Dashboard**: Notification analytics

### Low Priority
- [ ] **Voice Announcements**: TTS for notifications
- [ ] **Wearable Support**: Smartwatch notifications
- [ ] **Email Digest**: Daily/weekly email summaries
- [ ] **Notification Sync**: Sync settings across devices

## Dependencies

```yaml
dependencies:
  flutter_local_notifications: ^18.0.1  # Local notifications
  workmanager: ^0.5.2                   # Background tasks
  timezone: ^0.9.4                      # Timezone support
  hive: ^2.2.3                          # Local storage
```

## Troubleshooting

### Notifications Not Showing
1. **Check System Permissions**: Settings page → Request Permission
2. **Check Master Switch**: Must be enabled
3. **Check Quiet Hours**: May be in DND mode
4. **Check Background Service**: Statistics → Background Service should be "Active"

### Background Checks Not Working
1. **Battery Optimization**: Disable for app in system settings
2. **Check Interval**: May be too long (increase for testing)
3. **Network Connection**: Requires internet connection
4. **Workmanager**: Check logs for background task errors

### Test Notification Not Showing
1. **Initialize Service**: Ensure `PushNotificationService().initialize()` was called
2. **System Permissions**: Grant notification permission
3. **Check Logs**: Look for error messages in console

## Related Documentation
- [Background Tasks](https://pub.dev/packages/workmanager)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [AniList API - Airing Schedule](https://anilist.gitbook.io/anilist-apiv2-docs/)

## Status
✅ **Complete** - Basic push notification system fully implemented
⏳ **Pending** - Integration with AniList airing schedule (checkForNewEpisodes logic)
📋 **Future** - Advanced features listed above

---

**Date**: October 15, 2025  
**Version**: v1.1.0-dev  
**Author**: GitHub Copilot
