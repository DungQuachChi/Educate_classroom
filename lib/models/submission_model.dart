import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content; // Text submission
  final List<String> attachmentUrls; // File submissions
  final DateTime submittedAt;
  final int? score;
  final String? feedback;
  final DateTime? gradedAt;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.attachmentUrls = const [],
    required this.submittedAt,
    this.score,
    this.feedback,
    this.gradedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'content': content,
      'attachmentUrls': attachmentUrls,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'score': score,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
    };
  }

  // Create from Firestore document
  factory SubmissionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubmissionModel(
      id: documentId,
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      content: map['content'],
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      score: map['score'],
      feedback: map['feedback'],
      gradedAt: map['gradedAt'] != null 
          ? (map['gradedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Copy with method
  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? content,
    List<String>? attachmentUrls,
    DateTime? submittedAt,
    int? score,
    String? feedback,
    DateTime? gradedAt,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }
  bool get isGraded => score != null;

  bool isLate(DateTime dueDate) => submittedAt.isAfter(dueDate);
}