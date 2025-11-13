import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final List<String> attachmentUrls;
  final DateTime submittedAt;
  final int attemptNumber; 
  final bool isLate; 
  final int? score;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy; 

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.attachmentUrls = const [],
    required this.submittedAt,
    this.attemptNumber = 1,
    this.isLate = false,
    this.score,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'content': content,
      'attachmentUrls': attachmentUrls,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'attemptNumber': attemptNumber,
      'isLate': isLate,
      'score': score,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'gradedBy': gradedBy,
    };
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubmissionModel(
      id: documentId,
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      content: map['content'],
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      attemptNumber: map['attemptNumber'] ?? 1,
      isLate: map['isLate'] ?? false,
      score: map['score'],
      feedback: map['feedback'],
      gradedAt: map['gradedAt'] != null 
          ? (map['gradedAt'] as Timestamp).toDate() 
          : null,
      gradedBy: map['gradedBy'],
    );
  }

  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? content,
    List<String>? attachmentUrls,
    DateTime? submittedAt,
    int? attemptNumber,
    bool? isLate,
    int? score,
    String? feedback,
    DateTime? gradedAt,
    String? gradedBy,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      submittedAt: submittedAt ?? this.submittedAt,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      isLate: isLate ?? this.isLate,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
    );
  }

  bool get isGraded => score != null;
}