import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      child: Container(
        width: screenWidth > 800 ? 700 : screenWidth * 0.9,
        height: screenHeight * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accentRed.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'About MiyoList',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Version v1.1.0 "Botan (牡丹)"',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    _buildSection(
                      title: '📱 Description',
                      content: 'MiyoList is a powerful anime and manga tracking application that helps you manage your watchlist, discover new content, sync your progress across devices, and stay updated with the latest releases. Features include intelligent search, activity feed with airing schedules, privacy controls, statistics tracking, crash reporting, and automatic app updates.',
                    ),

                    const SizedBox(height: 24),

                    // What's New in v1.1.0 "Botan (牡丹)"
                    _buildSection(
                      title: '� What\'s New in v1.1.0 "Botan (牡丹)"',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            '� Social Features - Following System',
                            'Follow other users, view their public profiles, stats, and favorites. Browse Following/Followers lists, see activity feed from people you follow, and check who\'s watching the same anime!',
                          ),
                          _buildFeatureItem(
                            '🤝 Friend System',
                            'Mutual follow detection with 3-tab interface: Friends (mutual), Requests (incoming), and Pending (outgoing). Accept friend requests and manage connections easily!',
                          ),
                          _buildFeatureItem(
                            '� Activity Interactions',
                            'Like and reply to activities from following users. Post your own text activities with Markdown formatting. See AniList Guidelines link to avoid violations!',
                          ),
                          _buildFeatureItem(
                            '🎖️ Donator Badges',
                            '4-tier badge system with animated rainbow effect for tier 4 supporters. Badges appear in profiles, activity feeds, and friend lists.',
                          ),
                          _buildFeatureItem(
                            '� Offline Content Settings',
                            'Full control over what to cache: Lists, Favorites, Characters, Staff, Banners, Trending, Search. Choose your offline priorities and save storage!',
                          ),
                          _buildFeatureItem(
                            '☕ Java 17 Upgrade',
                            'Updated Android build to Java 17 (LTS until 2029). No more Java 8 warnings, better performance, and faster release builds!',
                          ),
                          _buildFeatureItem(
                            '� Push Notifications (Enhanced)',
                            'Windows desktop notifications for airing episodes, interactive actions (Mark Watched, Snooze, Add to Planning), and smart timing control.',
                          ),
                          _buildFeatureItem(
                            '🐛 Bug Fixes',
                            'Fixed zonedSchedule on Windows, reduced API requests on startup, improved AniList client initialization, and better error handling.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // What's New in v1.0.0 "Aoi (葵)"
                    _buildSection(
                      title: '🎉 Previous Release - v1.0.0 "Aoi (葵)"',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            '� Activity Feed & Airing Schedule',
                            'Stay up-to-date with today\'s releases, upcoming episodes, and real-time countdown timers. Auto-refreshes every minute!',
                          ),
                          _buildFeatureItem(
                            '� Advanced Global Search',
                            'Search across anime, manga, characters, staff, and studios with powerful filters including adult content toggle, format filters, and genre selection.',
                          ),
                          _buildFeatureItem(
                            '🔒 Privacy & Profile Controls',
                            'Full control over your profile visibility with public/private mode, custom tab visibility, and granular sync settings.',
                          ),
                          _buildFeatureItem(
                            '� Statistics & Analytics',
                            'Comprehensive stats tracking: watch time, episode counts, genre distribution, format breakdown, score analytics, and completion rates.',
                          ),
                          _buildFeatureItem(
                            '� Crash Reporting System',
                            'Automatic crash detection with detailed logs, privacy-focused reporting, and session tracking for improved stability.',
                          ),
                          _buildFeatureItem(
                            '� App Update System',
                            'Automatic update checks, changelog display, download links, reminder intervals, and manual check support via GitHub releases.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Special Thanks
                    _buildSection(
                      title: '💝 Special Thanks',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLinkItem(
                            'AniList',
                            'For providing the comprehensive anime/manga database and GraphQL API',
                            'https://anilist.co',
                          ),
                          _buildLinkItem(
                            'Flutter Team',
                            'For creating an amazing cross-platform framework',
                            'https://flutter.dev',
                          ),
                          _buildLinkItem(
                            'Supabase',
                            'For backend services and real-time database',
                            'https://supabase.com',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Art & Design Credits
                    _buildSection(
                      title: '🎨 Art & Design Credits',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLinkItem(
                            'Adorableninana',
                            'Cute cat stickers for AI Companion feature - "Cute Funny Orange Cat Illustration Sticker Set"',
                            'https://www.flaticon.com/stickers-pack/cute-funny-orange-cat-illustration-sticker-set',
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 12, top: 8),
                            child: Text(
                              'These adorable cat stickers will be used in future versions for the AI Companion feature, bringing personality and fun interactions to the app!',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGray,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Technologies & Services
                    _buildSection(
                      title: '🛠️ Technologies & Services',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTechCategory('Framework & Language', [
                            'Flutter 3.35.5 - UI framework (BSD 3-Clause)',
                            'Dart 3.9.2 - Programming language (BSD 3-Clause)',
                          ]),
                          const SizedBox(height: 16),
                          _buildTechCategory('Backend Services', [
                            'AniList GraphQL API - Anime/Manga database',
                            'Supabase - Authentication & Cloud sync (Apache 2.0)',
                            'Hive - Local NoSQL database (Apache 2.0)',
                          ]),
                          const SizedBox(height: 16),
                          _buildTechCategory('Key Packages', [
                            'graphql_flutter - GraphQL client (MIT)',
                            'supabase_flutter - Supabase SDK',
                            'hive & hive_flutter - Local storage',
                            'cached_network_image - Image caching',
                            'flutter_markdown - Markdown rendering',
                            'flutter_widget_from_html - HTML rendering',
                            'url_launcher - External links',
                            'google_fonts - Custom fonts',
                            'dio - HTTP client',
                            'intl - Date/number formatting',
                            'flutter_bloc - State management',
                            'package_info_plus - App version info',
                            'path_provider - File system paths',
                            'shared_preferences - Key-value storage',
                            'fl_chart - Statistics charts',
                            'flutter_local_notifications - Push notifications',
                          ]),
                          const SizedBox(height: 16),
                          _buildTechCategory('Architecture & Patterns', [
                            'Clean Architecture principles',
                            'Feature-first folder structure',
                            'Service layer pattern',
                            'Three-tier caching (Hive → Supabase → AniList)',
                            'Rate limiting for API protection',
                            'Offline-first approach',
                          ]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // License
                    _buildSection(
                      title: '📄 License',
                      content: 'MIT License\n\n'
                          'Copyright (c) 2025 MiyoList Contributors\n\n'
                          'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction...\n\n'
                          'See full license text in the project repository.',
                    ),

                    const SizedBox(height: 24),

                    // Disclaimer
                    _buildSection(
                      title: '⚠️ Disclaimer',
                      content: 'This is an unofficial client for AniList. It is not affiliated with, endorsed by, or connected to AniList in any way.\n\n'
                          'This application is provided "as is" without warranty of any kind. Use at your own risk.',
                    ),

                    const SizedBox(height: 24),

                    // Developer Info
                    _buildSection(
                      title: '👨‍💻 Developer',
                      content: 'Built with ❤️ by Baconana-chan',
                    ),

                    const SizedBox(height: 24),

                    // Links
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildActionButton(
                            context: context,
                            icon: Icons.code,
                            label: 'View Source',
                            onPressed: () => _launchURL('https://github.com/Baconana-chan/miyolist-public'),
                          ),
                          _buildActionButton(
                            context: context,
                            icon: Icons.bug_report,
                            label: 'Report Issue',
                            onPressed: () => _launchURL('https://github.com/Baconana-chan/miyolist-public/issues'),
                          ),
                          _buildActionButton(
                            context: context,
                            icon: Icons.download,
                            label: 'Download Updates',
                            onPressed: () => _launchURL('https://github.com/Baconana-chan/miyolist-public/releases'),
                          ),
                        ],
                      ),
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

  Widget _buildSection({
    required String title,
    String? content,
    Widget? child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textGray,
              height: 1.5,
            ),
          ),
        if (child != null) child,
      ],
    );
  }

  Widget _buildLinkItem(String title, String description, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new,
                size: 20,
                color: AppTheme.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.accentRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechCategory(String category, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '• ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.accentRed,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textWhite,
        side: const BorderSide(color: AppTheme.accentRed),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
