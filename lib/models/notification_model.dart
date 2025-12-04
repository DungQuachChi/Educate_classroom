import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  announcement,
  assignmentDeadline,
  quizDeadline,
  assignmentGraded,
  quizGraded,
  assignmentSubmitted,
  quizSubmitted,
  message,
  other,
}

class NotificationModel {
  final String id;
  final String userId; // Student ID
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // ID of related document (assignment, quiz, etc.)
  final String? relatedType; // Type of related document
  final String? actionUrl; // Optional: where to navigate when clicked

  NotificationModel({
    required this.id,
    required this.userId,
    required this. type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
    this.relatedType,
    this.actionUrl,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString(). split('.').last,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'actionUrl': actionUrl,
    };
  }

  // Create from Firestore document
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ??  '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.'). last == map['type'],
        orElse: () => NotificationType.other,
      ),
      title: map['title'] ??  '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ??  false,
      relatedId: map['relatedId'],
      relatedType: map['relatedType'],
      actionUrl: map['actionUrl'],
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String?  message,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
    String? relatedType,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  // Get icon based on type
  String getIcon() {
    switch (type) {
      case NotificationType.announcement:
        return '📢';
      case NotificationType.assignmentDeadline:
      case NotificationType.assignmentGraded:
      case NotificationType.assignmentSubmitted:
        return '📝';
      case NotificationType. quizDeadline:
      case NotificationType.quizGraded:
      case NotificationType.quizSubmitted:
        return '📊';
      case NotificationType. message:
        return '💬';
      default:
        return '🔔';
    }
  }

  // Get color based on type
  String getColorHex() {
    switch (type) {
      case NotificationType.announcement:
        return '#9C27B0'; // Purple
      case NotificationType.assignmentDeadline:
      case NotificationType.quizDeadline:
        return '#F44336'; // Red
      case NotificationType.assignmentGraded:
      case NotificationType.quizGraded:
        return '#4CAF50'; // Green
      case NotificationType.assignmentSubmitted:
      case NotificationType.quizSubmitted:
        return '#2196F3'; // Blue
      case NotificationType.message:
        return '#00BCD4'; // Cyan
      default:
        return '#757575'; // Gray
    }
  }
}