import 'package:flutter/material.dart';
import '../../../../core/services/image_cache_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/app_theme.dart';

class ImageCacheSettingsDialog extends StatefulWidget {
  final LocalStorageService localStorageService;
  
  const ImageCacheSettingsDialog({
    super.key,
    required this.localStorageService,
  });

  @override
  State<ImageCacheSettingsDialog> createState() => _ImageCacheSettingsDialogState();
}

class _ImageCacheSettingsDialogState extends State<ImageCacheSettingsDialog> {
  final _imageCacheService = ImageCacheService();
  int _cacheSize = 0;
  int _imageCount = 0;
  bool _isLoading = true;
  int _cacheLimitMB = 500;

  @override
  void initState() {
    super.initState();
    final settings = widget.localStorageService.getUserSettings();
    _cacheLimitMB = settings?.imageCacheSizeLimitMB ?? 500;
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final size = await _imageCacheService.getCacheSize();
      final count = await _imageCacheService.getCachedImageCount();
      
      if (mounted) {
        setState(() {
          _cacheSize = size;
          _imageCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCacheLimit(int limitMB) async {
    final settings = widget.localStorageService.getUserSettings();
    if (settings != null) {
      final updated = settings.copyWith(
        imageCacheSizeLimitMB: limitMB,
        updatedAt: DateTime.now(),
      );
      await widget.localStorageService.saveUserSettings(updated);
      
      setState(() {
        _cacheLimitMB = limitMB;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Cache limit set to $limitMB MB'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Image Cache'),
        content: const Text(
          'This will delete all downloaded cover images. '
          'They will be re-downloaded when you view your list again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _imageCacheService.clearCache();
        await _loadCacheInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Cache cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearOldCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Cache'),
        content: const Text(
          'This will delete cached images older than 30 days. '
          'Newer images will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deletedCount = await _imageCacheService.clearOldCache(days: 30);
        await _loadCacheInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Deleted $deletedCount old image${deletedCount != 1 ? 's' : ''}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing old cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, color: AppTheme.accentBlue),
                const SizedBox(width: 12),
                const Text(
                  'Image Cache',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildInfoCard(
                'Cover images for your list are automatically downloaded '
                'and stored locally for faster loading and offline access.',
              ),
              const SizedBox(height: 16),
              
              _buildStatRow(
                Icons.photo_library,
                'Cached Images',
                '$_imageCount image${_imageCount != 1 ? 's' : ''}',
              ),
              const SizedBox(height: 12),
              
              _buildStatRow(
                Icons.sd_storage,
                'Storage Used',
                _imageCacheService.formatBytes(_cacheSize),
              ),
              const SizedBox(height: 12),
              
              _buildCacheLimitSetting(),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _imageCount > 0 ? _clearOldCache : null,
                  icon: const Icon(Icons.schedule_outlined),
                  label: const Text('Clear Old Cache (30+ days)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _imageCount > 0 ? _clearCache : null,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheLimitSetting() {
    final limitOptions = [100, 250, 500, 1000, 2000, 5000]; // MB options
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: AppTheme.accentBlue),
              const SizedBox(width: 12),
              Text(
                'Cache Size Limit',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: limitOptions.map((limitMB) {
              final isSelected = _cacheLimitMB == limitMB;
              return ChoiceChip(
                label: Text('$limitMB MB'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _saveCacheLimit(limitMB);
                  }
                },
                selectedColor: AppTheme.accentBlue,
                backgroundColor: AppTheme.cardGray,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textGray,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: $_cacheLimitMB MB',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

