import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final List<String> attachmentUrls;
  final List<String> attachmentNames;

  MessageModel({
    required this.id,
    required this. conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this. sentAt,
    this.isRead = false,
    this.attachmentUrls = const [],
    this.attachmentNames = const [],
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
    };
  }

  // Create from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      attachmentNames: List<String>.from(map['attachmentNames'] ?? []),
    );
  }

  MessageModel copyWith({
    String?  id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ??  this.isRead,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      attachmentNames: attachmentNames ?? this.attachmentNames,
    );
  }
}