import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/character_details.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class CharacterDetailsPage extends StatefulWidget {
  final int characterId;
  final AniListService anilistService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const CharacterDetailsPage({
    super.key,
    required this.characterId,
    required this.anilistService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<CharacterDetailsPage> createState() => _CharacterDetailsPageState();
}

class _CharacterDetailsPageState extends State<CharacterDetailsPage> {
  CharacterDetails? _character;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharacterDetails();
  }

  Future<void> _loadCharacterDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Попробуем получить из кеша Hive
      CharacterDetails? character = widget.localStorageService.getCharacterDetails(widget.characterId);

      // Если кеш просрочен или не найден, загружаем из AniList
      if (character == null || character.isCacheExpired()) {
        print('📡 Loading character from AniList...');
        character = await widget.anilistService.getCharacterDetails(widget.characterId);

        if (character != null) {
          // Сохраняем в кеш
          await widget.localStorageService.saveCharacterDetails(character);
          print('✅ Character cached in Hive');
        }
      } else {
        print('✅ Character loaded from Hive cache');
      }

      if (mounted) {
        setState(() {
          _character = character;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading character: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToMedia(int mediaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailsPage(
          mediaId: mediaId,
          anilistService: widget.anilistService,
          localStorageService: widget.localStorageService,
          supabaseService: widget.supabaseService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_character?.name ?? 'Character'),
        actions: [
          if (_character != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCharacterDetails,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCharacterDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _character == null
                  ? const Center(child: Text('Character not found'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and basic info
          _buildHeader(),

          // Description
          if (_character!.description != null && _character!.description!.isNotEmpty)
            _buildSection(
              title: 'About',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: _character!.description!,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: AppTheme.textWhite),
                    a: const TextStyle(color: AppTheme.accentRed),
                  ),
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrl(Uri.parse(href));
                    }
                  },
                ),
              ),
            ),

          // Character Info
          _buildCharacterInfo(),

          // Appears In (Media)
          if (_character!.media != null && _character!.media!.isNotEmpty)
            _buildMediaSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.secondaryBlack,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character Image
          Hero(
            tag: 'character_${_character!.id}',
            child: Container(
              width: 120,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentRed, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _character!.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _character!.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.secondaryBlack,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.secondaryBlack,
                        child: const Icon(Icons.person, size: 60),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Character Name and Basic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _character!.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),

                // Alternative Names
                if (_character!.alternativeNames != null &&
                    _character!.alternativeNames!.isNotEmpty)
                  ...[ 
                    const SizedBox(height: 8),
                    Text(
                      _character!.alternativeNames!.join(', '),
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ],

                const SizedBox(height: 16),

                // Favourites
                if (_character!.favourites != null)
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppTheme.accentRed, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${_character!.favourites} favorites',
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterInfo() {
    final hasInfo = _character!.gender != null ||
        _character!.age != null ||
        _character!.dateOfBirth != null;

    if (!hasInfo) return const SizedBox.shrink();

    return _buildSection(
      title: 'Character Information',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_character!.gender != null)
              _buildInfoRow('Gender', _character!.gender!),
            if (_character!.age != null)
              _buildInfoRow('Age', _character!.age!),
            if (_character!.dateOfBirth != null)
              _buildInfoRow('Date of Birth', _character!.dateOfBirth!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    final mediaList = _character!.media!;
    final displayCount = mediaList.length > 10 ? 10 : mediaList.length;
    final hasMore = mediaList.length > 10;

    return _buildSection(
      title: 'Appears In (${mediaList.length})',
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: displayCount,
              itemBuilder: (context, index) {
                final media = mediaList[index];
                return _buildMediaCard(media);
              },
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: TextButton.icon(
                onPressed: () => _showAllMedia(),
                icon: const Icon(Icons.grid_view, size: 18),
                label: Text('See All ${mediaList.length} Media'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllMedia() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.secondaryBlack,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Media (${_character!.media!.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    childAspectRatio: 0.57,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _character!.media!.length,
                  itemBuilder: (context, index) {
                    final media = _character!.media![index];
                    return _buildMediaCard(media);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard(CharacterMedia media) {
    return GestureDetector(
      onTap: () => _navigateToMedia(media.id),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover Image
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: media.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: media.coverImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: AppTheme.secondaryBlack,
                        child: const Icon(Icons.image, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Title
            Flexible(
              child: Text(
                media.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Role
            if (media.characterRole != null)
              Flexible(
                child: Text(
                  media.characterRole!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: media.characterRole == 'MAIN'
                        ? AppTheme.accentRed
                        : AppTheme.textGray,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        child,
      ],
    );
  }
}
