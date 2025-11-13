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

    _assignmentSubscription = _databaseService.getAssignmentsByCourse(courseId).listen((assignments) {
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
  Future<String> submitAssignment(SubmissionModel submission) async {
    try {
      return await _databaseService.createSubmission(submission);
    } catch (e) {
      rethrow;
    }
  }

  // Get submissions for an assignment
  Stream<List<SubmissionModel>> getSubmissions(String assignmentId) {
    return _databaseService.getSubmissionsByAssignment(assignmentId);
  }

  // Grade submission
  Future<void> gradeSubmission(String submissionId, int score, String? feedback) async {
    try {
      await _databaseService.gradeSubmission(submissionId, score, feedback);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _assignmentSubscription?.cancel();
    super.dispose();
  }
}