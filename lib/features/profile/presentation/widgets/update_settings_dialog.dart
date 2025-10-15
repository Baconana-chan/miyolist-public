import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/widgets/update_dialog.dart';

/// Dialog for app update settings
class UpdateSettingsDialog extends StatefulWidget {
  const UpdateSettingsDialog({super.key});

  @override
  State<UpdateSettingsDialog> createState() => _UpdateSettingsDialogState();
}

class _UpdateSettingsDialogState extends State<UpdateSettingsDialog> {
  final UpdateService _updateService = UpdateService();
  final LocalStorageService _localStorageService = LocalStorageService();
  
  bool _autoCheckUpdates = true;
  int _reminderIntervalDays = 7;
  bool _isLoading = true;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = _localStorageService.getUserSettings();
      
      if (mounted) {
        setState(() {
          _autoCheckUpdates = settings?.autoCheckUpdates ?? true;
          _reminderIntervalDays = settings?.updateReminderIntervalDays ?? 7;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[UpdateSettingsDialog] Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settings = _localStorageService.getUserSettings();
      if (settings == null) return;

      final updatedSettings = settings.copyWith(
        autoCheckUpdates: _autoCheckUpdates,
        updateReminderIntervalDays: _reminderIntervalDays,
      );

      await _localStorageService.saveUserSettings(updatedSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[UpdateSettingsDialog] Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkForUpdatesNow() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final updateInfo = await _updateService.checkForUpdates();

      if (!mounted) return;

      if (updateInfo == null) {
        // No update available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You\'re on the latest version! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Update available - show update dialog
        await _updateService.clearSkippedVersion(); // Clear any skipped version
        await _updateService.updateLastCheckTime();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            updateInfo: updateInfo,
            onSkip: () async {
              await _updateService.setSkippedVersion(updateInfo.version);
            },
            onRemindLater: () async {
              await _updateService.updateLastCheckTime();
            },
            onUpdate: () {
              // Download initiated
            },
          ),
        );
      }
    } catch (e) {
      print('[UpdateSettingsDialog] Error checking for updates: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.system_update_alt,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Update Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-check updates toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.autorenew,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Auto-check for updates',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check for updates on app startup',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoCheckUpdates,
                          onChanged: (value) {
                            setState(() => _autoCheckUpdates = value);
                            _saveSettings();
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reminder interval
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Reminder interval',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How often to remind you about updates',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Interval buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _IntervalChip(
                              label: '1 day',
                              days: 1,
                              selected: _reminderIntervalDays == 1,
                              onTap: () {
                                setState(() => _reminderIntervalDays = 1);
                                _saveSettings();
                              },
                            ),
                            _IntervalChip(
                              label: '3 days',
                              days: 3,
                              selected: _reminderIntervalDays == 3,
                              onTap: () {
                                setState(() => _reminderIntervalDays = 3);
                                _saveSettings();
                              },
                            ),
                            _IntervalChip(
                              label: '7 days',
                              days: 7,
                              selected: _reminderIntervalDays == 7,
                              onTap: () {
                                setState(() => _reminderIntervalDays = 7);
                                _saveSettings();
                              },
                            ),
                            _IntervalChip(
                              label: '14 days',
                              days: 14,
                              selected: _reminderIntervalDays == 14,
                              onTap: () {
                                setState(() => _reminderIntervalDays = 14);
                                _saveSettings();
                              },
                            ),
                            _IntervalChip(
                              label: '30 days',
                              days: 30,
                              selected: _reminderIntervalDays == 30,
                              onTap: () {
                                setState(() => _reminderIntervalDays = 30);
                                _saveSettings();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Manual check button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCheckingUpdate ? null : _checkForUpdatesNow,
                      icon: _isCheckingUpdate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isCheckingUpdate
                            ? 'Checking...'
                            : 'Check for Updates Now',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Release notes link
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(_updateService.getReleasesPageUrl());
                        final urlLauncher = await url_launcher.canLaunchUrl(url);
                        if (urlLauncher) {
                          await url_launcher.launchUrl(
                            url,
                            mode: url_launcher.LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('View All Releases'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip for interval selection
class _IntervalChip extends StatelessWidget {
  final String label;
  final int days;
  final bool selected;
  final VoidCallback onTap;

  const _IntervalChip({
    required this.label,
    required this.days,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.colorScheme.primary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
