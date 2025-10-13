import 'package:flutter/material.dart';
import '../../../../core/models/search_filters.dart';
import '../../../../core/theme/app_theme.dart';

class AdvancedSearchFiltersDialog extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onApply;
  
  const AdvancedSearchFiltersDialog({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<AdvancedSearchFiltersDialog> createState() => _AdvancedSearchFiltersDialogState();
}

class _AdvancedSearchFiltersDialogState extends State<AdvancedSearchFiltersDialog> {
  late SearchFilters _filters;
  
  // Списки опций
  final List<String> _seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  final List<String> _animeFormats = ['TV', 'TV_SHORT', 'MOVIE', 'SPECIAL', 'OVA', 'ONA'];
  final List<String> _mangaFormats = ['MANGA', 'NOVEL', 'ONE_SHOT'];
  final List<String> _statuses = ['FINISHED', 'RELEASING', 'NOT_YET_RELEASED', 'CANCELLED', 'HIATUS'];
  final List<String> _allGenres = [
    'Action', 'Adventure', 'Comedy', 'Drama', 'Ecchi', 'Fantasy',
    'Horror', 'Mahou Shoujo', 'Mecha', 'Music', 'Mystery', 'Psychological',
    'Romance', 'Sci-Fi', 'Slice of Life', 'Sports', 'Supernatural', 'Thriller'
  ];
  
  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }
  
  @override
  Widget build(BuildContext context) {
    final isAnime = _filters.type == 'ANIME' || _filters.type == null;
    final isManga = _filters.type == 'MANGA';
    
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advanced Filters',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppTheme.textGray),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Прокручиваемый контент
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genres
                    _buildSectionTitle('Genres'),
                    _buildGenresSection(),
                    
                    const SizedBox(height: 20),
                    
                    // Year
                    _buildSectionTitle('Year'),
                    _buildYearSlider(),
                    
                    const SizedBox(height: 20),
                    
                    // Season (только для аниме)
                    if (isAnime) ...[
                      _buildSectionTitle('Season'),
                      _buildSeasonChips(),
                      const SizedBox(height: 20),
                    ],
                    
                    // Format
                    _buildSectionTitle('Format'),
                    _buildFormatChips(isAnime ? _animeFormats : _mangaFormats),
                    
                    const SizedBox(height: 20),
                    
                    // Status
                    _buildSectionTitle('Status'),
                    _buildStatusChips(),
                    
                    const SizedBox(height: 20),
                    
                    // Score Range
                    _buildSectionTitle('Score Range'),
                    _buildScoreRange(),
                    
                    const SizedBox(height: 20),
                    
                    // Episodes/Chapters Count
                    if (isAnime) ...[
                      _buildSectionTitle('Episodes'),
                      _buildEpisodesRange(),
                    ] else if (isManga) ...[
                      _buildSectionTitle('Chapters'),
                      _buildChaptersRange(),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Adult Content Toggle
                    _buildAdultContentToggle(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Кнопки действий
            Row(
              children: [
                // Clear Filters
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _filters = _filters.clearFilters();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textGray,
                      side: const BorderSide(color: AppTheme.textGray),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Apply
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_filters);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRed,
                      foregroundColor: AppTheme.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildGenresSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allGenres.map((genre) {
        final isSelected = _filters.genres?.contains(genre) ?? false;
        return FilterChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              final currentGenres = List<String>.from(_filters.genres ?? []);
              if (selected) {
                currentGenres.add(genre);
              } else {
                currentGenres.remove(genre);
              }
              _filters = _filters.copyWith(
                genres: currentGenres.isEmpty ? null : currentGenres,
              );
            });
          },
          selectedColor: AppTheme.accentRed.withOpacity(0.3),
          checkmarkColor: AppTheme.textWhite,
          backgroundColor: AppTheme.cardGray,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildYearSlider() {
    final currentYear = DateTime.now().year;
    final minYear = 1940;
    final selectedYear = _filters.year ?? currentYear;
    
    return Column(
      children: [
        Text(
          selectedYear.toString(),
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Slider(
          value: selectedYear.toDouble(),
          min: minYear.toDouble(),
          max: currentYear.toDouble() + 1,
          divisions: currentYear - minYear + 1,
          activeColor: AppTheme.accentRed,
          inactiveColor: AppTheme.cardGray,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(year: value.toInt());
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minYear.toString(),
              style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
            ),
            Text(
              (currentYear + 1).toString(),
              style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSeasonChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _seasons.map((season) {
        final isSelected = _filters.season == season;
        return ChoiceChip(
          label: Text(season),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                season: selected ? season : null,
              );
            });
          },
          selectedColor: AppTheme.accentRed.withOpacity(0.3),
          backgroundColor: AppTheme.cardGray,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildFormatChips(List<String> formats) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((format) {
        final isSelected = _filters.format == format;
        return ChoiceChip(
          label: Text(format.replaceAll('_', ' ')),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                format: selected ? format : null,
              );
            });
          },
          selectedColor: AppTheme.accentRed.withOpacity(0.3),
          backgroundColor: AppTheme.cardGray,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statuses.map((status) {
        final isSelected = _filters.status == status;
        return ChoiceChip(
          label: Text(status.replaceAll('_', ' ')),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                status: selected ? status : null,
              );
            });
          },
          selectedColor: AppTheme.accentRed.withOpacity(0.3),
          backgroundColor: AppTheme.cardGray,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.textWhite : AppTheme.textGray,
            fontSize: 12,
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildScoreRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'Min',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              hintText: '0',
              hintStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final score = int.tryParse(value);
              if (score != null && score >= 0 && score <= 100) {
                setState(() {
                  _filters = _filters.copyWith(scoreMin: score);
                });
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '-',
            style: TextStyle(color: AppTheme.textGray, fontSize: 20),
          ),
        ),
        Expanded(
          child: TextField(
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'Max',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              hintText: '100',
              hintStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final score = int.tryParse(value);
              if (score != null && score >= 0 && score <= 100) {
                setState(() {
                  _filters = _filters.copyWith(scoreMax: score);
                });
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildEpisodesRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'Min',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              hintText: '1',
              hintStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final episodes = int.tryParse(value);
              if (episodes != null && episodes >= 0) {
                setState(() {
                  _filters = _filters.copyWith(episodesMin: episodes);
                });
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '-',
            style: TextStyle(color: AppTheme.textGray, fontSize: 20),
          ),
        ),
        Expanded(
          child: TextField(
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'Max',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              hintText: '∞',
              hintStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final episodes = int.tryParse(value);
              if (episodes != null && episodes >= 0) {
                setState(() {
                  _filters = _filters.copyWith(episodesMax: episodes);
                });
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildChaptersRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'Min',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              hintText: '1',
              hintStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final chapters = int.tryParse(value);
              if (chapters != null && chapters >= 0) {
                setState(() {
                  _filters = _filters.copyWith(chaptersMin: chapters);
                });
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '-',
            style: TextStyle(color: AppTheme.textGray, fontSize: 20),
          ),
        ),
        Expanded(
          child: TextField(
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: InputDecoration(
              labelText: 'Max',
              labelStyle: const TextStyle(color: AppTheme.textGray),
              hintText: '∞',
              hintStyle: const TextStyle(color: AppTheme.textGray),
              filled: true,
              fillColor: AppTheme.cardGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final chapters = int.tryParse(value);
              if (chapters != null && chapters >= 0) {
                setState(() {
                  _filters = _filters.copyWith(chaptersMax: chapters);
                });
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdultContentToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _filters.includeAdultContent 
              ? AppTheme.accentRed.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: _filters.includeAdultContent 
                ? AppTheme.accentRed 
                : AppTheme.textGray,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adult Content (18+)',
                  style: TextStyle(
                    color: _filters.includeAdultContent 
                        ? AppTheme.textWhite 
                        : AppTheme.textGray,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _filters.includeAdultContent
                      ? 'Showing adult content in results'
                      : 'Adult content is hidden by default',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _filters.includeAdultContent,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(includeAdultContent: value);
              });
            },
            activeColor: AppTheme.accentRed,
            activeTrackColor: AppTheme.accentRed.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
