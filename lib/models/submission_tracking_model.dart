import 'user_model.dart';
import 'submission_model.dart';

class SubmissionTrackingModel {
  final UserModel student;
  final List<SubmissionModel> submissions;
  final String groupName;

  SubmissionTrackingModel({
    required this.student,
    required this.submissions,
    required this.groupName,
  });

  SubmissionModel? get latestSubmission {
    if (submissions.isEmpty) return null;
    return submissions.reduce((a, b) => 
      a.submittedAt.isAfter(b.submittedAt) ? a : b
    );
  }

  int? get highestScore {
    if (submissions.isEmpty) return null;
    final graded = submissions.where((s) => s.score != null).toList();
    if (graded.isEmpty) return null;
    return graded.map((s) => s.score!).reduce((a, b) => a > b ? a : b);
  }

  int get totalAttempts => submissions.length;

  bool get hasSubmitted => submissions.isNotEmpty;

  bool get isLateSubmission => latestSubmission?.isLate ?? false;

  bool get isGraded => latestSubmission?.isGraded ?? false;

  String get status {
    if (!hasSubmitted) return 'Not submitted';
    if (isGraded) return 'Graded';
    if (isLateSubmission) return 'Late submission';
    return 'Submitted';
  }
}