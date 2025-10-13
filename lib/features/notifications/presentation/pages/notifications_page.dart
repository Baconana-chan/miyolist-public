import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/notification.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/anilist_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/kaomoji_widget.dart';
import '../../../media_details/presentation/pages/media_details_page.dart';

class NotificationsPage extends StatefulWidget {
  final AniListService anilistService;
  final LocalStorageService localStorageService;
  final SupabaseService supabaseService;

  const NotificationsPage({
    Key? key,
    required this.anilistService,
    required this.localStorageService,
    required this.supabaseService,
  }) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationService _notificationService;
  
  final List<NotificationType?> _categories = [
    null, // All
    NotificationType.airing,
    NotificationType.activity,
    NotificationType.forum,
    NotificationType.follows,
    NotificationType.media,
  ];
  
  List<AniListNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    final token = await widget.anilistService.authService.getAccessToken();
    if (token != null) {
      _notificationService = NotificationService(
        token,
        widget.localStorageService.settingsBox,
      );
      await _loadNotifications();
      await _loadUnreadCount();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final type = _categories[_tabController.index];
      final notifications = await _notificationService.getNotifications(
        type: type,
        page: 1,
        perPage: 50,
      );

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (!mounted) return;

      setState(() {
        _unreadCount = count;
      });
    } catch (e) {
      // Ignore error for unread count
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accentBlue,
          labelColor: AppTheme.textWhite,
          unselectedLabelColor: AppTheme.textGray,
          onTap: (_) => _loadNotifications(),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Airing'),
            Tab(text: 'Activity'),
            Tab(text: 'Forum'),
            Tab(text: 'Follows'),
            Tab(text: 'Media'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const KaomojiLoader(message: 'Loading notifications...');
    }

    if (_errorMessage != null) {
      return KaomojiError(
        message: _errorMessage ?? 'Something went wrong',
        onRetry: _loadNotifications,
      );
    }

    if (_notifications.isEmpty) {
      return const KaomojiEmpty(message: 'No notifications\nYou\'re all caught up!');
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.accentBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(AniListNotification notification) {
    return Card(
      color: AppTheme.cardGray,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : const BorderSide(color: AppTheme.accentBlue, width: 2),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.coverImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: notification.coverImage!,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.borderGray,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.borderGray,
                      child: const Icon(Icons.error, color: AppTheme.textGray),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.getTitle(),
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.getText(),
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(AniListNotification notification) async {
    // Отметить как прочитанное
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        notification.isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      });
    }

    // Обработать навигацию
    if (notification.mediaId != null) {
      // Открыть страницу медиа в приложении
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailsPage(
            mediaId: notification.mediaId!,
            anilistService: widget.anilistService,
            localStorageService: widget.localStorageService,
            supabaseService: widget.supabaseService,
          ),
        ),
      );
    } else if (notification.url != null) {
      // Открыть в браузере (для форума, профилей и т.д.)
      final uri = Uri.parse(notification.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
