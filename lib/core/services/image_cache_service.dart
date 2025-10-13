import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for managing offline image caching for user's list entries
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  Directory? _cacheDirectory;
  bool _initialized = false;

  /// Initialize the service and create cache directory
  Future<void> initialize() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/image_cache');
    
    if (!await _cacheDirectory!.exists()) {
      await _cacheDirectory!.create(recursive: true);
    }
    
    _initialized = true;
  }

  /// Generate a safe filename from URL
  String _generateFilename(String url, int mediaId) {
    // Use mediaId and URL hash to create unique filename
    final urlHash = md5.convert(utf8.encode(url)).toString().substring(0, 8);
    final extension = url.split('.').last.split('?').first;
    return '${mediaId}_$urlHash.$extension';
  }

  /// Check if image exists locally
  Future<File?> getLocalImage(String url, int mediaId) async {
    if (!_initialized) await initialize();

    final filename = _generateFilename(url, mediaId);
    final file = File('${_cacheDirectory!.path}/$filename');

    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Download and cache image
  Future<File?> downloadImage(String url, int mediaId) async {
    if (!_initialized) await initialize();

    try {
      final filename = _generateFilename(url, mediaId);
      final file = File('${_cacheDirectory!.path}/$filename');

      // Skip if already exists
      if (await file.exists()) {
        return file;
      }

      // Download image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
    return null;
  }

  /// Delete cached image for a specific media
  Future<void> deleteImage(int mediaId) async {
    if (!_initialized) await initialize();

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          final filename = file.path.split(Platform.pathSeparator).last;
          if (filename.startsWith('${mediaId}_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    if (!_initialized) await initialize();

    int totalSize = 0;
    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      print('Error calculating cache size: $e');
    }
    return totalSize;
  }

  /// Format bytes to human readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clear all cached images
  Future<void> clearCache() async {
    if (!_initialized) await initialize();

    try {
      if (await _cacheDirectory!.exists()) {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear cached images older than specified days
  Future<int> clearOldCache({int days = 30}) async {
    if (!_initialized) await initialize();

    int deletedCount = 0;
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final files = await _cacheDirectory!.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final lastModified = await file.lastModified();
          if (lastModified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      print('🗑️ Deleted $deletedCount images older than $days days');
    } catch (e) {
      print('Error clearing old cache: $e');
    }
    return deletedCount;
  }

  /// Clean up images that are not in the provided media ID list
  Future<void> cleanupUnusedImages(List<int> activeMediaIds) async {
    if (!_initialized) await initialize();

    try {
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file is File) {
          final filename = file.path.split(Platform.pathSeparator).last;
          final mediaIdStr = filename.split('_').first;
          final mediaId = int.tryParse(mediaIdStr);
          
          if (mediaId != null && !activeMediaIds.contains(mediaId)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up unused images: $e');
    }
  }

  /// Get count of cached images
  Future<int> getCachedImageCount() async {
    if (!_initialized) await initialize();

    try {
      final files = await _cacheDirectory!.list().toList();
      return files.whereType<File>().length;
    } catch (e) {
      print('Error getting cached image count: $e');
      return 0;
    }
  }

  /// Download images for a list of media in background
  Future<void> downloadBatch(List<({int mediaId, String? coverUrl})> mediaList) async {
    if (!_initialized) await initialize();

    // Filter out media that already have cached images
    final toDownload = <({int mediaId, String coverUrl})>[];
    for (final media in mediaList) {
      if (media.coverUrl != null && media.coverUrl!.isNotEmpty) {
        final filename = _generateFilename(media.coverUrl!, media.mediaId);
        final file = File('${_cacheDirectory!.path}/$filename');
        
        // Only add to download list if file doesn't exist
        if (!await file.exists()) {
          toDownload.add((mediaId: media.mediaId, coverUrl: media.coverUrl!));
        }
      }
    }

    if (toDownload.isEmpty) {
      print('✅ All ${mediaList.length} cover images already cached');
      return;
    }

    print('📥 Downloading ${toDownload.length} new cover images (${mediaList.length - toDownload.length} already cached)');

    for (final media in toDownload) {
      await downloadImage(media.coverUrl, media.mediaId);
      // Small delay to avoid overwhelming the network
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('✅ Downloaded ${toDownload.length} new cover images');
  }
}
