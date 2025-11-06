import 'package:flutter/material.dart';
import '../models/semester_model.dart';
import '../services/database_service.dart';

class SemesterProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<SemesterModel> _semesters = [];
  SemesterModel? _currentSemester;
  bool _isLoading = false;

  List<SemesterModel> get semesters => _semesters;
  SemesterModel? get currentSemester => _currentSemester;
  bool get isLoading => _isLoading;

  // Initialize and load semesters
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Get current semester
    _currentSemester = await _databaseService.getCurrentSemester();

    // Listen to semesters stream
    _databaseService.getSemesters().listen((semesters) {
      _semesters = semesters;
      
      // Update current semester if needed
      if (_currentSemester == null && semesters.isNotEmpty) {
        _currentSemester = semesters.first;
      }
      
      _isLoading = false;
      notifyListeners();
    });
  }

  // Set current semester
  void setCurrentSemester(SemesterModel semester) {
    _currentSemester = semester;
    notifyListeners();
  }

  // Create semester
  Future<String> createSemester(SemesterModel semester) async {
    try {
      String id = await _databaseService.createSemester(semester);
      return id;
    } catch (e) {
      rethrow;
    }
  }

  // Update semester
  Future<void> updateSemester(SemesterModel semester) async {
    try {
      await _databaseService.updateSemester(semester);
      
      // Update current semester if it's the one being updated
      if (_currentSemester?.id == semester.id) {
        _currentSemester = semester;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete semester
  Future<void> deleteSemester(String semesterId) async {
    try {
      await _databaseService.deleteSemester(semesterId);
      
      // If deleted semester was current, set first available as current
      if (_currentSemester?.id == semesterId) {
        _currentSemester = _semesters.isNotEmpty ? _semesters.first : null;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Import semesters from CSV
  Future<Map<String, dynamic>> importSemesters(
      List<SemesterModel> semesters) async {
    return await _databaseService.importSemesters(semesters);
  }
}