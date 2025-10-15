import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/cached_image_info.dart';
import '../../../core/services/image_cache_service.dart';

/// Service for managing the image gallery
class ImageGalleryService {
  final ImageCacheService _imageCacheService = ImageCacheService();

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/image_cache');
  }

  /// Get all cached images with metadata
  Future<List<CachedImageInfo>> getAllCachedImages() async {
    await _imageCacheService.initialize();
    
    final cacheDir = await _getCacheDirectory();
    
    if (!await cacheDir.exists()) {
      return [];
    }

    final files = await cacheDir.list().toList();
    final imageFiles = files.whereType<File>().toList();

    final List<CachedImageInfo> images = [];
    for (final file in imageFiles) {
      try {
        final info = await CachedImageInfo.fromFile(file);
        images.add(info);
      } catch (e) {
        print('Error loading image info: $e');
      }
    }

    // Sort by last modified (newest first)
    images.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    return images;
  }

  /// Search cached images by media ID
  Future<List<CachedImageInfo>> searchByMediaId(String query) async {
    final allImages = await getAllCachedImages();
    
    if (query.isEmpty) return allImages;

    final searchQuery = query.toLowerCase();
    return allImages.where((image) {
      return image.mediaId.toString().contains(searchQuery) ||
             image.filename.toLowerCase().contains(searchQuery);
    }).toList();
  }

  /// Get images sorted by size (largest first)
  Future<List<CachedImageInfo>> getImagesSortedBySize() async {
    final images = await getAllCachedImages();
    images.sort((a, b) => b.size.compareTo(a.size));
    return images;
  }

  /// Get images sorted by date (oldest first)
  Future<List<CachedImageInfo>> getOldestImages() async {
    final images = await getAllCachedImages();
    images.sort((a, b) => a.lastModified.compareTo(b.lastModified));
    return images;
  }

  /// Delete specific image
  Future<void> deleteImage(CachedImageInfo image) async {
    try {
      if (await image.file.exists()) {
        await image.file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  /// Get total statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final images = await getAllCachedImages();
    
    int totalSize = 0;
    for (final image in images) {
      totalSize += image.size;
    }

    return {
      'count': images.length,
      'totalSize': totalSize,
      'averageSize': images.isNotEmpty ? totalSize ~/ images.length : 0,
      'oldestDate': images.isNotEmpty 
          ? images.map((e) => e.lastModified).reduce(
              (a, b) => a.isBefore(b) ? a : b
            )
          : null,
      'newestDate': images.isNotEmpty
          ? images.map((e) => e.lastModified).reduce(
              (a, b) => a.isAfter(b) ? a : b
            )
          : null,
    };
  }
}
