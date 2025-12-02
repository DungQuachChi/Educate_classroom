import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final String studentId;
  final String instructorId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;
  final int unreadCount; // Unread messages for current user
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.studentId,
    required this.instructorId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageSenderId,
    this.unreadCount = 0,
    required this.createdAt,
  });

  // Generate conversation ID from student and instructor IDs
  static String generateId(String studentId, String instructorId) {
    // Always put student ID first for consistency
    return '${studentId}_$instructorId';
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'instructorId': instructorId,
      'lastMessage': lastMessage,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount_$studentId': 0,
      'unreadCount_$instructorId': 0,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory ConversationModel.fromMap(Map<String, dynamic> map, String id, String currentUserId) {
    return ConversationModel(
      id: id,
      studentId: map['studentId'] ?? '',
      instructorId: map['instructorId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp).toDate(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      unreadCount: map['unreadCount_$currentUserId'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == studentId ? instructorId : studentId;
  }

  ConversationModel copyWith({
    String? id,
    String? studentId,
    String? instructorId,
    String? lastMessage,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      studentId: studentId ?? this. studentId,
      instructorId: instructorId ?? this.instructorId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this. lastMessageSenderId,
      unreadCount: unreadCount ??  this.unreadCount,
      createdAt: createdAt ??  this.createdAt,
    );
  }
}