import 'package:cloud_firestore/cloud_firestore.dart';

class ForumReplyModel {
  final String id;
  final String forumId;
  final String?  parentReplyId; // null for top-level replies
  final String content;
  final String createdBy;
  final DateTime createdAt;
  final DateTime?  updatedAt;
  final List<String> attachmentUrls;
  final List<String> attachmentNames;
  final int level; // 0 = top-level, 1 = nested reply, etc.

  ForumReplyModel({
    required this.id,
    required this.forumId,
    this.parentReplyId,
    required this. content,
    required this.createdBy,
    required this. createdAt,
    this. updatedAt,
    this.attachmentUrls = const [],
    this.attachmentNames = const [],
    this.level = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'forumId': forumId,
      'parentReplyId': parentReplyId,
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ?  Timestamp.fromDate(updatedAt!) : null,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
      'level': level,
    };
  }

  factory ForumReplyModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ForumReplyModel(
      id: documentId,
      forumId: map['forumId'] ??  '',
      parentReplyId: map['parentReplyId'],
      content: map['content'] ??  '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp). toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      attachmentNames: List<String>. from(map['attachmentNames'] ?? []),
      level: map['level'] ?? 0,
    );
  }

  ForumReplyModel copyWith({
    String? id,
    String? forumId,
    String? parentReplyId,
    String? content,
    String?  createdBy,
    DateTime?  createdAt,
    DateTime?  updatedAt,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
    int? level,
  }) {
    return ForumReplyModel(
      id: id ?? this.id,
      forumId: forumId ?? this.forumId,
      parentReplyId: parentReplyId ?? this.parentReplyId,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      attachmentNames: attachmentNames ?? this.attachmentNames,
      level: level ?? this. level,
    );
  }
}