import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String code;
  final String name;
  final int sessions; // 10 or 15
  final String semesterId;
  final String? coverImage;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.sessions,
    required this.semesterId,
    this.coverImage,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'sessions': sessions,
      'semesterId': semesterId,
      'coverImage': coverImage,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore document
  factory CourseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CourseModel(
      id: documentId,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      sessions: map['sessions'] ?? 10,
      semesterId: map['semesterId'] ?? '',
      coverImage: map['coverImage'],
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Create from CSV row (code, name, sessions, semesterId)
  factory CourseModel.fromCsv(List<dynamic> row, String semesterId) {
    return CourseModel(
      id: '',
      code: row[0].toString().trim(),
      name: row[1].toString().trim(),
      sessions: int.tryParse(row[2].toString()) ?? 10,
      semesterId: semesterId,
      createdAt: DateTime.now(),
    );
  }

  // Copy with method
  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    int? sessions,
    String? semesterId,
    String? coverImage,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      sessions: sessions ?? this.sessions,
      semesterId: semesterId ?? this.semesterId,
      coverImage: coverImage ?? this.coverImage,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}