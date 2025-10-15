import 'dart:io';

/// Information about a cached image
class CachedImageInfo {
  final File file;
  final String filename;
  final int mediaId;
  final int size; // bytes
  final DateTime lastModified;
  
  CachedImageInfo({
    required this.file,
    required this.filename,
    required this.mediaId,
    required this.size,
    required this.lastModified,
  });

  /// Parse media ID from filename (format: {mediaId}_{hash}.{ext})
  static int? parseMediaId(String filename) {
    try {
      final parts = filename.split('_');
      if (parts.isNotEmpty) {
        return int.tryParse(parts.first);
      }
    } catch (_) {}
    return null;
  }

  /// Format file size to human readable string
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format last modified date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(lastModified);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  /// Create from File
  static Future<CachedImageInfo> fromFile(File file) async {
    final filename = file.path.split(Platform.pathSeparator).last;
    final size = await file.length();
    final lastModified = await file.lastModified();
    final mediaId = parseMediaId(filename) ?? 0;

    return CachedImageInfo(
      file: file,
      filename: filename,
      mediaId: mediaId,
      size: size,
      lastModified: lastModified,
    );
  }
}
