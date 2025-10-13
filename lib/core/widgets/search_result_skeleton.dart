import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'shimmer_loading.dart';

/// A skeleton loading widget for search result cards
class SearchResultSkeleton extends StatelessWidget {
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cover image skeleton
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title line 1
                  Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Title line 2
                  Container(
                    height: 16,
                    width: double.infinity * 0.7,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Info line 1
                  Container(
                    height: 12,
                    width: double.infinity * 0.5,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Info line 2
                  Container(
                    height: 12,
                    width: double.infinity * 0.6,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Info line 3
                  Container(
                    height: 12,
                    width: double.infinity * 0.4,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
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
}

/// A list of search result skeletons
class SearchResultListSkeleton extends StatelessWidget {
  final int itemCount;

  const SearchResultListSkeleton({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SearchResultSkeleton(),
    );
  }
}
