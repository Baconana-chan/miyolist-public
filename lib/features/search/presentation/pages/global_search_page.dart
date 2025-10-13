import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/search_result.dart';
import '../../../../core/models/search_filters.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/search_result_skeleton.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/advanced_search_filters_dialog.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';
import '../../../character/presentation/pages/character_details_page.dart';
import '../../../staff/presentation/pages/staff_details_page.dart';
import '../../../studio/presentation/pages/studio_details_page.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  late final AniListService _anilistService;
  late final LocalStorageService _localStorage;
  late final SupabaseService _supabase;
  late final SearchHistoryService _searchHistory;
  final TextEditingController _searchController = TextEditingController();
  
  List<SearchResult> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String? _error;
  String _selectedType = 'ALL'; // ALL, ANIME, MANGA, CHARACTER, STAFF, STUDIO
  SearchFilters _filters = SearchFilters();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadRecentSearches();
  }

  void _initializeServices() {
    _localStorage = LocalStorageService();
    _supabase = SupabaseService();
    final authService = AuthService();
    _anilistService = AniListService(authService);
    _searchHistory = SearchHistoryService();
    _searchHistory.init();
  }

  Future<void> _loadRecentSearches() async {
    final recent = await _searchHistory.getRecentSearches();
    setState(() {
      _recentSearches = recent;
    });
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
      List<Map<String, dynamic>> results;
      
      // Используем расширенный поиск для медиа с фильтрами
      if (_selectedType == 'ANIME' || _selectedType == 'MANGA' || _selectedType == 'ALL') {
        results = await _anilistService.advancedSearch(
          query: query,
          type: _selectedType == 'ALL' ? null : _selectedType,
          genres: _filters.genres,
          year: _filters.year,
          season: _filters.season,
          format: _filters.format,
          status: _filters.status,
          scoreMin: _filters.scoreMin,
          scoreMax: _filters.scoreMax,
          episodesMin: _filters.episodesMin,
          episodesMax: _filters.episodesMax,
          chaptersMin: _filters.chaptersMin,
          chaptersMax: _filters.chaptersMax,
          sortBy: _filters.sortBy,
        );
      } else {
        // Для персонажей, стафа и студий используем обычный поиск
        results = await _anilistService.globalSearch(
          query: query,
          type: _selectedType,
        );
      }

      final searchResults = results.map((result) {
        final type = result['type'] as String;
        final data = result['data'] as Map<String, dynamic>;
        
        if (type == 'CHARACTER') {
          return SearchResult.fromCharacter(data);
        } else if (type == 'STAFF') {
          return SearchResult.fromStaff(data);
        } else if (type == 'STUDIO') {
          return SearchResult.fromStudio(data);
        } else {
          return SearchResult.fromMedia(data);
        }
      }).toList();

      // Фильтруем взрослый контент (если не включена опция показа)
      final filteredResults = searchResults.where((result) {
        // Проверяем только медиа (аниме/манга)
        if (result.type != 'ANIME' && result.type != 'MANGA') {
          return true; // Оставляем персонажей, стаф и студии
        }
        
        // Если включен показ контента для взрослых, пропускаем все
        if (_filters.includeAdultContent) {
          return true;
        }
        
        // Получаем оригинальные данные
        final originalData = results.firstWhere(
          (r) => r['data']['id'] == result.id,
          orElse: () => {'data': {}},
        )['data'] as Map<String, dynamic>;
        
        // Проверяем жанры на наличие Hentai или Ecchi (опционально)
        final genres = originalData['genres'] as List<dynamic>?;
        if (genres != null) {
          final genreList = genres.map((g) => g.toString().toLowerCase()).toList();
          
          // Фильтруем Hentai
          if (genreList.contains('hentai')) {
            return false;
          }
          
          // Опционально: фильтровать Ecchi (закомментировано, раскомментируйте если нужно)
          // if (genreList.contains('ecchi')) {
          //   return false;
          // }
        }
        
        // Проверяем теги на наличие NSFW контента
        final tags = originalData['tags'] as List<dynamic>?;
        if (tags != null) {
          for (var tag in tags) {
            if (tag is Map<String, dynamic>) {
              final tagName = tag['name']?.toString().toLowerCase() ?? '';
              final isAdult = tag['isAdult'] as bool? ?? false;
              
              // Фильтруем контент помеченный как для взрослых
              if (isAdult || tagName.contains('hentai')) {
                return false;
              }
            }
          }
        }
        
        // Проверяем возрастной рейтинг (isAdult)
        final isAdult = originalData['isAdult'] as bool? ?? false;
        if (isAdult) {
          return false;
        }
        
        return true;
      }).toList();

      // Сохраняем в историю
      await _searchHistory.addToHistory(query, filters: _filters);
      await _loadRecentSearches();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  void _openFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AdvancedSearchFiltersDialog(
        initialFilters: _filters,
        onApply: (filters) {
          setState(() {
            _filters = filters;
          });
          if (_searchController.text.isNotEmpty) {
            _performSearch();
          }
        },
      ),
    );
  }

  void _updateSortOption(String sortBy) {
    setState(() {
      _filters = _filters.copyWith(sortBy: sortBy);
    });
    if (_searchController.text.isNotEmpty) {
      _performSearch();
    }
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_filters.genres != null && _filters.genres!.isNotEmpty) count++;
    if (_filters.year != null) count++;
    if (_filters.season != null) count++;
    if (_filters.format != null) count++;
    if (_filters.status != null) count++;
    if (_filters.scoreMin != null || _filters.scoreMax != null) count++;
    if (_filters.episodesMin != null || _filters.episodesMax != null) count++;
    if (_filters.chaptersMin != null || _filters.chaptersMax != null) count++;
    return count;
  }

  void _onResultTap(SearchResult result) {
    if (result.type == 'ANIME' || result.type == 'MANGA') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailsPage(mediaId: result.id),
        ),
      );
    } else if (result.type == 'CHARACTER') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CharacterDetailsPage(
            characterId: result.id,
            anilistService: _anilistService,
            localStorageService: _localStorage,
            supabaseService: _supabase,
          ),
        ),
      );
    } else if (result.type == 'STAFF') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StaffDetailsPage(
            staffId: result.id,
            anilistService: _anilistService,
            localStorageService: _localStorage,
            supabaseService: _supabase,
          ),
        ),
      );
    } else if (result.type == 'STUDIO') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudioDetailsPage(
            studioId: result.id,
            anilistService: _anilistService,
            localStorageService: _localStorage,
            supabaseService: _supabase,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showFilters = _selectedType == 'ANIME' || _selectedType == 'MANGA' || _selectedType == 'ALL';
    
    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('Advanced Search'),
        elevation: 0,
        actions: [
          // Sort Button (только для медиа)
          if (showFilters)
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: _updateSortOption,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'POPULARITY_DESC',
                  child: Text('Popularity'),
                ),
                const PopupMenuItem(
                  value: 'SCORE_DESC',
                  child: Text('Score'),
                ),
                const PopupMenuItem(
                  value: 'TRENDING_DESC',
                  child: Text('Trending'),
                ),
                const PopupMenuItem(
                  value: 'TITLE_ROMAJI',
                  child: Text('Alphabetical'),
                ),
                const PopupMenuItem(
                  value: 'UPDATED_AT_DESC',
                  child: Text('Recently Updated'),
                ),
                const PopupMenuItem(
                  value: 'START_DATE_DESC',
                  child: Text('Release Date'),
                ),
              ],
            ),
        ],
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
                    hintText: 'Search anime, manga, characters, staff, studios...',
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
                
                // Type Filter and Buttons Row
                Row(
                  children: [
                    // Type Filter - Scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
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
                            const SizedBox(width: 8),
                            _buildTypeChip('CHARACTER', 'Characters'),
                            const SizedBox(width: 8),
                            _buildTypeChip('STAFF', 'Staff'),
                            const SizedBox(width: 8),
                            _buildTypeChip('STUDIO', 'Studios'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Filters and Search Buttons
                if (showFilters) ...[
                  Row(
                    children: [
                      // Advanced Filters Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openFiltersDialog,
                          icon: Icon(
                            Icons.filter_list,
                            color: _filters.hasActiveFilters
                                ? AppTheme.accentRed
                                : AppTheme.textGray,
                          ),
                          label: Text(
                            _filters.hasActiveFilters
                                ? 'Filters (${_getActiveFiltersCount()})'
                                : 'Advanced Filters',
                            style: TextStyle(
                              color: _filters.hasActiveFilters
                                  ? AppTheme.accentRed
                                  : AppTheme.textGray,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _filters.hasActiveFilters
                                  ? AppTheme.accentRed
                                  : AppTheme.textGray,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search Button
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
                ] else ...[
                  // Search Button (full width for non-media)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        foregroundColor: AppTheme.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                ],
                
                // Recent Searches (показываем когда поле пустое)
                if (_searchController.text.isEmpty && _recentSearches.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Searches',
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await _searchHistory.clearHistory();
                              await _loadRecentSearches();
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recentSearches.map((query) {
                          return ActionChip(
                            label: Text(query),
                            onPressed: () {
                              _searchController.text = query;
                              setState(() {});
                              _performSearch();
                            },
                            backgroundColor: AppTheme.cardGray,
                            labelStyle: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
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
          // Очищаем фильтры при смене типа на не-медиа
          if (value == 'CHARACTER' || value == 'STAFF' || value == 'STUDIO') {
            _filters = SearchFilters();
          }
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
        // Initial state
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: AppTheme.accentRed.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Advanced Search',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Search with advanced filters for anime, manga,\ncharacters, staff, and studios',
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
        // No results
        return EmptyStateWidget(
          icon: Icons.search_off,
          iconColor: AppTheme.textGray,
          title: 'No results found',
          description: 'No matches for "${_searchController.text}".\nTry a different search term or adjust filters.',
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    IconData icon;
    switch (result.type) {
      case 'CHARACTER':
        icon = Icons.person;
        break;
      case 'STAFF':
        icon = Icons.mic;
        break;
      case 'STUDIO':
        icon = Icons.business;
        break;
      default:
        icon = Icons.movie;
    }

    return GestureDetector(
      onTap: () => _onResultTap(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.mangaPanelDecoration,
        child: Row(
          children: [
            // Image or Icon
            if (result.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: result.imageUrl!,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 120,
                    color: AppTheme.secondaryBlack,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 120,
                    color: AppTheme.secondaryBlack,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: Icon(icon, size: 40, color: AppTheme.textGray),
              ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        result.subtitle!,
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.type,
                            style: const TextStyle(
                              color: AppTheme.accentRed,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (result.score != null) ...[
                          const Spacer(),
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${result.score!.toInt()}%',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
