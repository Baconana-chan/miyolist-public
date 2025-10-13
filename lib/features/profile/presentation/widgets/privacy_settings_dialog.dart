import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/user_settings.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_enum.dart';
import '../../../../core/providers/theme_provider.dart';

class PrivacySettingsDialog extends StatefulWidget {
  final UserSettings currentSettings;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const PrivacySettingsDialog({
    super.key,
    required this.currentSettings,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<PrivacySettingsDialog> createState() => _PrivacySettingsDialogState();
}

class _PrivacySettingsDialogState extends State<PrivacySettingsDialog> {
  late bool _isPublic;
  late bool _enableCloudSync;
  late bool _enableSocialFeatures;
  late int _cacheSizeLimitMB;
  late bool _syncAnimeList;
  late bool _syncMangaList;
  late bool _syncFavorites;
  late bool _syncUserProfile;
  late bool _showAnimeTab;
  late bool _showMangaTab;
  late bool _showNovelTab;
  late AppThemeMode _selectedTheme;
  bool _isLoading = false;
  Map<String, dynamic>? _dbStats;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.currentSettings.isPublicProfile;
    _enableCloudSync = widget.currentSettings.enableCloudSync;
    _enableSocialFeatures = widget.currentSettings.enableSocialFeatures;
    _cacheSizeLimitMB = widget.currentSettings.cacheSizeLimitMB;
    _syncAnimeList = widget.currentSettings.syncAnimeList;
    _syncMangaList = widget.currentSettings.syncMangaList;
    _syncFavorites = widget.currentSettings.syncFavorites;
    _syncUserProfile = widget.currentSettings.syncUserProfile;
    _showAnimeTab = widget.currentSettings.showAnimeTab;
    _showMangaTab = widget.currentSettings.showMangaTab;
    _showNovelTab = widget.currentSettings.showNovelTab;
    _selectedTheme = AppThemeMode.fromValue(widget.currentSettings.themeMode);
    _loadDatabaseStats();
  }

  Future<void> _loadDatabaseStats() async {
    final stats = await widget.localStorageService.getDatabaseStats();
    if (mounted) {
      setState(() => _dbStats = stats);
    }
  }

  void _onProfileTypeChanged(bool? value) {
    if (value == null) return;
    
    setState(() {
      _isPublic = value;
      if (value) {
        // Public profile enables cloud sync and social features
        _enableCloudSync = true;
        _enableSocialFeatures = true;
      } else {
        // Private profile disables everything
        _enableCloudSync = false;
        _enableSocialFeatures = false;
      }
    });
  }

  Future<void> _saveSettings() async {
    // Validate that at least one tab is visible
    if (!_showAnimeTab && !_showMangaTab && !_showNovelTab) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one tab must be visible'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newSettings = widget.currentSettings.copyWith(
        isPublicProfile: _isPublic,
        enableCloudSync: _enableCloudSync,
        enableSocialFeatures: _enableSocialFeatures,
        cacheSizeLimitMB: _cacheSizeLimitMB,
        syncAnimeList: _syncAnimeList,
        syncMangaList: _syncMangaList,
        syncFavorites: _syncFavorites,
        syncUserProfile: _syncUserProfile,
        showAnimeTab: _showAnimeTab,
        showMangaTab: _showMangaTab,
        showNovelTab: _showNovelTab,
        themeMode: _selectedTheme.value,
        updatedAt: DateTime.now(),
      );

      // Save settings locally
      await widget.localStorageService.saveUserSettings(newSettings);
      
      // Update theme if changed
      if (widget.currentSettings.themeMode != _selectedTheme.value) {
        if (mounted) {
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          await themeProvider.setTheme(_selectedTheme);
        }
      }

      // Check if tab visibility changed
      final tabsChanged = widget.currentSettings.showAnimeTab != _showAnimeTab ||
                          widget.currentSettings.showMangaTab != _showMangaTab ||
                          widget.currentSettings.showNovelTab != _showNovelTab;

      // If switching from public to private, show warning about cloud data
      if (widget.currentSettings.isPublicProfile && !_isPublic) {
        final confirmed = await _showPrivateWarning();
        if (!confirmed) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // If switching to public, sync data to cloud
      if (!widget.currentSettings.enableCloudSync && _enableCloudSync) {
        await _syncToCloud();
      }

      if (mounted) {
        Navigator.of(context).pop(newSettings);
        
        // Show info about tab visibility change
        if (tabsChanged) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tab visibility updated. Please return to home to see changes.'),
              backgroundColor: AppTheme.accentBlue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showPrivateWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch to Private Profile?'),
        content: const Text(
          'Switching to private profile will:\n\n'
          '• Stop cloud synchronization\n'
          '• Disable social features\n'
          '• Keep data only on this device\n\n'
          'Your existing cloud data will remain in the database but won\'t be updated.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
            ),
            child: const Text('Switch to Private'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _syncToCloud() async {
    try {
      final user = widget.localStorageService.getUser();
      if (user == null) return;

      // Sync user data
      await widget.supabaseService.syncUserData(user.toJson());

      // Sync lists
      final animeList = widget.localStorageService.getAnimeList();
      await widget.supabaseService.syncAnimeList(
        user.id,
        animeList.map((e) => e.toJson()).toList(),
      );

      final mangaList = widget.localStorageService.getMangaList();
      await widget.supabaseService.syncMangaList(
        user.id,
        mangaList.map((e) => e.toJson()).toList(),
      );

      // Sync favorites
      final favorites = widget.localStorageService.getFavorites();
      if (favorites != null) {
        await widget.supabaseService.syncFavorites(user.id, favorites);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced to cloud successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Cloud sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud sync failed: $e')),
        );
      }
    }
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will clear all cached media details. '
          'Your anime/manga lists will not be affected.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.localStorageService.mediaCacheBox.clear();
      await _loadDatabaseStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.privacy_tip,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('Privacy Settings'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Type
            Text(
              'Profile Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            RadioListTile<bool>(
              title: const Text('Private Profile'),
              subtitle: const Text('Local only, no cloud sync'),
              value: false,
              groupValue: _isPublic,
              onChanged: _onProfileTypeChanged,
              activeColor: AppTheme.accentBlue,
              secondary: const Icon(Icons.lock),
            ),
            
            RadioListTile<bool>(
              title: const Text('Public Profile'),
              subtitle: const Text('Cloud sync and social features'),
              value: true,
              groupValue: _isPublic,
              onChanged: _onProfileTypeChanged,
              activeColor: AppTheme.accentRed,
              secondary: const Icon(Icons.public),
            ),
            
            const Divider(height: 32),
            
            // Features
            Text(
              'Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SwitchListTile(
              title: const Text('Cloud Sync'),
              subtitle: const Text('Sync data across devices'),
              value: _enableCloudSync,
              onChanged: _isPublic ? null : null,
              secondary: const Icon(Icons.cloud),
              activeColor: AppTheme.accentRed,
            ),
            
            SwitchListTile(
              title: const Text('Social Features'),
              subtitle: const Text('Interact with community'),
              value: _enableSocialFeatures,
              onChanged: _isPublic ? null : null,
              secondary: const Icon(Icons.people),
              activeColor: AppTheme.accentRed,
            ),
            
            // Selective Sync Options (only show if cloud sync is enabled)
            if (_enableCloudSync) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          size: 18,
                          color: AppTheme.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selective Sync',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose which data to sync to the cloud',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              
              CheckboxListTile(
                title: const Text('Anime List'),
                subtitle: const Text('Sync your anime watching list'),
                value: _syncAnimeList,
                onChanged: (value) => setState(() => _syncAnimeList = value ?? true),
                activeColor: AppTheme.accentRed,
                secondary: const Icon(Icons.tv, size: 20),
                dense: true,
              ),
              
              CheckboxListTile(
                title: const Text('Manga List'),
                subtitle: const Text('Sync your manga reading list'),
                value: _syncMangaList,
                onChanged: (value) => setState(() => _syncMangaList = value ?? true),
                activeColor: AppTheme.accentRed,
                secondary: const Icon(Icons.book, size: 20),
                dense: true,
              ),
              
              CheckboxListTile(
                title: const Text('Favorites'),
                subtitle: const Text('Sync your favorite characters and staff'),
                value: _syncFavorites,
                onChanged: (value) => setState(() => _syncFavorites = value ?? true),
                activeColor: AppTheme.accentRed,
                secondary: const Icon(Icons.favorite, size: 20),
                dense: true,
              ),
              
              CheckboxListTile(
                title: const Text('User Profile'),
                subtitle: const Text('Sync profile information'),
                value: _syncUserProfile,
                onChanged: (value) => setState(() => _syncUserProfile = value ?? true),
                activeColor: AppTheme.accentRed,
                secondary: const Icon(Icons.person, size: 20),
                dense: true,
              ),
              
              if (!_syncAnimeList && !_syncMangaList && !_syncFavorites && !_syncUserProfile)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No data will be synced to the cloud',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            
            const Divider(height: 32),
            
            // Tab Visibility Settings
            Text(
              'Tab Visibility',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Text(
                'Choose which tabs to show in the main view',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            CheckboxListTile(
              title: const Text('Anime Tab'),
              subtitle: const Text('Show anime list tab'),
              value: _showAnimeTab,
              onChanged: (value) => setState(() => _showAnimeTab = value ?? true),
              activeColor: AppTheme.accentRed,
              secondary: const Icon(Icons.tv, size: 20),
              dense: true,
            ),
            
            CheckboxListTile(
              title: const Text('Manga Tab'),
              subtitle: const Text('Show manga list tab'),
              value: _showMangaTab,
              onChanged: (value) => setState(() => _showMangaTab = value ?? true),
              activeColor: AppTheme.accentRed,
              secondary: const Icon(Icons.book, size: 20),
              dense: true,
            ),
            
            CheckboxListTile(
              title: const Text('Novels Tab'),
              subtitle: const Text('Show light novels list tab'),
              value: _showNovelTab,
              onChanged: (value) => setState(() => _showNovelTab = value ?? true),
              activeColor: AppTheme.accentRed,
              secondary: const Icon(Icons.menu_book, size: 20),
              dense: true,
            ),
            
            if (!_showAnimeTab && !_showMangaTab && !_showNovelTab)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: AppTheme.accentRed,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'At least one tab must be visible',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const Divider(height: 32),
            
            // Theme Settings
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              child: Text(
                'Choose your preferred app theme',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildThemeSelector(),
            
            const Divider(height: 32),
            
            // Storage Settings
            Text(
              'Storage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Database size info
            if (_dbStats != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textGray.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storage, color: AppTheme.accentRed, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Database Usage',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(_dbStats!['totalSizeMB'] as double).toStringAsFixed(2)} MB',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentRed,
                              ),
                            ),
                            Text(
                              'of $_cacheSizeLimitMB MB',
                              style: const TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_dbStats!['totalSizeMB'] as double) / _cacheSizeLimitMB,
                            minHeight: 8,
                            backgroundColor: AppTheme.textGray.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (_dbStats!['totalSizeMB'] as double) / _cacheSizeLimitMB > 0.8
                                  ? Colors.orange
                                  : AppTheme.accentRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Detailed stats
                    _buildStatRow('Anime Entries', _dbStats!['animeListEntries']),
                    _buildStatRow('Manga Entries', _dbStats!['mangaListEntries']),
                    _buildStatRow('Cached Media', _dbStats!['mediaCacheEntries']),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Cache limit slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cache Size Limit'),
                      Text(
                        '$_cacheSizeLimitMB MB',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentRed,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _cacheSizeLimitMB.toDouble(),
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: '$_cacheSizeLimitMB MB',
                    activeColor: AppTheme.accentRed,
                    onChanged: (value) {
                      setState(() => _cacheSizeLimitMB = value.round());
                    },
                  ),
                  Text(
                    'Recommended: 200 MB',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
              
              // Clear cache button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearCache,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Cached Media'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            
            if (!_isPublic)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Private profiles cannot use cloud sync or social features',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentBlue,
                        ),
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
  
  Widget _buildThemeSelector() {
    return Column(
      children: AppThemeMode.values.map((mode) {
        final isSelected = _selectedTheme == mode;
        final colors = AppTheme.getThemeColors(mode);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _selectedTheme = mode),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? colors.primaryAccent.withOpacity(0.1) 
                    : AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? colors.primaryAccent 
                      : AppTheme.textGray.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Theme preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primaryBackground,
                          colors.secondaryBackground,
                        ],
                      ),
                      border: Border.all(
                        color: colors.primaryAccent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.secondaryAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Theme info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? colors.primaryAccent : AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getThemeDescription(mode),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colors.primaryAccent,
                      size: 28,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: AppTheme.textGray.withOpacity(0.5),
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return 'Classic manga-style dark theme';
      case AppThemeMode.light:
        return 'Clean and bright light theme';
      case AppThemeMode.carrot:
        return 'Warm orange tones with carrot vibes';
    }
  }
}
