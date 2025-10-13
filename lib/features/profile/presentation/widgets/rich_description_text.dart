import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/media_preview.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'inline_media_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that parses markdown with AniList links and displays inline media cards
class RichDescriptionText extends StatefulWidget {
  final String markdown;

  const RichDescriptionText({
    super.key,
    required this.markdown,
  });

  @override
  State<RichDescriptionText> createState() => _RichDescriptionTextState();
}

class _RichDescriptionTextState extends State<RichDescriptionText> {
  final LocalStorageService _storageService = LocalStorageService();
  late final AniListService _anilistService;
  
  Map<int, MediaPreview> _mediaCache = {};
  Set<int> _loadingIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _anilistService = AniListService(AuthService());
    _parseAndLoadMedia();
  }

  @override
  void didUpdateWidget(RichDescriptionText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _parseAndLoadMedia();
    }
  }

  Future<void> _parseAndLoadMedia() async {
    // Extract all AniList media links
    final anilistRegex = RegExp(r'anilist\.co/(anime|manga)/(\d+)');
    final matches = anilistRegex.allMatches(widget.markdown);
    
    final mediaIds = matches.map((m) => int.parse(m.group(2)!)).toSet();
    
    // Load media data from cache or API
    for (final id in mediaIds) {
      if (!_mediaCache.containsKey(id) && !_loadingIds.contains(id)) {
        _loadingIds.add(id);
        _loadMediaData(id);
      }
    }
    
    if (!_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadMediaData(int mediaId) async {
    try {
      // Try local cache first
      MediaPreview? media;
      
      // Check in anime list
      final animeList = await _storageService.getAnimeList();
      for (var entry in animeList) {
        if (entry.media?.id == mediaId) {
          media = MediaPreview.fromMediaListEntry(entry);
          break;
        }
      }
      
      // Check in manga list if not found
      if (media == null) {
        final mangaList = await _storageService.getMangaList();
        for (var entry in mangaList) {
          if (entry.media?.id == mediaId) {
            media = MediaPreview.fromMediaListEntry(entry);
            break;
          }
        }
      }
      
      // If not in cache, fetch from API
      if (media == null) {
        final mediaData = await _anilistService.getMediaById(mediaId);
        if (mediaData != null) {
          media = MediaPreview.fromJson(mediaData);
        }
      }
      
      if (media != null) {
        setState(() {
          _mediaCache[mediaId] = media!;
          _loadingIds.remove(mediaId);
        });
      } else {
        setState(() {
          _loadingIds.remove(mediaId);
        });
      }
    } catch (e) {
      print('Error loading media $mediaId: $e');
      setState(() {
        _loadingIds.remove(mediaId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildRichText();
  }

  Widget _buildRichText() {
    // Split markdown by AniList links
    final anilistRegex = RegExp(
      r'\[([^\]]+)\]\(https?://anilist\.co/(anime|manga)/(\d+)[^\)]*\)',
    );
    
    final List<Widget> children = [];
    int lastIndex = 0;
    
    for (final match in anilistRegex.allMatches(widget.markdown)) {
      // Add text before the link
      if (match.start > lastIndex) {
        final textBefore = widget.markdown.substring(lastIndex, match.start);
        children.add(_buildMarkdownText(textBefore));
      }
      
      // Add media card or loading placeholder
      final mediaId = int.parse(match.group(3)!);
      final linkText = match.group(1)!;
      
      if (_mediaCache.containsKey(mediaId)) {
        children.add(InlineMediaCard(media: _mediaCache[mediaId]!));
      } else if (_loadingIds.contains(mediaId)) {
        children.add(_buildLoadingCard(linkText));
      } else {
        // Fallback to regular link
        children.add(_buildMarkdownText(match.group(0)!));
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < widget.markdown.length) {
      final textAfter = widget.markdown.substring(lastIndex);
      children.add(_buildMarkdownText(textAfter));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildMarkdownText(String markdown) {
    if (markdown.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    
    return MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet(
        p: Theme.of(context).textTheme.bodyMedium,
        a: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.accentBlue,
          decoration: TextDecoration.underline,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          _handleExternalUrl(href);
        }
      },
    );
  }

  Widget _buildLoadingCard(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.colors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.colors.divider,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.colors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.colors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: AppTheme.colors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
