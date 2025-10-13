import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/staff_details.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';
import '../../../character/presentation/pages/character_details_page.dart';

class StaffDetailsPage extends StatefulWidget {
  final int staffId;
  final AniListService anilistService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const StaffDetailsPage({
    super.key,
    required this.staffId,
    required this.anilistService,
    required this.localStorageService,
    required this.supabaseService,
  });

  @override
  State<StaffDetailsPage> createState() => _StaffDetailsPageState();
}

class _StaffDetailsPageState extends State<StaffDetailsPage> with SingleTickerProviderStateMixin {
  StaffDetails? _staff;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStaffDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Попробуем получить из кеша Hive
      StaffDetails? staff = widget.localStorageService.getStaffDetails(widget.staffId);

      // Если кеш просрочен или не найден, загружаем из AniList
      if (staff == null || staff.isCacheExpired()) {
        print('📡 Loading staff from AniList...');
        staff = await widget.anilistService.getStaffDetails(widget.staffId);

        if (staff != null) {
          // Сохраняем в кеш
          await widget.localStorageService.saveStaffDetails(staff);
          print('✅ Staff cached in Hive');
        }
      } else {
        print('✅ Staff loaded from Hive cache');
      }

      if (mounted) {
        setState(() {
          _staff = staff;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading staff: $e');
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

  void _navigateToCharacter(int characterId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterDetailsPage(
          characterId: characterId,
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
        title: Text(_staff?.name ?? 'Staff'),
        actions: [
          if (_staff != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStaffDetails,
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
                        onPressed: _loadStaffDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _staff == null
                  ? const Center(child: Text('Staff not found'))
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
          if (_staff!.description != null && _staff!.description!.isNotEmpty)
            _buildSection(
              title: 'About',
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: _staff!.description!,
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

          // Staff Info
          _buildStaffInfo(),

          // Social Media Links
          if (_staff!.socialMedia != null && _staff!.socialMedia!.isNotEmpty)
            _buildSocialMediaSection(),

          // Works and Characters Tabs
          if ((_staff!.staffMedia != null && _staff!.staffMedia!.isNotEmpty) ||
              (_staff!.characters != null && _staff!.characters!.isNotEmpty))
            _buildTabSection(),

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
          // Staff Image
          Hero(
            tag: 'staff_${_staff!.id}',
            child: Container(
              width: 120,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentRed, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _staff!.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _staff!.imageUrl!,
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

          // Staff Name and Basic Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _staff!.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),

                // Alternative Names
                if (_staff!.alternativeNames != null &&
                    _staff!.alternativeNames!.isNotEmpty)
                  ...[
                    const SizedBox(height: 8),
                    Text(
                      _staff!.alternativeNames!.join(', '),
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ],

                const SizedBox(height: 16),

                // Favourites
                if (_staff!.favourites != null)
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppTheme.accentRed, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${_staff!.favourites} favorites',
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

  Widget _buildStaffInfo() {
    final hasInfo = _staff!.gender != null ||
        _staff!.age != null ||
        _staff!.dateOfBirth != null ||
        _staff!.dateOfDeath != null ||
        _staff!.homeTown != null ||
        _staff!.yearsActive != null;

    if (!hasInfo) return const SizedBox.shrink();

    return _buildSection(
      title: 'Staff Information',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_staff!.gender != null)
              _buildInfoRow('Gender', _staff!.gender!),
            if (_staff!.age != null)
              _buildInfoRow('Age', _staff!.age!),
            if (_staff!.dateOfBirth != null)
              _buildInfoRow('Date of Birth', _staff!.dateOfBirth!),
            if (_staff!.dateOfDeath != null)
              _buildInfoRow('Date of Death', _staff!.dateOfDeath!),
            if (_staff!.homeTown != null)
              _buildInfoRow('Home Town', _staff!.homeTown!),
            if (_staff!.yearsActive != null)
              _buildInfoRow('Years Active', _staff!.yearsActive!),
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

  Widget _buildSocialMediaSection() {
    return _buildSection(
      title: 'Links',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _staff!.socialMedia!.map((link) {
            return OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(link.url)),
              icon: const Icon(Icons.link),
              label: Text(link.platform),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentRed,
                side: const BorderSide(color: AppTheme.accentRed),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Works (${_staff!.staffMedia?.length ?? 0})'),
            Tab(text: 'Characters (${_staff!.characters?.length ?? 0})'),
          ],
          indicatorColor: AppTheme.accentRed,
          labelColor: AppTheme.accentRed,
          unselectedLabelColor: AppTheme.textGray,
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWorksTab(),
              _buildCharactersTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorksTab() {
    if (_staff!.staffMedia == null || _staff!.staffMedia!.isEmpty) {
      return const Center(child: Text('No works found'));
    }

    final worksList = _staff!.staffMedia!;
    final displayCount = worksList.length > 10 ? 10 : worksList.length;
    final hasMore = worksList.length > 10;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final media = worksList[index];
              return _buildMediaCard(media);
            },
          ),
        ),
        if (hasMore)
          TextButton.icon(
            onPressed: () => _showAllWorks(),
            icon: const Icon(Icons.grid_view, size: 18),
            label: Text('See All ${worksList.length} Works'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentBlue,
            ),
          ),
      ],
    );
  }

  Widget _buildCharactersTab() {
    if (_staff!.characters == null || _staff!.characters!.isEmpty) {
      return const Center(child: Text('No characters found'));
    }

    final charList = _staff!.characters!;
    final displayCount = charList.length > 10 ? 10 : charList.length;
    final hasMore = charList.length > 10;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              final character = charList[index];
              return _buildCharacterCard(character);
            },
          ),
        ),
        if (hasMore)
          TextButton.icon(
            onPressed: () => _showAllCharacters(),
            icon: const Icon(Icons.grid_view, size: 18),
            label: Text('See All ${charList.length} Characters'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentBlue,
            ),
          ),
      ],
    );
  }

  void _showAllWorks() {
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
                    'All Works (${_staff!.staffMedia!.length})',
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
                  itemCount: _staff!.staffMedia!.length,
                  itemBuilder: (context, index) {
                    final media = _staff!.staffMedia![index];
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

  void _showAllCharacters() {
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
                    'All Characters (${_staff!.characters!.length})',
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
                  itemCount: _staff!.characters!.length,
                  itemBuilder: (context, index) {
                    final character = _staff!.characters![index];
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

  Widget _buildMediaCard(StaffMedia media) {
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
            if (media.staffRole != null)
              Flexible(
                child: Text(
                  media.staffRole!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(StaffCharacter character) {
    return GestureDetector(
      onTap: () => _navigateToCharacter(character.id),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Character Image
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: character.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: character.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: AppTheme.secondaryBlack,
                        child: const Icon(Icons.person, size: 40),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Flexible(
              child: Text(
                character.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Media Title
            if (character.mediaTitle != null)
              Flexible(
                child: Text(
                  character.mediaTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGray,
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
