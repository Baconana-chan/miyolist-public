import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_cache_service.dart';

/// Widget that displays cover image with offline caching support
/// Uses local cache for user's list entries, falls back to network
class CachedCoverImage extends StatefulWidget {
  final String? imageUrl;
  final int mediaId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool enableOfflineCache;

  const CachedCoverImage({
    super.key,
    required this.imageUrl,
    required this.mediaId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.enableOfflineCache = true,
  });

  @override
  State<CachedCoverImage> createState() => _CachedCoverImageState();
}

class _CachedCoverImageState extends State<CachedCoverImage> {
  File? _localImage;

  @override
  void initState() {
    super.initState();
    if (widget.enableOfflineCache && widget.imageUrl != null) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null) return;

    try {
      final imageCache = ImageCacheService();
      
      // Check for local image first
      final localFile = await imageCache.getLocalImage(widget.imageUrl!, widget.mediaId);
      
      if (localFile != null) {
        if (mounted) {
          setState(() {
            _localImage = localFile;
          });
        }
      } else {
        // Start background download
        _downloadInBackground();
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> _downloadInBackground() async {
    if (widget.imageUrl == null) return;

    try {
      final imageCache = ImageCacheService();
      final downloadedFile = await imageCache.downloadImage(widget.imageUrl!, widget.mediaId);
      
      if (downloadedFile != null && mounted) {
        setState(() {
          _localImage = downloadedFile;
        });
      }
    } catch (e) {
      print('Error downloading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If offline cache is disabled or no URL, use regular network image
    if (!widget.enableOfflineCache || widget.imageUrl == null) {
      return _buildNetworkImage();
    }

    // If we have a local image, use it
    if (_localImage != null) {
      return Image.file(
        _localImage!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          // If local file fails, fall back to network
          return _buildNetworkImage();
        },
      );
    }

    // Fall back to network image while downloading
    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    if (widget.imageUrl == null) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      placeholder: (context, url) => _buildLoadingIndicator(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[900],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.movie, size: 48, color: Colors.grey),
      ),
    );
  }
}
