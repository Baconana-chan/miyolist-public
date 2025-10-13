import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'shimmer_loading.dart';

/// A skeleton loading widget that mimics the appearance of a MediaListCard
class MediaCardSkeleton extends StatelessWidget {
  const MediaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image skeleton
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlack,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
            ),
            
            // Text content skeleton
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title line 1
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Title line 2 (shorter)
                  Container(
                    height: 12,
                    width: double.infinity * 0.7,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress/info line
                  Container(
                    height: 10,
                    width: double.infinity * 0.5,
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

/// A grid of skeleton cards for loading state
class MediaGridSkeleton extends StatelessWidget {
  final int itemCount;

  const MediaGridSkeleton({
    super.key,
    this.itemCount = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.67,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const MediaCardSkeleton(),
    );
  }
}
