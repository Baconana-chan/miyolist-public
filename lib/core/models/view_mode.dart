enum ViewMode {
  grid,
  list,
  compact;

  String get label {
    switch (this) {
      case ViewMode.grid:
        return 'Grid';
      case ViewMode.list:
        return 'List';
      case ViewMode.compact:
        return 'Compact';
    }
  }

  String get description {
    switch (this) {
      case ViewMode.grid:
        return 'Card-based grid layout';
      case ViewMode.list:
        return 'Detailed list with large cards';
      case ViewMode.compact:
        return 'Condensed list for more items';
    }
  }

  String toHiveValue() {
    return name;
  }

  static ViewMode fromHiveValue(String value) {
    return ViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ViewMode.grid,
    );
  }
}
