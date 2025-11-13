import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final String? groupId; // Optional: assign to specific group
  final DateTime dueDate;
  final int maxScore;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    this.groupId,
    required this.dueDate,
    this.maxScore = 100,
    this.attachmentUrls = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'courseId': courseId,
      'groupId': groupId,
      'dueDate': Timestamp.fromDate(dueDate),
      'maxScore': maxScore,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory AssignmentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AssignmentModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      courseId: map['courseId'] ?? '',
      groupId: map['groupId'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      maxScore: map['maxScore'] ?? 100,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copy with method
  AssignmentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? groupId,
    DateTime? dueDate,
    int? maxScore,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      groupId: groupId ?? this.groupId,
      dueDate: dueDate ?? this.dueDate,
      maxScore: maxScore ?? this.maxScore,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if assignment is overdue
  bool get isOverdue => DateTime.now().isAfter(dueDate);

  // Check if assignment is due soon (within 24 hours)
  bool get isDueSoon {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inHours <= 24 && difference.inHours > 0;
  }
}