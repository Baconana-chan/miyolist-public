import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/list_filters.dart';

class FilterSortDialog extends StatefulWidget {
  final ListFilters initialFilters;
  final String mediaType; // 'anime', 'manga', or 'novel'
  final List<String> availableCustomLists; // All custom lists from entries

  const FilterSortDialog({
    super.key,
    required this.initialFilters,
    required this.mediaType,
    this.availableCustomLists = const [],
  });

  @override
  State<FilterSortDialog> createState() => _FilterSortDialogState();
}

class _FilterSortDialogState extends State<FilterSortDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Set<String> _selectedFormats;
  late Set<String> _selectedStatuses;
  late Set<String> _selectedGenres;
  late Set<String> _selectedCountries;
  late Set<String> _selectedCustomLists;
  late int? _startYear;
  late int? _endYear;
  late SortOption _sortOption;
  late bool _ascending;

  // Available genres (most popular ones)
  final List<String> _availableGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Horror',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize with current filters
    _selectedFormats = Set.from(widget.initialFilters.formats);
    _selectedStatuses = Set.from(widget.initialFilters.mediaStatuses);
    _selectedGenres = Set.from(widget.initialFilters.genres);
    _selectedCountries = Set.from(widget.initialFilters.countries);
    _selectedCustomLists = Set.from(widget.initialFilters.customLists);
    _startYear = widget.initialFilters.startYear;
    _endYear = widget.initialFilters.endYear;
    _sortOption = widget.initialFilters.sortOption;
    _ascending = widget.initialFilters.ascending;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedFormats.clear();
      _selectedStatuses.clear();
      _selectedGenres.clear();
      _selectedCountries.clear();
      _selectedCustomLists.clear();
      _startYear = null;
      _endYear = null;
      _sortOption = SortOption.title;
      _ascending = true;
    });
  }

  void _applyFilters() {
    final filters = ListFilters(
      formats: _selectedFormats,
      mediaStatuses: _selectedStatuses,
      genres: _selectedGenres,
      countries: _selectedCountries,
      customLists: _selectedCustomLists,
      startYear: _startYear,
      endYear: _endYear,
      sortOption: _sortOption,
      ascending: _ascending,
    );
    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Reset'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Filters'),
                Tab(text: 'Custom Lists'),
                Tab(text: 'Sort'),
                Tab(text: 'Year'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFiltersTab(),
                  _buildCustomListsTab(),
                  _buildSortTab(),
                  _buildYearTab(),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersTab() {
    // Determine format options based on media type
    final List<String> formatOptions;
    final String Function(String) formatDisplayName;
    
    switch (widget.mediaType) {
      case 'anime':
        formatOptions = AnimeFormats.all;
        formatDisplayName = AnimeFormats.getDisplayName;
        break;
      case 'manga':
        formatOptions = MangaFormats.all;
        formatDisplayName = MangaFormats.getDisplayName;
        break;
      case 'novel':
        formatOptions = NovelFormats.all;
        formatDisplayName = NovelFormats.getDisplayName;
        break;
      default:
        formatOptions = AnimeFormats.all;
        formatDisplayName = AnimeFormats.getDisplayName;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format filter
          _buildFilterSection(
            'Format',
            formatOptions,
            _selectedFormats,
            formatDisplayName,
          ),
          const SizedBox(height: 24),

          // Status filter
          _buildFilterSection(
            'Media Status',
            MediaStatus.all,
            _selectedStatuses,
            MediaStatus.getDisplayName,
          ),
          const SizedBox(height: 24),

          // Country filter
          _buildFilterSection(
            'Country',
            Countries.all,
            _selectedCountries,
            (country) => '${Countries.getFlag(country)} ${Countries.getDisplayName(country)}',
          ),
          const SizedBox(height: 24),

          // Genre filter
          _buildGenreFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    Set<String> selectedValues,
    String Function(String) getDisplayName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(getDisplayName(option)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                });
              },
              selectedColor: AppTheme.accentBlue.withOpacity(0.3),
              checkmarkColor: AppTheme.accentBlue,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenreFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genres ${_selectedGenres.isNotEmpty ? '(${_selectedGenres.length})' : ''}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableGenres.map((genre) {
            final isSelected = _selectedGenres.contains(genre);
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGenres.add(genre);
                  } else {
                    _selectedGenres.remove(genre);
                  }
                });
              },
              selectedColor: AppTheme.accentBlue.withOpacity(0.3),
              checkmarkColor: AppTheme.accentBlue,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomListsTab() {
    if (widget.availableCustomLists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.list_alt,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No Custom Lists',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create custom lists in entry editor\nto organize your collection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Custom Lists',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Show only entries in selected lists',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableCustomLists.map((listName) {
              final isSelected = _selectedCustomLists.contains(listName);
              return FilterChip(
                label: Text(listName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCustomLists.add(listName);
                    } else {
                      _selectedCustomLists.remove(listName);
                    }
                  });
                },
                selectedColor: AppTheme.accentBlue.withOpacity(0.3),
                checkmarkColor: AppTheme.accentBlue,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.accentBlue : Colors.white,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sort Direction',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text(_ascending ? 'Ascending (A-Z, 0-9)' : 'Descending (Z-A, 9-0)'),
          subtitle: Text(_ascending ? 'Lowest to Highest' : 'Highest to Lowest'),
          value: _ascending,
          onChanged: (value) {
            setState(() {
              _ascending = value;
            });
          },
          activeColor: AppTheme.accentBlue,
        ),
        const SizedBox(height: 24),
        const Text(
          'Sort By',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(option.label),
            value: option,
            groupValue: _sortOption,
            onChanged: (value) {
              setState(() {
                _sortOption = value!;
              });
            },
            activeColor: AppTheme.accentBlue,
          );
        }),
      ],
    );
  }

  Widget _buildYearTab() {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1940 + 2, // From 1940 to next year
      (index) => 1940 + index,
    ).reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Filter by Release Year',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Filter media released within a specific year range',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),

        // Start year
        ListTile(
          title: const Text('Start Year'),
          subtitle: Text(_startYear?.toString() ?? 'Any'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final year = await _showYearPicker(years, _startYear);
            if (year != null) {
              setState(() {
                _startYear = year;
                // Ensure end year is after start year
                if (_endYear != null && _endYear! < year) {
                  _endYear = year;
                }
              });
            }
          },
        ),
        const Divider(),

        // End year
        ListTile(
          title: const Text('End Year'),
          subtitle: Text(_endYear?.toString() ?? 'Any'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final year = await _showYearPicker(years, _endYear);
            if (year != null) {
              setState(() {
                _endYear = year;
                // Ensure start year is before end year
                if (_startYear != null && _startYear! > year) {
                  _startYear = year;
                }
              });
            }
          },
        ),
        const SizedBox(height: 24),

        if (_startYear != null || _endYear != null) ...[
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _startYear = null;
                _endYear = null;
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Year Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
            ),
          ),
        ],
      ],
    );
  }

  Future<int?> _showYearPicker(List<int> years, int? currentYear) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final isSelected = year == currentYear;
                return ListTile(
                  title: Text(
                    year.toString(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.accentBlue : null,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => Navigator.pop(context, year),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
