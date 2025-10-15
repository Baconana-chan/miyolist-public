import 'package:flutter/material.dart';
import '../models/cached_image_info.dart';
import '../services/image_gallery_service.dart';
import 'image_viewer_page.dart';
import '../../../core/services/image_cache_service.dart';

/// Offline Image Gallery - Browse all cached images
class ImageGalleryPage extends StatefulWidget {
  const ImageGalleryPage({super.key});

  @override
  State<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends State<ImageGalleryPage> {
  final ImageGalleryService _galleryService = ImageGalleryService();
  final ImageCacheService _cacheService = ImageCacheService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CachedImageInfo> _images = [];
  List<CachedImageInfo> _filteredImages = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // date, size, oldest
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);

    try {
      List<CachedImageInfo> images;
      
      switch (_sortBy) {
        case 'size':
          images = await _galleryService.getImagesSortedBySize();
          break;
        case 'oldest':
          images = await _galleryService.getOldestImages();
          break;
        case 'date':
        default:
          images = await _galleryService.getAllCachedImages();
      }

      setState(() {
        _images = images;
        _filteredImages = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e')),
        );
      }
    }
  }

  Future<void> _loadStatistics() async {
    final stats = await _galleryService.getStatistics();
    setState(() => _stats = stats);
  }

  void _searchImages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredImages = _images;
      } else {
        _filteredImages = _images.where((image) {
          return image.mediaId.toString().contains(query) ||
                 image.filename.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteImage(CachedImageInfo image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: Text('Delete cached image for media #${image.mediaId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _galleryService.deleteImage(image);
        await _loadImages();
        await _loadStatistics();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Image deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting image: $e')),
          );
        }
      }
    }
  }

  void _openImageViewer(CachedImageInfo image, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          images: _filteredImages,
          initialIndex: index,
          onDelete: (deletedImage) async {
            await _galleryService.deleteImage(deletedImage);
            await _loadImages();
            await _loadStatistics();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('📸 Offline Gallery'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadImages();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.access_time, 
                      color: _sortBy == 'date' ? Colors.blue : null),
                    const SizedBox(width: 12),
                    const Text('Newest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.history, 
                      color: _sortBy == 'oldest' ? Colors.blue : null),
                    const SizedBox(width: 12),
                    const Text('Oldest First'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'size',
                child: Row(
                  children: [
                    Icon(Icons.data_usage, 
                      color: _sortBy == 'size' ? Colors.blue : null),
                    const SizedBox(width: 12),
                    const Text('Largest First'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _loadImages();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics card
          if (_stats.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    Icons.image,
                    '${_stats['count']}',
                    'Images',
                  ),
                  _buildStatItem(
                    Icons.storage,
                    _cacheService.formatBytes(_stats['totalSize'] ?? 0),
                    'Total Size',
                  ),
                  _buildStatItem(
                    Icons.analytics,
                    _cacheService.formatBytes(_stats['averageSize'] ?? 0),
                    'Avg Size',
                  ),
                ],
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _searchImages,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by Media ID or filename...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchImages('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Image grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _filteredImages.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _filteredImages.length,
                        itemBuilder: (context, index) {
                          final image = _filteredImages[index];
                          return _buildImageCard(image, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(CachedImageInfo image, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(image, index),
      onLongPress: () => _deleteImage(image),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.file(
                  image.file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${image.mediaId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        image.formattedSize,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        image.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isNotEmpty
                ? Icons.search_off
                : Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No images found'
                : 'No cached images yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search'
                : 'Images are cached when you view them in your list',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
