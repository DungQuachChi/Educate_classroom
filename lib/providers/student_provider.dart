import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'dart:async';

class StudentProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  List<UserModel> _students = [];
  bool _isLoading = false;
  StreamSubscription? _studentSubscription;

  List<UserModel> get students => _students;
  bool get isLoading => _isLoading;

  // Initialize and load students
  void initialize() {
    if (_studentSubscription != null) return; // Already initialized

    _isLoading = true;

    _studentSubscription = _databaseService.getStudents().listen((students) {
      _students = students;
      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  // Create student
  Future<UserModel> createStudent({
    required String email,
    required String password,
    required String displayName,
    String? studentId,
  }) async {
    try {
      return await _authService.createStudentAccount(
        email: email,
        password: password,
        displayName: displayName,
        studentId: studentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update student (only profile info, not auth)
  Future<void> updateStudent(UserModel student) async {
    try {
      await _databaseService.updateStudent(student);
    } catch (e) {
      rethrow;
    }
  }

  // Delete student
  Future<void> deleteStudent(String userId) async {
    try {
      await _databaseService.deleteStudent(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Import students from CSV
  Future<Map<String, dynamic>> importStudents(
      List<Map<String, String>> studentData) async {
    int added = 0;
    int skipped = 0;
    List<String> errors = [];

    for (var data in studentData) {
      try {
        // Check if student already exists
        bool exists = _students.any((s) => s.email == data['email']);

        if (!exists) {
          await createStudent(
            email: data['email']!,
            password: data['password'] ?? 'student123',
            displayName: data['displayName']!,
            studentId: data['studentId'],
          );
          added++;
        } else {
          skipped++;
        }
      } catch (e) {
        errors.add('${data['email']}: $e');
      }
    }

    return {
      'added': added,
      'skipped': skipped,
      'errors': errors,
    };
  }

  @override
  void dispose() {
    _studentSubscription?.cancel();
    super.dispose();
  }
}