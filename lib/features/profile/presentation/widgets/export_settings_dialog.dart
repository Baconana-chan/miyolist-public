import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/models/user_settings.dart';
import '../../../../core/services/local_storage_service.dart';

/// Dialog for configuring export settings (custom save path)
class ExportSettingsDialog extends StatefulWidget {
  const ExportSettingsDialog({super.key});

  @override
  State<ExportSettingsDialog> createState() => _ExportSettingsDialogState();
}

class _ExportSettingsDialogState extends State<ExportSettingsDialog> {
  final LocalStorageService _storageService = LocalStorageService();
  bool _isLoading = true;
  String? _currentPath;
  bool _useDefaultPath = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storageService.getUserSettings();
    setState(() {
      _currentPath = settings?.exportPath;
      _useDefaultPath = _currentPath == null || _currentPath!.isEmpty;
      _isLoading = false;
    });
  }

  Future<void> _pickDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        setState(() {
          _currentPath = selectedDirectory;
          _useDefaultPath = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _currentPath = null;
      _useDefaultPath = true;
    });
  }

  Future<void> _saveSettings() async {
    try {
      final settings = await _storageService.getUserSettings();
      if (settings != null) {
        final updatedSettings = settings.copyWith(
          exportPath: _useDefaultPath ? null : _currentPath,
          updatedAt: DateTime.now(),
        );

        await _storageService.saveUserSettings(updatedSettings);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export settings saved successfully! ✅'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDefaultPath() {
    // Show approximate default path
    if (Platform.isWindows) {
      return '%APPDATA%/MiyoList/MiyoList_Exports';
    } else if (Platform.isAndroid) {
      return '/data/data/com.miyolist.app/files/MiyoList_Exports';
    } else if (Platform.isMacOS) {
      return '~/Library/Application Support/MiyoList/MiyoList_Exports';
    } else if (Platform.isLinux) {
      return '~/.local/share/MiyoList/MiyoList_Exports';
    }
    return 'App Directory/MiyoList_Exports';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.folder_open, color: Color(0xFF2196F3)),
          SizedBox(width: 12),
          Text('Export Settings'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure where exported images are saved.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Default path option
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _useDefaultPath,
                    onChanged: (value) {
                      setState(() {
                        _useDefaultPath = true;
                      });
                    },
                    title: const Text('Use default app folder'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getDefaultPath(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Custom path option
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _useDefaultPath,
                    onChanged: (value) {
                      setState(() {
                        _useDefaultPath = false;
                      });
                    },
                    title: const Text('Use custom folder'),
                    subtitle: _currentPath != null && !_useDefaultPath
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _currentPath!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                  ),

                  if (!_useDefaultPath) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickDirectory,
                            icon: const Icon(Icons.folder_open, size: 20),
                            label: const Text('Browse...'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Exported images will be saved with timestamps in the selected folder.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
