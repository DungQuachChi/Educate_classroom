import 'package:cloud_firestore/cloud_firestore.dart';

class ForumModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime?  updatedAt;
  final bool isPinned;
  final bool isLocked;
  final List<String> tags;
  final List<String> attachmentUrls;
  final List<String> attachmentNames;
  final int replyCount;
  final DateTime lastActivityAt;
  final String lastActivityBy;

  ForumModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.tags = const [],
    this.attachmentUrls = const [],
    this. attachmentNames = const [],
    this.replyCount = 0,
    required this.lastActivityAt,
    required this.lastActivityBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPinned': isPinned,
      'isLocked': isLocked,
      'tags': tags,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
      'replyCount': replyCount,
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'lastActivityBy': lastActivityBy,
    };
  }

  factory ForumModel. fromMap(Map<String, dynamic> map, String documentId) {
    return ForumModel(
      id: documentId,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ??  '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isPinned: map['isPinned'] ?? false,
      isLocked: map['isLocked'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      attachmentUrls: List<String>.from(map['attachmentUrls'] ??  []),
      attachmentNames: List<String>.from(map['attachmentNames'] ?? []),
      replyCount: map['replyCount'] ?? 0,
      lastActivityAt: (map['lastActivityAt'] as Timestamp). toDate(),
      lastActivityBy: map['lastActivityBy'] ??  '',
    );
  }

  ForumModel copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isLocked,
    List<String>? tags,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
    int? replyCount,
    DateTime? lastActivityAt,
    String? lastActivityBy,
  }) {
    return ForumModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this. title,
      description: description ??  this.description,
      createdBy: createdBy ?? this. createdBy,
      createdAt: createdAt ?? this. createdAt,
      updatedAt: updatedAt ?? this. updatedAt,
      isPinned: isPinned ?? this. isPinned,
      isLocked: isLocked ?? this. isLocked,
      tags: tags ?? this.tags,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      attachmentNames: attachmentNames ?? this.attachmentNames,
      replyCount: replyCount ?? this.replyCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      lastActivityBy: lastActivityBy ?? this.lastActivityBy,
    );
  }
}