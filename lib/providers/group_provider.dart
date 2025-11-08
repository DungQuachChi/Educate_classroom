import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/database_service.dart';
import 'dart:async';

class GroupProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _currentCourseId;
  StreamSubscription? _groupSubscription;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;

  // Load groups for a course
  void loadGroupsByCourse(String courseId) {
    if (_currentCourseId == courseId) return; // Already loaded
    
    _currentCourseId = courseId;
    _isLoading = true;
    
    // Cancel previous subscription
    _groupSubscription?.cancel();

    _groupSubscription = _databaseService.getGroupsByCourse(courseId).listen((groups) {
      _groups = groups;
      _isLoading = false;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  // Create group
  Future<String> createGroup(GroupModel group) async {
    try {
      return await _databaseService.createGroup(group);
    } catch (e) {
      rethrow;
    }
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    try {
      await _databaseService.updateGroup(group);
    } catch (e) {
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _databaseService.deleteGroup(groupId);
    } catch (e) {
      rethrow;
    }
  }

  // Add student to group
  Future<void> addStudentToGroup(String groupId, String studentId) async {
    try {
      await _databaseService.addStudentToGroup(groupId, studentId);
    } catch (e) {
      rethrow;
    }
  }

  // Remove student from group
  Future<void> removeStudentFromGroup(String groupId, String studentId) async {
    try {
      await _databaseService.removeStudentFromGroup(groupId, studentId);
    } catch (e) {
      rethrow;
    }
  }

  // Clear groups
  void clear() {
    _groups = [];
    _currentCourseId = null;
    _groupSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _groupSubscription?.cancel();
    super.dispose();
  }
}