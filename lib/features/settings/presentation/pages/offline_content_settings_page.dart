import 'package:flutter/material.dart';
import 'package:miyolist/core/theme/app_theme.dart';
import 'package:miyolist/core/services/local_storage_service.dart';
import 'package:miyolist/core/services/image_cache_service.dart';

/// Page for configuring what content to cache for offline access
class OfflineContentSettingsPage extends StatefulWidget {
  final LocalStorageService localStorageService;

  const OfflineContentSettingsPage({
    super.key,
    required this.localStorageService,
  });

  @override
  State<OfflineContentSettingsPage> createState() => _OfflineContentSettingsPageState();
}

class _OfflineContentSettingsPageState extends State<OfflineContentSettingsPage> {
  final _imageCacheService = ImageCacheService();
  
  bool _cacheListCovers = true;
  bool _cacheFavoriteCovers = true;
  bool _cacheCharacterImages = false;
  bool _cacheStaffImages = false;
  bool _cacheBannerImages = false;
  bool _cacheTrendingCovers = false;
  bool _cacheSearchResults = false;

  int _cacheSize = 0;
  int _imageCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheInfo();
  }

  void _loadSettings() {
    final settings = widget.localStorageService.getUserSettings();
    if (settings != null) {
      setState(() {
        _cacheListCovers = settings.cacheListCovers;
        _cacheFavoriteCovers = settings.cacheFavoriteCovers;
        _cacheCharacterImages = settings.cacheCharacterImages;
        _cacheStaffImages = settings.cacheStaffImages;
        _cacheBannerImages = settings.cacheBannerImages;
        _cacheTrendingCovers = settings.cacheTrendingCovers;
        _cacheSearchResults = settings.cacheSearchResults;
      });
    }
  }

  Future<void> _loadCacheInfo() async {
    try {
      final size = await _imageCacheService.getCacheSize();
      final count = await _imageCacheService.getCachedImageCount();
      
      if (mounted) {
        setState(() {
          _cacheSize = size;
          _imageCount = count;
        });
      }
    } catch (e) {
      print('Error loading cache info: $e');
    }
  }

  Future<void> _saveSetting(String setting, bool value) async {
    final settings = widget.localStorageService.getUserSettings();
    if (settings == null) return;

    final updatedSettings = settings.copyWith(
      cacheListCovers: setting == 'cacheListCovers' ? value : settings.cacheListCovers,
      cacheFavoriteCovers: setting == 'cacheFavoriteCovers' ? value : settings.cacheFavoriteCovers,
      cacheCharacterImages: setting == 'cacheCharacterImages' ? value : settings.cacheCharacterImages,
      cacheStaffImages: setting == 'cacheStaffImages' ? value : settings.cacheStaffImages,
      cacheBannerImages: setting == 'cacheBannerImages' ? value : settings.cacheBannerImages,
      cacheTrendingCovers: setting == 'cacheTrendingCovers' ? value : settings.cacheTrendingCovers,
      cacheSearchResults: setting == 'cacheSearchResults' ? value : settings.cacheSearchResults,
    );

    await widget.localStorageService.saveUserSettings(updatedSettings);
  }

  Future<void> _cacheAllContent() async {
    setState(() => _isLoading = true);

    try {
      int cachedCount = 0;
      final settings = widget.localStorageService.getUserSettings();
      if (settings == null) return;

      // Cache list covers (anime + manga)
      if (settings.cacheListCovers) {
        final animeList = widget.localStorageService.getAnimeList();
        final mangaList = widget.localStorageService.getMangaList();
        
        final allMedia = [
          ...animeList.map((e) => (mediaId: e.mediaId, coverUrl: e.media?.coverImage)),
          ...mangaList.map((e) => (mediaId: e.mediaId, coverUrl: e.media?.coverImage)),
        ];
        
        await _imageCacheService.downloadBatch(allMedia);
        cachedCount += allMedia.length;
      }

      // Cache favorites - TODO: Implement when favorites are available in UserModel

      // TODO: Add character, staff, banner, trending, and search caching
      // These would require additional data sources to be implemented

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cached $cachedCount items for offline access'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }

      await _loadCacheInfo();
    } catch (e) {
      print('Error caching content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error caching content'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        title: const Text('Offline Content Settings'),
        backgroundColor: AppTheme.cardGray,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentBlue, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Offline Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose what content to cache for offline access. '
                  'Only selected content will be downloaded and available without internet.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current cache:',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    Text(
                      '$_imageCount images (${_formatBytes(_cacheSize)})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Essential content section
          _buildSectionHeader('📚 Essential Content', 'Your personal lists'),
          _buildCacheTile(
            icon: Icons.list_alt,
            title: 'List Covers',
            subtitle: 'Anime & Manga list covers',
            value: _cacheListCovers,
            onChanged: (value) {
              setState(() => _cacheListCovers = value);
              _saveSetting('cacheListCovers', value);
            },
            recommended: true,
          ),
          _buildCacheTile(
            icon: Icons.favorite,
            title: 'Favorites',
            subtitle: 'Your favorite anime & manga',
            value: _cacheFavoriteCovers,
            onChanged: (value) {
              setState(() => _cacheFavoriteCovers = value);
              _saveSetting('cacheFavoriteCovers', value);
            },
            recommended: true,
          ),

          const SizedBox(height: 16),

          // Additional content section
          _buildSectionHeader('🎨 Additional Content', 'Optional content (increases storage)'),
          _buildCacheTile(
            icon: Icons.person,
            title: 'Character Images',
            subtitle: 'Character portraits',
            value: _cacheCharacterImages,
            onChanged: (value) {
              setState(() => _cacheCharacterImages = value);
              _saveSetting('cacheCharacterImages', value);
            },
          ),
          _buildCacheTile(
            icon: Icons.badge,
            title: 'Staff Images',
            subtitle: 'Voice actors, directors, etc.',
            value: _cacheStaffImages,
            onChanged: (value) {
              setState(() => _cacheStaffImages = value);
              _saveSetting('cacheStaffImages', value);
            },
          ),
          _buildCacheTile(
            icon: Icons.panorama,
            title: 'Banner Images',
            subtitle: 'Large banner images',
            value: _cacheBannerImages,
            onChanged: (value) {
              setState(() => _cacheBannerImages = value);
              _saveSetting('cacheBannerImages', value);
            },
          ),

          const SizedBox(height: 16),

          // Discovery content section
          _buildSectionHeader('🔥 Discovery Content', 'Trending and search results'),
          _buildCacheTile(
            icon: Icons.trending_up,
            title: 'Trending',
            subtitle: 'Trending anime & manga',
            value: _cacheTrendingCovers,
            onChanged: (value) {
              setState(() => _cacheTrendingCovers = value);
              _saveSetting('cacheTrendingCovers', value);
            },
          ),
          _buildCacheTile(
            icon: Icons.search,
            title: 'Search Results',
            subtitle: 'Recently searched content',
            value: _cacheSearchResults,
            onChanged: (value) {
              setState(() => _cacheSearchResults = value);
              _saveSetting('cacheSearchResults', value);
            },
          ),

          const SizedBox(height: 24),

          // Cache all button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _cacheAllContent,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isLoading ? 'Caching...' : 'Cache Selected Content Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Content is cached automatically when you view it. '
                    'Use "Cache Now" to download everything in advance.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool recommended = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.accentBlue : Colors.grey[800]!,
          width: value ? 2 : 1,
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: value ? AppTheme.accentBlue : Colors.grey[600]),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (recommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentGreen),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentBlue,
      ),
    );
  }
}
