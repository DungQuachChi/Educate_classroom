import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementCommentModel {
  final String id;
  final String announcementId;
  final String userId;
  final String userName;
  final String userRole; // instructor or student
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AnnouncementCommentModel({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'announcementId': announcementId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory AnnouncementCommentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AnnouncementCommentModel(
      id: documentId,
      announcementId: map['announcementId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  AnnouncementCommentModel copyWith({
    String? id,
    String? announcementId,
    String? userId,
    String? userName,
    String? userRole,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementCommentModel(
      id: id ?? this.id,
      announcementId: announcementId ?? this.announcementId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}