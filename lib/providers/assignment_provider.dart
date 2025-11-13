import 'package:flutter/material.dart';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../services/database_service.dart';
import 'dart:async';

class AssignmentProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<AssignmentModel> _assignments = [];
  bool _isLoading = false;
  String? _currentCourseId;
  StreamSubscription? _assignmentSubscription;

  List<AssignmentModel> get assignments => _assignments;
  bool get isLoading => _isLoading;

  // Load assignments for a course
  void loadAssignmentsByCourse(String courseId) {
    if (_currentCourseId == courseId) return;
    
    _currentCourseId = courseId;
    _isLoading = true;
    
    _assignmentSubscription?.cancel();

    _assignmentSubscription = _databaseService
        .getAssignmentsByCourse(courseId)
        .listen((assignments) {
      _assignments = assignments;
      _isLoading = false;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  // Create assignment
  Future<String> createAssignment(AssignmentModel assignment) async {
    try {
      return await _databaseService.createAssignment(assignment);
    } catch (e) {
      rethrow;
    }
  }

  // Update assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    try {
      await _databaseService.updateAssignment(assignment);
    } catch (e) {
      rethrow;
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _databaseService.deleteAssignment(assignmentId);
    } catch (e) {
      rethrow;
    }
  }

  // Submit assignment
  Future<String> submitAssignment({
    required String assignmentId,
    required String studentId,
    required AssignmentModel assignment,
    String? content,
    List<String>? attachmentUrls,
  }) async {
    try {
      return await _databaseService.submitAssignment(
        assignmentId: assignmentId,
        studentId: studentId,
        assignment: assignment,
        content: content,
        attachmentUrls: attachmentUrls,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get submission history
  Future<List<SubmissionModel>> getSubmissionHistory(
    String assignmentId,
    String studentId,
  ) async {
    try {
      return await _databaseService.getStudentSubmissionHistory(
        assignmentId,
        studentId,
      );
    } catch (e) {
      return [];
    }
  }

  // Get all submissions
  Future<List<SubmissionModel>> getAllSubmissions(String assignmentId) async {
    try {
      return await _databaseService.getAllSubmissionsForAssignment(assignmentId);
    } catch (e) {
      return [];
    }
  }

  // Grade submission
  Future<void> gradeSubmission({
    required String submissionId,
    required int score,
    String? feedback,
    required String gradedBy,
  }) async {
    try {
      await _databaseService.gradeSubmission(
        submissionId: submissionId,
        score: score,
        feedback: feedback,
        gradedBy: gradedBy,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Export to CSV
  Future<String> exportToCSV(
    String assignmentId,
    AssignmentModel assignment,
  ) async {
    try {
      return await _databaseService.exportSubmissionsToCSV(
        assignmentId,
        assignment,
      );
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _assignments = [];
    _currentCourseId = null;
    _assignmentSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _assignmentSubscription?.cancel();
    super.dispose();
  }
}