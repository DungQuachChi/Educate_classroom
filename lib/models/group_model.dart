import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String courseId;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.courseId,
    this.studentIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'courseId': courseId,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory GroupModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupModel(
      id: documentId,
      name: map['name'] ?? '',
      courseId: map['courseId'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Create from CSV row (name, courseId)
  factory GroupModel.fromCsv(List<dynamic> row, String courseId) {
    return GroupModel(
      id: '',
      name: row[0].toString().trim(),
      courseId: courseId,
      createdAt: DateTime.now(),
    );
  }

  // Copy with method
  GroupModel copyWith({
    String? id,
    String? name,
    String? courseId,
    List<String>? studentIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      courseId: courseId ?? this.courseId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get student count
  int get studentCount => studentIds.length;
}