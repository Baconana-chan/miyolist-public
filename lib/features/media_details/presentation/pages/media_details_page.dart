import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/media_details.dart';
import '../../../../core/models/media_list_entry.dart';
import '../../../../core/services/media_search_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../anime_list/presentation/widgets/edit_entry_dialog.dart';
import '../../../character/presentation/pages/character_details_page.dart';
import '../../../staff/presentation/pages/staff_details_page.dart';
import '../../../studio/presentation/pages/studio_details_page.dart';

class MediaDetailsPage extends StatefulWidget {
  final int mediaId;
  final AniListService? anilistService;
  final LocalStorageService? localStorageService;
  final SupabaseService? supabaseService;

  const MediaDetailsPage({
    super.key,
    required this.mediaId,
    this.anilistService,
    this.localStorageService,
    this.supabaseService,
  });

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  late final MediaSearchService _searchService;
  late final LocalStorageService _localStorage;
  late final AniListService _anilist;
  late final SupabaseService _supabase;
  MediaDetails? _media;
  MediaListEntry? _listEntry; // Track if media is in user's list
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadMediaDetails();
  }

  void _initializeServices() {
    _localStorage = widget.localStorageService ?? LocalStorageService();
    _supabase = widget.supabaseService ?? SupabaseService();
    final authService = AuthService();
    _anilist = widget.anilistService ?? AniListService(authService);

    _searchService = MediaSearchService(
      localStorage: _localStorage,
      supabase: _supabase,
      anilist: _anilist,
    );
  }

  Future<void> _loadMediaDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final media = await _searchService.getMediaDetails(widget.mediaId);
      
      // Check if media is in user's list
      MediaListEntry? entry;
      if (media != null) {
        if (media.type == 'ANIME') {
          final animeList = _localStorage.getAnimeList();
          entry = animeList.firstWhere(
            (e) => e.mediaId == widget.mediaId,
            orElse: () => MediaListEntry(
              id: 0,
              mediaId: widget.mediaId,
              status: 'PLANNING',
              progress: 0,
            ),
          );
          if (entry.id == 0) entry = null;
        } else {
          final mangaList = _localStorage.getMangaList();
          entry = mangaList.firstWhere(
            (e) => e.mediaId == widget.mediaId,
            orElse: () => MediaListEntry(
              id: 0,
              mediaId: widget.mediaId,
              status: 'PLANNING',
              progress: 0,
            ),
          );
          if (entry.id == 0) entry = null;
        }
      }
      
      setState(() {
        _media = media;
        _listEntry = entry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load media details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentRed))
          : _error != null
              ? _buildError()
              : _media == null
                  ? _buildNotFound()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.textGray),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppTheme.textGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMediaDetails,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Text(
        'Media not found',
        style: TextStyle(color: AppTheme.textGray),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // App Bar with Banner
        _buildAppBar(),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover + Basic Info
              _buildHeader(),

              const SizedBox(height: 24),

              // Description
              if (_media!.description != null) _buildDescription(),

              // Statistics
              _buildStatistics(),

              // Dates & Season Info
              _buildDatesAndSeason(),

              // Source & Studios
              _buildSourceAndStudios(),

              // Genres
              if (_media!.genres != null && _media!.genres!.isNotEmpty)
                _buildGenres(),

              // Synonyms
              if (_media!.synonyms != null && _media!.synonyms!.isNotEmpty)
                _buildSynonyms(),

              // Trailer
              if (_media!.trailer != null) _buildTrailer(),

              // Tags
              if (_media!.tags != null && _media!.tags!.isNotEmpty)
                _buildTags(),

              // External & Streaming Links
              if (_media!.externalLinks != null && _media!.externalLinks!.isNotEmpty)
                _buildExternalLinks(),

              // Characters
              if (_media!.characters != null && _media!.characters!.isNotEmpty)
                _buildCharacters(),

              // Staff
              if (_media!.staff != null && _media!.staff!.isNotEmpty)
                _buildStaff(),

              // Relations
              if (_media!.relations != null && _media!.relations!.isNotEmpty)
                _buildRelations(),

              // Recommendations
              if (_media!.recommendations != null && _media!.recommendations!.isNotEmpty)
                _buildRecommendations(),

              // Status Distribution
              if (_media!.statusDistribution != null && _media!.statusDistribution!.isNotEmpty)
                _buildStatusDistribution(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.secondaryBlack,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_media!.bannerImage != null)
              Image.network(
                _media!.bannerImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: AppTheme.secondaryBlack);
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.secondaryBlack,
                      AppTheme.primaryBlack,
                    ],
                  ),
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.primaryBlack.withOpacity(0.7),
                    AppTheme.primaryBlack,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _media!.coverImage != null
                ? Image.network(
                    _media!.coverImage!,
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildCoverPlaceholder();
                    },
                  )
                : _buildCoverPlaceholder(),
          ),

          const SizedBox(width: 16),

          // Title and Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _media!.displayTitle,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Format & Status
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      _media!.formatText,
                      _media!.isAnime ? AppTheme.accentRed : Colors.blue,
                    ),
                    _buildChip(_media!.statusText, Colors.green),
                  ],
                ),

                const SizedBox(height: 16),

                // Add to List / Edit Entry Button
                SizedBox(
                  width: double.infinity,
                  child: _listEntry != null
                      ? ElevatedButton.icon(
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: AppTheme.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add to List'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentRed,
                            foregroundColor: AppTheme.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      width: 120,
      height: 180,
      color: AppTheme.secondaryBlack,
      child: const Icon(
        Icons.image_not_supported,
        color: AppTheme.textGray,
        size: 48,
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          HtmlWidget(
            _media!.description!,
            textStyle: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
              height: 1.5,
            ),
            onTapUrl: (url) => _handleUrlTap(url),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  Icons.star,
                  'Score',
                  _media!.averageScore != null
                      ? '${(_media!.averageScore! / 10).toStringAsFixed(1)}/10'
                      : 'N/A',
                  Colors.amber,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  Icons.people,
                  'Popularity',
                  _formatNumber(_media!.popularity ?? 0),
                  Colors.blue,
                ),
              ),
              if (_media!.isAnime && _media!.episodes != null)
                Expanded(
                  child: _buildStatItem(
                    Icons.tv,
                    'Episodes',
                    '${_media!.episodes}',
                    Colors.purple,
                  ),
                ),
              if (_media!.isManga && _media!.chapters != null)
                Expanded(
                  child: _buildStatItem(
                    Icons.book,
                    'Chapters',
                    '${_media!.chapters}',
                    Colors.purple,
                  ),
                ),
            ],
          ),
          if (_media!.isManga && _media!.volumes != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.collections_bookmark,
                    'Volumes',
                    '${_media!.volumes}',
                    Colors.green,
                  ),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
          if (_media!.isAnime && _media!.duration != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.timer,
                    'Duration',
                    '${_media!.duration} min',
                    Colors.orange,
                  ),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDatesAndSeason() {
    if (_media!.startDate == null &&
        _media!.endDate == null &&
        _media!.season == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Release Information',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_media!.season != null && _media!.seasonYear != null)
            _buildInfoRow(
              Icons.calendar_today,
              'Season',
              '${_formatSeason(_media!.season!)} ${_media!.seasonYear}',
            ),
          if (_media!.startDate != null)
            _buildInfoRow(
              Icons.play_arrow,
              'Start Date',
              _formatDate(_media!.startDate!),
            ),
          if (_media!.endDate != null)
            _buildInfoRow(
              Icons.stop,
              'End Date',
              _formatDate(_media!.endDate!),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceAndStudios() {
    if (_media!.source == null && (_media!.studios == null || _media!.studios!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Production',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_media!.source != null)
            _buildInfoRow(
              Icons.source,
              'Source',
              _formatSource(_media!.source!),
            ),
          // Studios (Main) - только студии с isMain = true
          if (_media!.studios != null && _media!.studios!.whereType<MediaStudio>().any((s) => s.isMain)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.business, color: AppTheme.textGray, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Studios: ',
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _media!.studios!
                          .whereType<MediaStudio>()
                          .where((studio) => studio.isMain)
                          .map((studio) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudioDetailsPage(
                                  studioId: studio.id,
                                  anilistService: _anilist,
                                  localStorageService: _localStorage,
                                  supabaseService: _supabase,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            studio.name,
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Producers (Support) - только студии с isMain = false
          if (_media!.studios != null && _media!.studios!.whereType<MediaStudio>().any((s) => !s.isMain)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.people, color: AppTheme.textGray, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Producers: ',
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _media!.studios!
                          .whereType<MediaStudio>()
                          .where((studio) => !studio.isMain)
                          .map((studio) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudioDetailsPage(
                                  studioId: studio.id,
                                  anilistService: _anilist,
                                  localStorageService: _localStorage,
                                  supabaseService: _supabase,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            studio.name,
                            style: const TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textGray, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenres() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genres',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _media!.genres!.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accentRed.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSynonyms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alternative Titles',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...(_media!.synonyms!.map((synonym) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $synonym',
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 14,
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildTrailer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trailer',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _launchTrailer(),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_media!.bannerImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _media!.bannerImage!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Icon(
                    Icons.play_circle_outline,
                    size: 64,
                    color: AppTheme.textWhite,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacters() {
    final charactersCount = _media!.characters!.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Characters',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (charactersCount > 12)
                  TextButton(
                    onPressed: () => _showAllCharacters(),
                    child: Text(
                      'View All ($charactersCount)',
                      style: const TextStyle(
                        color: AppTheme.accentRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: charactersCount.clamp(0, 12), // Показываем максимум 12
              itemBuilder: (context, index) {
                final character = _media!.characters![index];
                return _buildCharacterCard(character);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllCharacters() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardGray,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Characters (${_media!.characters!.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 120,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _media!.characters!.length,
                  itemBuilder: (context, index) {
                    final character = _media!.characters![index];
                    return _buildCharacterCard(character);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCard(MediaCharacter character) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CharacterDetailsPage(
              characterId: character.id,
              anilistService: _anilist,
              localStorageService: _localStorage,
              supabaseService: _supabase,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: character.image != null
                  ? Image.network(
                      character.image!,
                      width: 100,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 120,
                          color: AppTheme.secondaryBlack,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.textGray,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 120,
                      color: AppTheme.secondaryBlack,
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.textGray,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              character.name ?? 'Unknown',
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (character.role != null)
              Text(
                character.role!,
                style: TextStyle(
                  color: character.role == 'MAIN'
                      ? AppTheme.accentRed
                      : AppTheme.textGray,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelations() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Related Media',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _media!.relations!.length,
              itemBuilder: (context, index) {
                final relation = _media!.relations![index];
                return _buildRelationCard(relation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationCard(MediaRelation relation) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaDetailsPage(mediaId: relation.id),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: relation.coverImage != null
                  ? Image.network(
                      relation.coverImage!,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 120,
                          height: 160,
                          color: AppTheme.secondaryBlack,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppTheme.textGray,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 120,
                      height: 160,
                      color: AppTheme.secondaryBlack,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppTheme.textGray,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              relation.relationTypeText,
              style: const TextStyle(
                color: AppTheme.accentRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              relation.title ?? 'Unknown',
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatSeason(String season) {
    switch (season) {
      case 'WINTER':
        return 'Winter';
      case 'SPRING':
        return 'Spring';
      case 'SUMMER':
        return 'Summer';
      case 'FALL':
        return 'Fall';
      default:
        return season;
    }
  }

  String _formatSource(String source) {
    switch (source) {
      case 'ORIGINAL':
        return 'Original';
      case 'MANGA':
        return 'Manga';
      case 'LIGHT_NOVEL':
        return 'Light Novel';
      case 'VISUAL_NOVEL':
        return 'Visual Novel';
      case 'VIDEO_GAME':
        return 'Video Game';
      case 'OTHER':
        return 'Other';
      case 'NOVEL':
        return 'Novel';
      case 'DOUJINSHI':
        return 'Doujinshi';
      case 'ANIME':
        return 'Anime';
      default:
        return source;
    }
  }

  Future<void> _launchTrailer() async {
    if (_media!.trailer == null) return;

    final url = Uri.parse('https://www.youtube.com/watch?v=${_media!.trailer}');
    
    // Save ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not open trailer')),
        );
      }
    }
  }

  Widget _buildTags() {
    final tags = _media!.tags!;
    final spoilerTags = tags.where((t) => t.isMediaSpoiler == true).toList();
    final normalTags = tags.where((t) => t.isMediaSpoiler != true).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tags',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (normalTags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: normalTags.take(20).map((tag) {
                final rank = tag.rank ?? 0;
                final opacity = (rank / 100).clamp(0.3, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Chip(
                    label: Text(
                      tag.name,
                      style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                    ),
                    backgroundColor: AppTheme.accentRed.withOpacity(0.2),
                    side: BorderSide(color: AppTheme.accentRed.withOpacity(0.5)),
                  ),
                );
              }).toList(),
            ),
          if (spoilerTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text(
                'Spoiler Tags (Click to reveal)',
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
              ),
              iconColor: AppTheme.accentRed,
              collapsedIconColor: AppTheme.textGray,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: spoilerTags.take(10).map((tag) {
                    return Chip(
                      label: Text(
                        tag.name,
                        style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                      ),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExternalLinks() {
    final links = _media!.externalLinks!;
    final streamingLinks = links.where((l) => l.isStreaming).toList();
    final otherLinks = links.where((l) => !l.isStreaming).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (streamingLinks.isNotEmpty) ...[
            const Text(
              'Streaming',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...streamingLinks.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _launchUrl(link.url),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline, color: AppTheme.accentRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          link.site,
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: AppTheme.textGray, size: 16),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (otherLinks.isNotEmpty) ...[
            const Text(
              'External Links',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...otherLinks.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => _launchUrl(link.url),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBlack,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.textGray.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: AppTheme.textGray),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          link.site,
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: AppTheme.textGray, size: 16),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildStaff() {
    final staffCount = _media!.staff!.length;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Staff',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (staffCount > 12)
                TextButton(
                  onPressed: () => _showAllStaff(),
                  child: Text(
                    'View All ($staffCount)',
                    style: const TextStyle(
                      color: AppTheme.accentRed,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: staffCount.clamp(0, 12), // Показываем максимум 12
              itemBuilder: (context, index) {
                return _buildStaffCard(_media!.staff![index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAllStaff() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardGray,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Staff (${_media!.staff!.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 160,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _media!.staff!.length,
                  itemBuilder: (context, index) {
                    final staff = _media!.staff![index];
                    return _buildStaffCard(staff);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(MediaStaff staff) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffDetailsPage(
              staffId: staff.id,
              anilistService: _anilist,
              localStorageService: _localStorage,
              supabaseService: _supabase,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Staff Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: staff.image != null
                  ? Image.network(
                      staff.image!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(120),
                    )
                  : _buildImagePlaceholder(120),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name ?? 'Unknown',
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (staff.role != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      staff.role!,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommendations',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _media!.recommendations!.length,
              itemBuilder: (context, index) {
                return _buildRecommendationCard(_media!.recommendations![index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(MediaRecommendation rec) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaDetailsPage(mediaId: rec.id),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: rec.coverImage != null
                  ? Image.network(
                      rec.coverImage!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(160),
                    )
                  : _buildImagePlaceholder(160),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title ?? 'Unknown',
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rec.averageScore != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${rec.averageScore}%',
                          style: const TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final dist = _media!.statusDistribution!;
    final total = dist.values.fold(0, (sum, val) => sum + val);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Distribution',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...dist.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0.0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatStatus(entry.key),
                        style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                      ),
                      Text(
                        '${entry.value} ($percentage%)',
                        style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: AppTheme.secondaryBlack,
                      valueColor: AlwaysStoppedAnimation(_getStatusColor(entry.key)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'CURRENT':
        return _media!.type == 'ANIME' ? 'Watching' : 'Reading';
      case 'PLANNING':
        return 'Planning';
      case 'COMPLETED':
        return 'Completed';
      case 'DROPPED':
        return 'Dropped';
      case 'PAUSED':
        return 'Paused';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CURRENT':
        return Colors.green;
      case 'PLANNING':
        return Colors.blue;
      case 'COMPLETED':
        return AppTheme.accentRed;
      case 'DROPPED':
        return Colors.red;
      case 'PAUSED':
        return Colors.orange;
      default:
        return AppTheme.textGray;
    }
  }

  Widget _buildImagePlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppTheme.secondaryBlack,
      child: const Icon(Icons.person, color: AppTheme.textGray, size: 40),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    
    // Save ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    if (_media == null) return;

    // Create a new entry from MediaDetails
    final newEntry = MediaListEntry(
      id: 0, // Will be assigned by AniList
      mediaId: _media!.id,
      status: 'PLANNING',
      score: null,
      progress: 0,
      progressVolumes: null,
      repeat: 0,
      notes: null,
      startedAt: null,
      completedAt: null,
      updatedAt: null,
      media: _media!.toAnimeModel(),
    );

    // Save ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => EditEntryDialog(
        entry: newEntry,
        isAnime: _media!.isAnime,
        mediaStatus: _media!.status, // Pass media status for filtering
        onSave: (updatedEntry) async {
          try {
            // Save to AniList first (pass mediaId for new entries)
            final result = await _anilist.updateMediaListEntry(
              entryId: updatedEntry.id == 0 ? null : updatedEntry.id,
              mediaId: updatedEntry.id == 0 ? _media!.id : null,
              status: updatedEntry.status,
              score: updatedEntry.score,
              progress: updatedEntry.progress,
              progressVolumes: updatedEntry.progressVolumes,
              notes: updatedEntry.notes,
            );

            if (result != null) {
              // Update entry with AniList ID
              final savedEntry = updatedEntry.copyWith(
                id: result['id'] as int,
              );

              // Save to local storage
              if (_media!.isAnime) {
                final animeList = _localStorage.getAnimeList();
                final existingIndex = animeList.indexWhere((e) => e.mediaId == savedEntry.mediaId);
                if (existingIndex != -1) {
                  animeList[existingIndex] = savedEntry;
                } else {
                  animeList.add(savedEntry);
                }
                await _localStorage.saveAnimeList(animeList);
              } else {
                final mangaList = _localStorage.getMangaList();
                final existingIndex = mangaList.indexWhere((e) => e.mediaId == savedEntry.mediaId);
                if (existingIndex != -1) {
                  mangaList[existingIndex] = savedEntry;
                } else {
                  mangaList.add(savedEntry);
                }
                await _localStorage.saveMangaList(mangaList);
              }

              // Update UI
              if (mounted) {
                setState(() {
                  _listEntry = savedEntry;
                });

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('✓ Added to list'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to add: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onDelete: null, // No delete for new entries
      ),
    );
  }

  Future<void> _showEditDialog() async {
    if (_listEntry == null) return;

    // Save ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (context) => EditEntryDialog(
        entry: _listEntry!,
        isAnime: _media!.isAnime,
        mediaStatus: _media!.status, // Pass media status for filtering
        onSave: (updatedEntry) async {
          try {
            // Update in AniList
            final result = await _anilist.updateMediaListEntry(
              entryId: updatedEntry.id,
              status: updatedEntry.status,
              score: updatedEntry.score,
              progress: updatedEntry.progress,
              progressVolumes: updatedEntry.progressVolumes,
              notes: updatedEntry.notes,
            );

            if (result != null) {
              // Update local storage
              if (_media!.isAnime) {
                await _localStorage.updateAnimeEntry(updatedEntry);
              } else {
                await _localStorage.updateMangaEntry(updatedEntry);
              }

              // Update UI
              if (mounted) {
                setState(() {
                  _listEntry = updatedEntry;
                });

                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('✓ Updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to update: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onDelete: () async {
          try {
            // Delete from local storage
            if (_media!.isAnime) {
              final animeList = _localStorage.getAnimeList();
              animeList.removeWhere((e) => e.id == _listEntry!.id);
              await _localStorage.saveAnimeList(animeList);
            } else {
              final mangaList = _localStorage.getMangaList();
              mangaList.removeWhere((e) => e.id == _listEntry!.id);
              await _localStorage.saveMangaList(mangaList);
            }

            // Update UI
            if (mounted) {
              setState(() {
                _listEntry = null;
              });

              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('✓ Removed from list'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Failed to delete: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  bool _handleUrlTap(String url) {
    // Check if it's an AniList media link
    final anilistRegex = RegExp(r'anilist\.co/(anime|manga)/(\d+)');
    final match = anilistRegex.firstMatch(url);
    
    if (match != null) {
      // Extract media ID and navigate to MediaDetailsPage
      final mediaId = int.parse(match.group(2)!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailsPage(mediaId: mediaId),
        ),
      );
      return true; // Handled internally
    }
    
    // For other links, open in external browser
    _launchUrl(url);
    return true; // Handled
  }
}
