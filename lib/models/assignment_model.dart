import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final List<String> groupIds; 
  final DateTime startDate; 
  final DateTime dueDate;
  final bool allowLateSubmission;
  final DateTime? lateDeadline; 
  final int maxAttempts;
  final List<String> allowedFileFormats; 
  final int maxFileSizeMB; 
  final List<String> attachmentUrls; 
  final int maxScore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    this.groupIds = const [],
    required this.startDate,
    required this.dueDate,
    this.allowLateSubmission = false,
    this.lateDeadline,
    this.maxAttempts = 1,
    this.allowedFileFormats = const [],
    this.maxFileSizeMB = 10,
    this.attachmentUrls = const [],
    this.maxScore = 100,
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
      'groupIds': groupIds,
      'startDate': Timestamp.fromDate(startDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'allowLateSubmission': allowLateSubmission,
      'lateDeadline': lateDeadline != null ? Timestamp.fromDate(lateDeadline!) : null,
      'maxAttempts': maxAttempts,
      'allowedFileFormats': allowedFileFormats,
      'maxFileSizeMB': maxFileSizeMB,
      'attachmentUrls': attachmentUrls,
      'maxScore': maxScore,
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
      groupIds: List<String>.from(map['groupIds'] ?? []),
      startDate: (map['startDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      allowLateSubmission: map['allowLateSubmission'] ?? false,
      lateDeadline: map['lateDeadline'] != null 
          ? (map['lateDeadline'] as Timestamp).toDate() 
          : null,
      maxAttempts: map['maxAttempts'] ?? 1,
      allowedFileFormats: List<String>.from(map['allowedFileFormats'] ?? []),
      maxFileSizeMB: map['maxFileSizeMB'] ?? 10,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      maxScore: map['maxScore'] ?? 100,
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
    List<String>? groupIds,
    DateTime? startDate,
    DateTime? dueDate,
    bool? allowLateSubmission,
    DateTime? lateDeadline,
    int? maxAttempts,
    List<String>? allowedFileFormats,
    int? maxFileSizeMB,
    List<String>? attachmentUrls,
    int? maxScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      groupIds: groupIds ?? this.groupIds,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      lateDeadline: lateDeadline ?? this.lateDeadline,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      allowedFileFormats: allowedFileFormats ?? this.allowedFileFormats,
      maxFileSizeMB: maxFileSizeMB ?? this.maxFileSizeMB,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      maxScore: maxScore ?? this.maxScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if assignment has started
  bool get hasStarted => DateTime.now().isAfter(startDate);

  // Check if assignment is overdue (past due date)
  bool get isOverdue => DateTime.now().isAfter(dueDate);

  // Check if assignment is past late deadline
  bool get isPastLateDeadline {
    if (!allowLateSubmission || lateDeadline == null) return isOverdue;
    return DateTime.now().isAfter(lateDeadline!);
  }

  // Check if can submit now
  bool get canSubmit {
    if (!hasStarted) return false;
    if (!allowLateSubmission) return !isOverdue;
    return !isPastLateDeadline;
  }

  // Check if assignment is due soon (within 24 hours)
  bool get isDueSoon {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.inHours <= 24 && difference.inHours > 0;
  }

  // Get status text
  String get statusText {
    if (!hasStarted) return 'Not started';
    if (isPastLateDeadline) return 'Closed';
    if (isOverdue && allowLateSubmission) return 'Late submission allowed';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due soon';
    return 'Active';
  }
}