import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/database_service.dart';

class CourseProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<CourseModel> _courses = [];
  bool _isLoading = false;
  String? _currentSemesterId;

  List<CourseModel> get courses => _courses;
  bool get isLoading => _isLoading;

  // Load courses for a semester
  void loadCoursesBySemester(String semesterId) {
    _currentSemesterId = semesterId;
    _isLoading = true;
    notifyListeners();

    _databaseService.getCoursesBySemester(semesterId).listen((courses) {
      _courses = courses;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Create course
  Future<String> createCourse(CourseModel course) async {
    try {
      return await _databaseService.createCourse(course);
    } catch (e) {
      rethrow;
    }
  }

  // Update course
  Future<void> updateCourse(CourseModel course) async {
    try {
      await _databaseService.updateCourse(course);
    } catch (e) {
      rethrow;
    }
  }

  // Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      await _databaseService.deleteCourse(courseId);
    } catch (e) {
      rethrow;
    }
  }
}