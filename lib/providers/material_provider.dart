import 'package:flutter/material.dart';
import '../models/material_model.dart';
import '../services/database_service.dart';
import 'dart:async';

class MaterialProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<MaterialModel> _materials = [];
  bool _isLoading = false;
  String? _currentCourseId;
  StreamSubscription? _materialSubscription;

  List<MaterialModel> get materials => _materials;
  bool get isLoading => _isLoading;

  // Load materials for a course
  void loadMaterialsByCourse(String courseId) {
    if (_currentCourseId == courseId) return;
    
    _currentCourseId = courseId;
    _isLoading = true;
    
    _materialSubscription?.cancel();

    _materialSubscription = _databaseService
        .getMaterialsByCourse(courseId)
        .listen((materials) {
      _materials = materials;
      _isLoading = false;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  // Create material
  Future<String> createMaterial(MaterialModel material) async {
    try {
      return await _databaseService.createMaterial(material);
    } catch (e) {
      rethrow;
    }
  }

  // Update material
  Future<void> updateMaterial(MaterialModel material) async {
    try {
      await _databaseService.updateMaterial(material);
    } catch (e) {
      rethrow;
    }
  }

  // Delete material
  Future<void> deleteMaterial(String materialId, String fileUrl) async {
    try {
      await _databaseService.deleteMaterial(materialId, fileUrl);
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _materials = [];
    _currentCourseId = null;
    _materialSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _materialSubscription?.cancel();
    super.dispose();
  }
}