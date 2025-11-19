import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAnswer {
  final String questionId;
  final int selectedAnswerIndex;

  QuizAnswer({
    required this.questionId,
    required this.selectedAnswerIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
    };
  }

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      questionId: map['questionId'] ?? '',
      selectedAnswerIndex: map['selectedAnswerIndex'] ?? -1,
    );
  }
}

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final int attemptNumber;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final List<QuizAnswer> answers;
  final int? score; // Calculated score
  final int? totalQuestions;
  final bool isCompleted;
  final List<String> questionOrder; // Randomized order for this attempt

  QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.attemptNumber,
    required this.startedAt,
    this.submittedAt,
    this.answers = const [],
    this.score,
    this.totalQuestions,
    this.isCompleted = false,
    this.questionOrder = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'attemptNumber': attemptNumber,
      'startedAt': Timestamp.fromDate(startedAt),
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'answers': answers.map((a) => a.toMap()).toList(),
      'score': score,
      'totalQuestions': totalQuestions,
      'isCompleted': isCompleted,
      'questionOrder': questionOrder,
    };
  }

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map, String documentId) {
    return QuizAttemptModel(
      id: documentId,
      quizId: map['quizId'] ?? '',
      studentId: map['studentId'] ?? '',
      attemptNumber: map['attemptNumber'] ?? 1,
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      submittedAt: map['submittedAt'] != null 
          ? (map['submittedAt'] as Timestamp).toDate() 
          : null,
      answers: (map['answers'] as List<dynamic>?)
          ?.map((a) => QuizAnswer.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      score: map['score'],
      totalQuestions: map['totalQuestions'],
      isCompleted: map['isCompleted'] ?? false,
      questionOrder: List<String>.from(map['questionOrder'] ?? []),
    );
  }

  QuizAttemptModel copyWith({
    String? id,
    String? quizId,
    String? studentId,
    int? attemptNumber,
    DateTime? startedAt,
    DateTime? submittedAt,
    List<QuizAnswer>? answers,
    int? score,
    int? totalQuestions,
    bool? isCompleted,
    List<String>? questionOrder,
  }) {
    return QuizAttemptModel(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      studentId: studentId ?? this.studentId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isCompleted: isCompleted ?? this.isCompleted,
      questionOrder: questionOrder ?? this.questionOrder,
    );
  }

  // Calculate percentage
  double? get percentage {
    if (score == null || totalQuestions == null || totalQuestions == 0) {
      return null;
    }
    return (score! / totalQuestions!) * 100;
  }

  // Get time taken
  Duration? get timeTaken {
    if (submittedAt == null) return null;
    return submittedAt!.difference(startedAt);
  }
}