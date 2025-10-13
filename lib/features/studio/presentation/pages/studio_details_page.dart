import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/studio_details.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class StudioDetailsPage extends StatefulWidget {
  final int studioId;
  final AniListService anilistService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const StudioDetailsPage({
    super.key,
    required this.studioId,
    required this.anilistService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<StudioDetailsPage> createState() => _StudioDetailsPageState();
}

class _StudioDetailsPageState extends State<StudioDetailsPage> with SingleTickerProviderStateMixin {
  StudioDetails? _studio;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudioDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudioDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Попробуем получить из кеша Hive
      StudioDetails? studio = widget.localStorageService.getStudioDetails(widget.studioId);

      // Если кеш просрочен или не найден, загружаем из AniList
      if (studio == null || studio.isCacheExpired()) {
        print('📡 Loading studio from AniList...');
        studio = await widget.anilistService.getStudioDetails(widget.studioId);

        if (studio != null) {
          // Сохраняем в кеш
          await widget.localStorageService.saveStudioDetails(studio);
          print('✅ Studio cached in Hive');
        }
      } else {
        print('✅ Studio loaded from Hive cache');
      }

      if (mounted) {
        setState(() {
          _studio = studio;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading studio: $e');
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
        title: Text(_studio?.name ?? 'Studio'),
        actions: [
          if (_studio != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStudioDetails,
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
                        onPressed: _loadStudioDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _studio == null
                  ? const Center(child: Text('Studio not found'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with studio name and info
          _buildHeader(),

          // Studio Info
          _buildStudioInfo(),

          // Link to AniList
          if (_studio!.siteUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(_studio!.siteUrl!)),
                icon: const Icon(Icons.link),
                label: const Text('View on AniList'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  side: const BorderSide(color: AppTheme.accentRed),
                ),
              ),
            ),

          // Productions
          if (_studio!.media != null && _studio!.media!.isNotEmpty)
            _buildProductionsSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppTheme.secondaryBlack,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Studio Name
          Row(
            children: [
              const Icon(Icons.business, color: AppTheme.accentRed, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _studio!.name,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Studio Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _studio!.isAnimationStudio
                  ? AppTheme.accentRed.withOpacity(0.2)
                  : AppTheme.accentBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _studio!.isAnimationStudio
                    ? AppTheme.accentRed
                    : AppTheme.accentBlue,
              ),
            ),
            child: Text(
              _studio!.isAnimationStudio ? 'Animation Studio' : 'Production Company',
              style: TextStyle(
                color: _studio!.isAnimationStudio
                    ? AppTheme.accentRed
                    : AppTheme.accentBlue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Favourites
          if (_studio!.favourites != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.favorite, color: AppTheme.accentRed, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${_studio!.favourites} favorites',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudioInfo() {
    if (_studio!.media == null || _studio!.media!.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainStudios = _studio!.media!.where((m) => m.isMainStudio).length;
    final supportStudios = _studio!.media!.where((m) => !m.isMainStudio).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Main Studio',
                  mainStudios.toString(),
                  Icons.star,
                  AppTheme.accentRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Support',
                  supportStudios.toString(),
                  Icons.support,
                  AppTheme.accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionsSection() {
    final mainStudios = _studio!.media!.where((m) => m.isMainStudio).toList();
    final supportStudios = _studio!.media!.where((m) => !m.isMainStudio).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mainStudios.isNotEmpty) ...[
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Main Studio (${mainStudios.length})'),
                Tab(text: 'Support (${supportStudios.length})'),
              ],
              indicatorColor: AppTheme.accentRed,
              labelColor: AppTheme.accentRed,
              unselectedLabelColor: AppTheme.textGray,
            ),
            SizedBox(
              height: 600, // Фиксированная высота для TabBarView
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMediaList(mainStudios),
                  _buildMediaList(supportStudios),
                ],
              ),
            ),
          ] else
            _buildMediaList(_studio!.media!),
        ],
      ),
    );
  }

  Widget _buildMediaList(List<StudioMedia> mediaList) {
    if (mediaList.isEmpty) {
      return const Center(child: Text('No productions found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        childAspectRatio: 0.57,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        return _buildMediaCard(media);
      },
    );
  }

  Widget _buildMediaCard(StudioMedia media) {
    return GestureDetector(
      onTap: () => _navigateToMedia(media.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Expanded(
            child: Container(
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
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            media.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Year and Season
          if (media.seasonYear != null || media.season != null)
            Text(
              [
                if (media.season != null) media.season!,
                if (media.seasonYear != null) media.seasonYear.toString(),
              ].join(' '),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textGray,
              ),
            ),

          // Score
          if (media.averageScore != null)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${media.averageScore}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
