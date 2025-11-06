import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'instructor' or 'student'
  final String? avatarUrl;
  final String? studentId;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.studentId,
    required this.createdAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'avatarUrl': avatarUrl,
      'studentId': studentId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? '',
      avatarUrl: map['avatarUrl'],
      studentId: map['studentId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Check if user is instructor
  bool get isInstructor => role == 'instructor';
  
  // Check if user is student
  bool get isStudent => role == 'student';
}