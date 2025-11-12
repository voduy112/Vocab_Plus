import 'package:flutter/material.dart';
import '../../../core/models/notification.dart';
import '../repositories/notification_repository.dart';
import '../../decks/repositories/deck_repository.dart';
import '../../decks/views/deck_overview_screen.dart';
import 'notification_tile.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({super.key});

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final DeckRepository _deckRepository = DeckRepository();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _notificationRepository.getAllNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Đánh dấu notification là đã đọc
    if (notification.id != null && !notification.isRead) {
      await _notificationRepository.markAsRead(notification.id!);
      _loadNotifications();
    }

    // Nếu notification có deckId, điều hướng đến deck overview
    if (notification.deckId != null) {
      try {
        final deck = await _deckRepository.getDeckById(notification.deckId!);
        if (deck != null && deck.id != null && mounted) {
          // Đóng dialog trước
          Navigator.of(context).pop();

          // Điều hướng đến deck overview screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeckOverviewScreen(deck: deck),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy thông tin deck'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể tải thông tin deck: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Không có thông báo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn sẽ nhận được thông báo khi có cập nhật mới',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Dismissible(
          key: Key('notification_${notification.id ?? index}'),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Xóa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (direction) async {
            if (notification.id != null) {
              await _notificationRepository
                  .deleteNotification(notification.id!);
              _loadNotifications();
            }
          },
          child: NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          ),
        );
      },
    );
  }
}
