/// Filter and sort options for media list
class ListFilters {
  // Format filter
  final Set<String> formats;
  
  // Media status filter (FINISHED, RELEASING, NOT_YET_RELEASED, CANCELLED, HIATUS)
  final Set<String> mediaStatuses;
  
  // Genre filter
  final Set<String> genres;
  
  // Country filter (JP, CN, KR, TW)
  final Set<String> countries;
  
  // Custom lists filter
  final Set<String> customLists;
  
  // Year range filter
  final int? startYear;
  final int? endYear;
  
  // Sort option
  final SortOption sortOption;
  
  // Sort direction
  final bool ascending;

  const ListFilters({
    this.formats = const {},
    this.mediaStatuses = const {},
    this.genres = const {},
    this.countries = const {},
    this.customLists = const {},
    this.startYear,
    this.endYear,
    this.sortOption = SortOption.title,
    this.ascending = true,
  });

  ListFilters copyWith({
    Set<String>? formats,
    Set<String>? mediaStatuses,
    Set<String>? genres,
    Set<String>? countries,
    Set<String>? customLists,
    int? startYear,
    int? endYear,
    SortOption? sortOption,
    bool? ascending,
  }) {
    return ListFilters(
      formats: formats ?? this.formats,
      mediaStatuses: mediaStatuses ?? this.mediaStatuses,
      genres: genres ?? this.genres,
      countries: countries ?? this.countries,
      customLists: customLists ?? this.customLists,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      sortOption: sortOption ?? this.sortOption,
      ascending: ascending ?? this.ascending,
    );
  }

  bool get hasActiveFilters {
    return formats.isNotEmpty ||
        mediaStatuses.isNotEmpty ||
        genres.isNotEmpty ||
        countries.isNotEmpty ||
        customLists.isNotEmpty ||
        startYear != null ||
        endYear != null;
  }

  void reset() {}
}

enum SortOption {
  title('Title'),
  score('My Score'),
  progress('Progress'),
  lastUpdated('Last Updated'),
  lastAdded('Last Added'),
  startDate('My Start Date'),
  completedDate('My Completed Date'),
  releaseDate('Release Date'),
  averageScore('Average Score'),
  popularity('Popularity');

  final String label;
  const SortOption(this.label);
}

/// Available anime formats
class AnimeFormats {
  static const String tv = 'TV';
  static const String tvShort = 'TV_SHORT';
  static const String movie = 'MOVIE';
  static const String special = 'SPECIAL';
  static const String ova = 'OVA';
  static const String ona = 'ONA';
  static const String music = 'MUSIC';

  static const List<String> all = [
    tv,
    tvShort,
    movie,
    special,
    ova,
    ona,
    music,
  ];

  static String getDisplayName(String format) {
    switch (format) {
      case tvShort:
        return 'TV Short';
      default:
        return format.replaceAll('_', ' ');
    }
  }
}

/// Available manga formats
class MangaFormats {
  static const String manga = 'MANGA';
  static const String oneShot = 'ONE_SHOT';

  static const List<String> all = [
    manga,
    oneShot,
  ];

  static String getDisplayName(String format) {
    switch (format) {
      case oneShot:
        return 'One Shot';
      default:
        return format.replaceAll('_', ' ');
    }
  }
}

/// Available novel formats
class NovelFormats {
  static const String novel = 'NOVEL';

  static const List<String> all = [
    novel,
  ];

  static String getDisplayName(String format) {
    return format.replaceAll('_', ' ');
  }
}

/// Media airing status
class MediaStatus {
  static const String finished = 'FINISHED';
  static const String releasing = 'RELEASING';
  static const String notYetReleased = 'NOT_YET_RELEASED';
  static const String cancelled = 'CANCELLED';
  static const String hiatus = 'HIATUS';

  static const List<String> all = [
    finished,
    releasing,
    notYetReleased,
    cancelled,
    hiatus,
  ];

  static String getDisplayName(String status) {
    switch (status) {
      case notYetReleased:
        return 'Not Yet Released';
      default:
        return status.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }
}

/// Countries of origin
class Countries {
  static const String japan = 'JP';
  static const String china = 'CN';
  static const String southKorea = 'KR';
  static const String taiwan = 'TW';

  static const List<String> all = [
    japan,
    china,
    southKorea,
    taiwan,
  ];

  static String getDisplayName(String country) {
    switch (country) {
      case japan:
        return 'Japan';
      case china:
        return 'China';
      case southKorea:
        return 'South Korea';
      case taiwan:
        return 'Taiwan';
      default:
        return country;
    }
  }

  static String getFlag(String country) {
    switch (country) {
      case japan:
        return '🇯🇵';
      case china:
        return '🇨🇳';
      case southKorea:
        return '🇰🇷';
      case taiwan:
        return '🇹🇼';
      default:
        return '';
    }
  }
}
