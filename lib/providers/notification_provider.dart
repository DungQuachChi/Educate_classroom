import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

class NotificationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String?  _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get unread notifications
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get read notifications
  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  // Load notifications stream
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _databaseService.getNotifications(userId);
  }

  // Load unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _databaseService.getUnreadNotificationCount(userId);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _databaseService.markNotificationAsRead(notificationId);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      _setLoading(true);
      await _databaseService.markAllNotificationsAsRead(userId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _databaseService.deleteNotification(notificationId);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Delete all read notifications
  Future<void> deleteAllRead(String userId) async {
    try {
      _setLoading(true);
      await _databaseService.deleteReadNotifications(userId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String?  value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}