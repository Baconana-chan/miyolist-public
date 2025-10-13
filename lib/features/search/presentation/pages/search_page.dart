import 'package:flutter/material.dart';
import '../../../../core/models/media_details.dart';
import '../../../../core/services/media_search_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/search_result_skeleton.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/search_result_card.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final MediaSearchService _searchService;
  final TextEditingController _searchController = TextEditingController();
  
  List<MediaDetails> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _selectedType = 'ALL'; // ALL, ANIME, MANGA

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    final localStorage = LocalStorageService();
    final supabase = SupabaseService();
    final authService = AuthService();
    final anilist = AniListService(authService);
    
    _searchService = MediaSearchService(
      localStorage: localStorage,
      supabase: supabase,
      anilist: anilist,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _searchService.searchMedia(
        query: query,
        type: _selectedType == 'ALL' ? null : _selectedType,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  void _onMediaTap(MediaDetails media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailsPage(mediaId: media.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('Search Anime & Manga'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryBlack,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Search anime or manga...',
                    hintStyle: const TextStyle(color: AppTheme.textGray),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textGray),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.textGray),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _error = null;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.cardGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onChanged: (value) => setState(() {}),
                ),
                
                const SizedBox(height: 12),
                
                // Type Filter
                Row(
                  children: [
                    const Text(
                      'Type:',
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildTypeChip('ALL', 'All'),
                    const SizedBox(width: 8),
                    _buildTypeChip('ANIME', 'Anime'),
                    const SizedBox(width: 8),
                    _buildTypeChip('MANGA', 'Manga'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: AppTheme.textWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = value;
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch();
        }
      },
      backgroundColor: AppTheme.cardGray,
      selectedColor: AppTheme.accentRed.withOpacity(0.3),
      checkmarkColor: AppTheme.accentRed,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.accentRed : Colors.transparent,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SearchResultListSkeleton(itemCount: 8);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentRed,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isEmpty) {
        // Initial state - no search yet
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: AppTheme.accentBlue.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Search for anime and manga',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter a title in the search bar above to find media',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGray,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      } else {
        // Search performed but no results
        return EmptyStateWidget(
          icon: Icons.search_off,
          iconColor: AppTheme.textGray,
          title: 'No results found',
          description: 'No matches for "${_searchController.text}".\nTry a different search term or check your spelling.',
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final media = _searchResults[index];
        return SearchResultCard(
          media: media,
          onTap: () => _onMediaTap(media),
        );
      },
    );
  }
}
