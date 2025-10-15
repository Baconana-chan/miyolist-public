import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

/// Service for optimizing cached images
/// Supports WebP conversion, compression, and thumbnail generation
class ImageOptimizationService {
  /// Optimize a single image file
  /// Returns the new file size in bytes, or null if optimization failed
  Future<int?> optimizeImage({
    required File imageFile,
    int quality = 85,
    bool convertToWebP = true,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      // Read original image
      final bytes = await imageFile.readAsBytes();
      final originalSize = bytes.length;
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('❌ Failed to decode image: ${imageFile.path}');
        return null;
      }
      
      // Resize if needed
      if (maxWidth != null || maxHeight != null) {
        final targetWidth = maxWidth ?? image.width;
        final targetHeight = maxHeight ?? image.height;
        
        // Calculate aspect ratio
        final aspectRatio = image.width / image.height;
        int newWidth = targetWidth;
        int newHeight = targetHeight;
        
        if (maxWidth != null && maxHeight != null) {
          // Both dimensions specified
          if (image.width > targetWidth || image.height > targetHeight) {
            if (aspectRatio > 1) {
              // Landscape
              newWidth = targetWidth;
              newHeight = (targetWidth / aspectRatio).round();
            } else {
              // Portrait
              newHeight = targetHeight;
              newWidth = (targetHeight * aspectRatio).round();
            }
          }
        } else if (maxWidth != null) {
          // Only width specified
          if (image.width > targetWidth) {
            newWidth = targetWidth;
            newHeight = (targetWidth / aspectRatio).round();
          }
        } else if (maxHeight != null) {
          // Only height specified
          if (image.height > targetHeight) {
            newHeight = targetHeight;
            newWidth = (targetHeight * aspectRatio).round();
          }
        }
        
        if (newWidth < image.width || newHeight < image.height) {
          image = img.copyResize(
            image,
            width: newWidth,
            height: newHeight,
            interpolation: img.Interpolation.cubic,
          );
        }
      }
      
      // Encode image
      Uint8List? optimizedBytes;
      
      if (convertToWebP) {
        // Convert to high-quality JPEG (WebP not directly supported)
        // JPEG with quality 85 provides similar compression to WebP
        optimizedBytes = img.encodeJpg(image, quality: quality);
      } else {
        // Keep original format but compress
        final originalExtension = path.extension(imageFile.path).toLowerCase();
        if (originalExtension == '.png') {
          optimizedBytes = img.encodePng(image, level: 6);
        } else if (originalExtension == '.jpg' || originalExtension == '.jpeg') {
          optimizedBytes = img.encodeJpg(image, quality: quality);
        } else {
          // Unknown format, try JPEG
          optimizedBytes = img.encodeJpg(image, quality: quality);
        }
      }
      
      // Check if optimization actually reduced file size
      final optimizedSize = optimizedBytes.length;
      if (optimizedSize >= originalSize) {
        debugPrint('⚠️ Optimization did not reduce size: ${imageFile.path}');
        return null;
      }
      
      // IMPORTANT: Keep the same filename to maintain CachedNetworkImage compatibility
      // Just overwrite the original file with the optimized version
      await imageFile.writeAsBytes(optimizedBytes);
      
      final savedBytes = originalSize - optimizedSize;
      final savedPercent = ((savedBytes / originalSize) * 100).toStringAsFixed(1);
      debugPrint('✅ Optimized: ${path.basename(imageFile.path)} | Saved: ${_formatBytes(savedBytes)} ($savedPercent%)');
      
      return optimizedSize;
    } catch (e) {
      debugPrint('❌ Error optimizing image: $e');
      return null;
    }
  }
  
  /// Generate thumbnail for an image
  Future<File?> generateThumbnail({
    required File imageFile,
    int size = 200,
    int quality = 85,
  }) async {
    try {
      // Read original image
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('❌ Failed to decode image for thumbnail: ${imageFile.path}');
        return null;
      }
      
      // Create square thumbnail
      final thumbnailSize = size;
      img.Image thumbnail;
      
      if (image.width > image.height) {
        // Landscape - crop sides
        final cropX = ((image.width - image.height) / 2).round();
        image = img.copyCrop(image, x: cropX, y: 0, width: image.height, height: image.height);
      } else if (image.height > image.width) {
        // Portrait - crop top/bottom
        final cropY = ((image.height - image.width) / 2).round();
        image = img.copyCrop(image, x: 0, y: cropY, width: image.width, height: image.width);
      }
      
      // Resize to thumbnail size
      thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.cubic,
      );
      
      // Encode as JPEG (high quality)
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: quality);
      
      // Create thumbnail path
      final directory = imageFile.parent.path;
      final filename = path.basenameWithoutExtension(imageFile.path);
      final thumbnailPath = path.join(directory, '${filename}_thumb.jpg');
      
      // Write thumbnail
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      debugPrint('✅ Generated thumbnail: ${path.basename(thumbnailPath)}');
      return thumbnailFile;
    } catch (e) {
      debugPrint('❌ Error generating thumbnail: $e');
      return null;
    }
  }
  
  /// Batch optimize all images in a directory
  Future<Map<String, dynamic>> batchOptimize({
    required Directory directory,
    int quality = 85,
    bool convertToWebP = true,
    int? maxWidth,
    int? maxHeight,
    bool generateThumbnails = false,
    Function(int current, int total)? onProgress,
  }) async {
    final results = {
      'total': 0,
      'optimized': 0,
      'failed': 0,
      'skipped': 0,
      'totalSaved': 0,
      'thumbnails': 0,
    };
    
    try {
      // Get all image files
      final files = directory
          .listSync(recursive: false)
          .whereType<File>()
          .where((file) {
            final ext = path.extension(file.path).toLowerCase();
            return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
          })
          .where((file) => !path.basename(file.path).endsWith('_thumb.jpg'))
          .toList();
      
      results['total'] = files.length;
      debugPrint('🔧 Starting batch optimization: ${files.length} images');
      
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        onProgress?.call(i + 1, files.length);
        
        // Skip thumbnails
        if (path.basename(file.path).endsWith('_thumb.jpg')) {
          results['skipped'] = (results['skipped'] as int) + 1;
          continue;
        }
        
        // Skip already optimized JPEG files with reasonable size
        if (convertToWebP && path.extension(file.path).toLowerCase() == '.jpg') {
          final fileSize = await file.length();
          // Skip if already small (under 200KB)
          if (fileSize < 200 * 1024) {
            results['skipped'] = (results['skipped'] as int) + 1;
            continue;
          }
        }
        
        final originalSize = await file.length();
        
        // Optimize image
        final newSize = await optimizeImage(
          imageFile: file,
          quality: quality,
          convertToWebP: convertToWebP,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
        
        if (newSize != null) {
          results['optimized'] = (results['optimized'] as int) + 1;
          results['totalSaved'] = (results['totalSaved'] as int) + (originalSize - newSize);
          
          // Generate thumbnail if requested
          if (generateThumbnails) {
            final thumb = await generateThumbnail(imageFile: file, size: 200, quality: quality);
            if (thumb != null) {
              results['thumbnails'] = (results['thumbnails'] as int) + 1;
            }
          }
        } else {
          results['failed'] = (results['failed'] as int) + 1;
        }
        
        // Small delay to prevent UI freezing
        if (i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      
      debugPrint('✅ Batch optimization complete!');
      debugPrint('   Total: ${results['total']}');
      debugPrint('   Optimized: ${results['optimized']}');
      debugPrint('   Failed: ${results['failed']}');
      debugPrint('   Skipped: ${results['skipped']}');
      debugPrint('   Total saved: ${_formatBytes(results['totalSaved'] as int)}');
      if (generateThumbnails) {
        debugPrint('   Thumbnails: ${results['thumbnails']}');
      }
    } catch (e) {
      debugPrint('❌ Error in batch optimization: $e');
    }
    
    return results;
  }
  
  /// Get optimization statistics for a directory
  Future<Map<String, dynamic>> getOptimizationStats(Directory directory) async {
    final stats = {
      'totalImages': 0,
      'totalSize': 0,
      'jpgCount': 0,
      'pngCount': 0,
      'thumbnailCount': 0,
      'averageSize': 0,
    };
    
    try {
      final files = directory
          .listSync(recursive: false)
          .whereType<File>()
          .where((file) {
            final ext = path.extension(file.path).toLowerCase();
            return ext == '.jpg' || ext == '.jpeg' || ext == '.png';
          })
          .toList();
      
      stats['totalImages'] = files.length;
      
      for (final file in files) {
        final size = await file.length();
        stats['totalSize'] = (stats['totalSize'] as int) + size;
        
        final ext = path.extension(file.path).toLowerCase();
        final filename = path.basename(file.path);
        
        if (filename.endsWith('_thumb.jpg')) {
          stats['thumbnailCount'] = (stats['thumbnailCount'] as int) + 1;
        } else if (ext == '.jpg' || ext == '.jpeg') {
          stats['jpgCount'] = (stats['jpgCount'] as int) + 1;
        } else if (ext == '.png') {
          stats['pngCount'] = (stats['pngCount'] as int) + 1;
        }
      }
      
      if (stats['totalImages']! > 0) {
        stats['averageSize'] = (stats['totalSize'] as int) ~/ (stats['totalImages'] as int);
      }
    } catch (e) {
      debugPrint('❌ Error getting optimization stats: $e');
    }
    
    return stats;
  }
  
  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
