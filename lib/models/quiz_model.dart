import 'package:cloud_firestore/cloud_firestore.dart';

class QuizStructure {
  final int easyCount;
  final int mediumCount;
  final int hardCount;

  QuizStructure({
    required this.easyCount,
    required this.mediumCount,
    required this.hardCount,
  });

  int get totalQuestions => easyCount + mediumCount + hardCount;

  Map<String, dynamic> toMap() {
    return {
      'easyCount': easyCount,
      'mediumCount': mediumCount,
      'hardCount': hardCount,
    };
  }

  factory QuizStructure.fromMap(Map<String, dynamic> map) {
    return QuizStructure(
      easyCount: map['easyCount'] ?? 0,
      mediumCount: map['mediumCount'] ?? 0,
      hardCount: map['hardCount'] ?? 0,
    );
  }
}

class QuizModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final List<String> groupIds; // Empty = all students
  final DateTime openTime;
  final DateTime closeTime;
  final int durationMinutes; // Quiz duration in minutes
  final int maxAttempts; // 0 = unlimited
  final QuizStructure structure;
  final List<String> questionIds; // Selected question IDs (randomly picked or manual)
  final bool randomizeQuestions; // Randomize question order for each student
  final bool randomizeChoices; // Randomize choice order for each student
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    this.groupIds = const [],
    required this.openTime,
    required this.closeTime,
    required this.durationMinutes,
    this.maxAttempts = 1,
    required this.structure,
    required this.questionIds,
    this.randomizeQuestions = true,
    this.randomizeChoices = true,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
      'groupIds': groupIds,
      'openTime': Timestamp.fromDate(openTime),
      'closeTime': Timestamp.fromDate(closeTime),
      'durationMinutes': durationMinutes,
      'maxAttempts': maxAttempts,
      'structure': structure.toMap(),
      'questionIds': questionIds,
      'randomizeQuestions': randomizeQuestions,
      'randomizeChoices': randomizeChoices,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map, String documentId) {
    return QuizModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      courseId: map['courseId'] ?? '',
      groupIds: List<String>.from(map['groupIds'] ?? []),
      openTime: (map['openTime'] as Timestamp).toDate(),
      closeTime: (map['closeTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 60,
      maxAttempts: map['maxAttempts'] ?? 1,
      structure: QuizStructure.fromMap(map['structure'] ?? {}),
      questionIds: List<String>.from(map['questionIds'] ?? []),
      randomizeQuestions: map['randomizeQuestions'] ?? true,
      randomizeChoices: map['randomizeChoices'] ?? true,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    List<String>? groupIds,
    DateTime? openTime,
    DateTime? closeTime,
    int? durationMinutes,
    int? maxAttempts,
    QuizStructure? structure,
    List<String>? questionIds,
    bool? randomizeQuestions,
    bool? randomizeChoices,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      groupIds: groupIds ?? this.groupIds,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      structure: structure ?? this.structure,
      questionIds: questionIds ?? this.questionIds,
      randomizeQuestions: randomizeQuestions ?? this.randomizeQuestions,
      randomizeChoices: randomizeChoices ?? this.randomizeChoices,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if quiz is open
  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(openTime) && now.isBefore(closeTime);
  }

  // Check if quiz is upcoming
  bool get isUpcoming => DateTime.now().isBefore(openTime);

  // Check if quiz is closed
  bool get isClosed => DateTime.now().isAfter(closeTime);

  // Get status text
  String get statusText {
    if (isUpcoming) return 'Upcoming';
    if (isClosed) return 'Closed';
    return 'Open';
  }

  // Get total questions
  int get totalQuestions => structure.totalQuestions;
}