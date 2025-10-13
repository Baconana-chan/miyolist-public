import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'kaomoji_state.dart';

/// Enhanced empty state widget with customizable icon, title, description and action
class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? iconColor;
  final bool useKaomoji;

  const EmptyStateWidget({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onActionPressed,
    this.iconColor,
    this.useKaomoji = true, // По умолчанию используем каомодзи
  });

  /// Empty state for no search results
  factory EmptyStateWidget.noSearchResults({
    required String query,
    required VoidCallback onClearSearch,
  }) {
    return EmptyStateWidget(
      title: 'No results found',
      description: 'No entries match "$query".\nTry adjusting your search or filters.',
      actionLabel: 'Clear Search',
      onActionPressed: onClearSearch,
    );
  }

  /// Empty state for no entries in a status filter
  factory EmptyStateWidget.noEntriesInStatus({
    required String statusName,
    required bool isAnime,
  }) {
    final mediaType = isAnime ? 'anime' : 'manga';
    return EmptyStateWidget(
      title: 'No $mediaType in $statusName',
      description: 'Add some $mediaType to your list to see them here.',
    );
  }

  /// Empty state for no entries at all (new user)
  factory EmptyStateWidget.noEntriesAtAll({
    required bool isAnime,
  }) {
    final mediaType = isAnime ? 'anime' : 'manga';
    return EmptyStateWidget(
      title: 'Your $mediaType list is empty',
      description: 'Start tracking your favorite $mediaType!\nSearch and add entries to get started.',
    );
  }

  /// Empty state for filtered results (no matches)
  factory EmptyStateWidget.noFilterResults({
    required VoidCallback onClearFilters,
  }) {
    return EmptyStateWidget(
      title: 'No matches found',
      description: 'Try adjusting your filters to see more results.',
      actionLabel: 'Clear Filters',
      onActionPressed: onClearFilters,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Если нужен каомодзи вместо иконки
    if (useKaomoji) {
      return KaomojiState(
        type: KaomojiType.empty,
        message: title,
        subtitle: description,
        action: (actionLabel != null && onActionPressed != null)
            ? OutlinedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.clear),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                  side: const BorderSide(color: AppTheme.accentBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            : null,
      );
    }

    // Старый вариант с иконкой (если useKaomoji = false)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            if (icon != null)
              Icon(
                icon,
                size: 80,
                color: iconColor ?? AppTheme.textGray,
              ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            
            // Description
            if (description != null) ...[
              const SizedBox(height: 12),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGray,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action button
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.clear),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                  side: const BorderSide(color: AppTheme.accentBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
