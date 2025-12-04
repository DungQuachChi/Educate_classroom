import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final userId = authProvider.user?.uid ??  '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<int>(
            stream: notificationProvider.getUnreadCountStream(userId),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              if (unreadCount == 0) return const SizedBox();

              return TextButton. icon(
                onPressed: () async {
                  await notificationProvider.markAllAsRead(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.done_all, color: Colors.white),
                label: const Text('Mark all read', style: TextStyle(color: Colors.white)),
              );
            },
          ),
          // Delete read notifications
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_read') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Read Notifications'),
                    content: const Text('Are you sure you want to delete all read notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await notificationProvider.deleteAllRead(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Read notifications deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 8),
                    Text('Delete read'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationProvider.getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot. hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be notified about important events here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Group by read/unread
          final unread = notifications. where((n) => !n. isRead).toList();
          final read = notifications.where((n) => n.isRead).toList();

          return ListView(
            children: [
              // Unread section
              if (unread.isNotEmpty) ...[
                _SectionHeader(
                  title: 'New',
                  count: unread.length,
                ),
                ...unread.map((notification) => _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification, notificationProvider),
                  onDelete: () => _deleteNotification(context, notification, notificationProvider),
                )),
              ],

              // Read section
              if (read.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Earlier',
                  count: read. length,
                ),
                ... read.map((notification) => _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification, notificationProvider),
                  onDelete: () => _deleteNotification(context, notification, notificationProvider),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    // Mark as read
    if (! notification.isRead) {
      await provider.markAsRead(notification. id);
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    try {
      await provider.deleteNotification(notification.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    }
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Notification Tile Widget
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this. notification,
    required this.onTap,
    required this. onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection. endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: notification.isRead ? Colors.white : Colors.blue. shade50,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getColor(notification),
            child: Text(
              notification.getIcon(),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors. grey[600]),
              ),
            ],
          ),
          trailing: ! notification.isRead
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Color _getColor(NotificationModel notification) {
    final hex = notification.getColorHex(). replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd'). format(dateTime);
    }
  }
}