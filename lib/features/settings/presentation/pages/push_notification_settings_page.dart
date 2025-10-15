import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/push_notification_settings.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/background_sync_service.dart';
import '../../../../core/theme/app_theme.dart';

class PushNotificationSettingsPage extends StatefulWidget {
  const PushNotificationSettingsPage({super.key});

  @override
  State<PushNotificationSettingsPage> createState() =>
      _PushNotificationSettingsPageState();
}

class _PushNotificationSettingsPageState
    extends State<PushNotificationSettingsPage> {
  final _pushService = PushNotificationService();
  final _backgroundService = BackgroundSyncService();
  late PushNotificationSettings _settings;
  bool _loading = true;
  bool _systemNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    
    await _pushService.initialize();
    await _backgroundService.initialize();
    
    _settings = _pushService.getSettings();
    _systemNotificationsEnabled = await _pushService.areNotificationsEnabled();
    
    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    await _pushService.saveSettings(_settings);

    // Обновить фоновые задачи
    if (_settings.enabled && _settings.episodeNotificationsEnabled) {
      await _backgroundService.startPeriodicChecks(
        intervalMinutes: _settings.checkIntervalMinutes,
      );
    } else {
      await _backgroundService.stopPeriodicChecks();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Settings saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _pushService.requestPermissions();
    setState(() => _systemNotificationsEnabled = granted);

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Permission denied. Please enable in system settings.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _pushService.showEpisodeNotification(
      animeId: 1,
      animeTitle: 'Test Anime',
      episode: 1,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Push Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _testNotification,
            tooltip: 'Test Notification',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSystemPermissionsCard(),
          const SizedBox(height: 16),
          _buildMasterSwitchCard(),
          const SizedBox(height: 16),
          _buildEpisodeNotificationsCard(),
          const SizedBox(height: 16),
          _buildActivityNotificationsCard(),
          const SizedBox(height: 16),
          _buildSoundSettingsCard(),
          const SizedBox(height: 16),
          _buildQuietHoursCard(),
          const SizedBox(height: 16),
          _buildCheckIntervalCard(),
          const SizedBox(height: 16),
          _buildNotificationHistoryCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildSystemPermissionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _systemNotificationsEnabled
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _systemNotificationsEnabled
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  'System Permissions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _systemNotificationsEnabled
                  ? 'Notifications are enabled for this app'
                  : 'Notifications are disabled in system settings',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!_systemNotificationsEnabled) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: const Icon(Icons.settings),
                label: const Text('Request Permission'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMasterSwitchCard() {
    return Card(
      child: SwitchListTile(
        value: _settings.enabled,
        onChanged: (value) {
          setState(() {
            _settings.enabled = value;
          });
        },
        title: const Text('Enable Push Notifications'),
        subtitle: const Text('Master switch for all push notifications'),
        secondary: Icon(
          _settings.enabled ? Icons.notifications_active : Icons.notifications_off,
          color: _settings.enabled ? AppTheme.accentBlue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildEpisodeNotificationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tv, color: AppTheme.accentBlue),
                const SizedBox(width: 12),
                Text(
                  'Episode Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _settings.episodeNotificationsEnabled,
              onChanged: _settings.enabled
                  ? (value) {
                      setState(() {
                        _settings.episodeNotificationsEnabled = value;
                      });
                    }
                  : null,
              title: const Text('Enable Episode Notifications'),
              subtitle: const Text('Get notified when new episodes air'),
            ),
            if (_settings.episodeNotificationsEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Notification Timing'),
                subtitle: Text(_settings.episodeTiming.displayName),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showTimingPicker(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityNotificationsCard() {
    return Card(
      child: SwitchListTile(
        value: _settings.activityNotificationsEnabled,
        onChanged: _settings.enabled
            ? (value) {
                setState(() {
                  _settings.activityNotificationsEnabled = value;
                });
              }
            : null,
        title: const Text('Activity Notifications'),
        subtitle: const Text('Likes, comments, and follows'),
        secondary: Icon(Icons.favorite, color: AppTheme.accentRed),
      ),
    );
  }

  Widget _buildSoundSettingsCard() {
    return Card(
      child: SwitchListTile(
        value: _settings.soundEnabled,
        onChanged: _settings.enabled
            ? (value) {
                setState(() {
                  _settings.soundEnabled = value;
                });
              }
            : null,
        title: const Text('Notification Sound'),
        subtitle: const Text('Play sound for notifications'),
        secondary: Icon(
          _settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
          color: AppTheme.accentBlue,
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: AppTheme.accentPurple),
                const SizedBox(width: 12),
                Text(
                  'Quiet Hours (DND)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _settings.quietHoursEnabled,
              onChanged: _settings.enabled
                  ? (value) {
                      setState(() {
                        _settings.quietHoursEnabled = value;
                      });
                    }
                  : null,
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text('Silence notifications during specific hours'),
            ),
            if (_settings.quietHoursEnabled) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start Time'),
                subtitle: Text('${_settings.quietHoursStart}:00'),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text('End Time'),
                subtitle: Text('${_settings.quietHoursEnd}:00'),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _pickTime(isStart: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckIntervalCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: AppTheme.accentGreen),
                const SizedBox(width: 12),
                Text(
                  'Check Interval',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'How often to check for new episodes (minutes)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _settings.checkIntervalMinutes.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 7,
                    label: '${_settings.checkIntervalMinutes} min',
                    onChanged: _settings.enabled
                        ? (value) {
                            setState(() {
                              _settings.checkIntervalMinutes = value.toInt();
                            });
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '${_settings.checkIntervalMinutes} min',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            Text(
              'Note: Shorter intervals use more battery',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryCard() {
    final history = _pushService.getNotificationHistory();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppTheme.accentBlue),
                const SizedBox(width: 12),
                Text(
                  'Notification History',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      await _pushService.clearNotificationHistory();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No notification history yet'),
                ),
              )
            else
              ...history.take(5).map((entry) {
                final timestamp = DateTime.fromMillisecondsSinceEpoch(
                  entry['timestamp'] as int,
                );
                return ListTile(
                  leading: Icon(
                    entry['type'] == 'episode' ? Icons.tv : Icons.favorite,
                    color: entry['type'] == 'episode'
                        ? AppTheme.accentBlue
                        : AppTheme.accentRed,
                  ),
                  title: Text(entry['title'] as String),
                  subtitle: Text(entry['message'] as String),
                  trailing: Text(
                    DateFormat('MMM d, HH:mm').format(timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }),
            if (history.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+${history.length - 5} more',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _backgroundService.getStats();
    final lastCheck = stats['lastCheck'] != null
        ? DateTime.parse(stats['lastCheck'] as String)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.accentGreen),
                const SizedBox(width: 12),
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Background Service', stats['isEnabled'] ? 'Active' : 'Inactive'),
            _buildStatRow(
              'Last Check',
              lastCheck != null
                  ? DateFormat('MMM d, HH:mm').format(lastCheck)
                  : 'Never',
            ),
            if (stats['timeSinceLastCheck'] != null)
              _buildStatRow(
                'Time Since Check',
                '${stats['timeSinceLastCheck']} minutes ago',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimingPicker() async {
    final selected = await showDialog<EpisodeNotificationTiming>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Timing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EpisodeNotificationTiming.values.map((timing) {
            return RadioListTile<EpisodeNotificationTiming>(
              value: timing,
              groupValue: _settings.episodeTiming,
              onChanged: (value) => Navigator.pop(context, value),
              title: Text(timing.displayName),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _settings.episodeTiming = selected;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final currentHour = isStart
        ? _settings.quietHoursStart
        : _settings.quietHoursEnd;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _settings.quietHoursStart = time.hour;
        } else {
          _settings.quietHoursEnd = time.hour;
        }
      });
    }
  }
}
