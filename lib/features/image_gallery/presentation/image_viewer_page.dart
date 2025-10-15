import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cached_image_info.dart';

/// Full-screen image viewer with swipe navigation
class ImageViewerPage extends StatefulWidget {
  final List<CachedImageInfo> images;
  final int initialIndex;
  final Function(CachedImageInfo)? onDelete;

  const ImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
    this.onDelete,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
  }

  Future<void> _deleteCurrentImage() async {
    final currentImage = widget.images[_currentIndex];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Image?', 
          style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete cached image for media #${currentImage.mediaId}?\n\n'
          'This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
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

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!(currentImage);
      
      // Navigate away if this was the last image
      if (widget.images.length <= 1) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Move to next image or previous if at end
        final newIndex = _currentIndex >= widget.images.length - 1
            ? _currentIndex - 1
            : _currentIndex;
        
        if (mounted) {
          setState(() {
            _currentIndex = newIndex;
          });
          _pageController.jumpToPage(newIndex);
        }
      }
    }
  }

  void _showImageInfo() {
    final image = widget.images[_currentIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Image Info', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Media ID', image.mediaId.toString()),
            _buildInfoRow('Filename', image.filename),
            _buildInfoRow('Size', image.formattedSize),
            _buildInfoRow('Cached', image.formattedDate),
            _buildInfoRow('Last Modified', 
              '${image.lastModified.day}/${image.lastModified.month}/${image.lastModified.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          children: [
            // Image PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final image = widget.images[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      image.file,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 80,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // Top UI Bar
            if (_showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Media #${widget.images[_currentIndex].mediaId}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.white),
                          onPressed: _showImageInfo,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: _deleteCurrentImage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom UI Bar
            if (_showUI)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Image counter
                          Text(
                            '${_currentIndex + 1} / ${widget.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Progress indicator
                          if (widget.images.length > 1)
                            LinearProgressIndicator(
                              value: (_currentIndex + 1) / widget.images.length,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
