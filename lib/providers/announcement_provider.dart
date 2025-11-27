import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/announcement_comment_model.dart';
import '../services/database_service.dart';
import 'dart:async';

class AnnouncementProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _currentCourseId;
  StreamSubscription? _announcementSubscription;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  // Load announcements by course
  void loadAnnouncementsByCourse(String courseId) {
    if (_currentCourseId == courseId && _announcementSubscription != null) return;
    
    _currentCourseId = courseId;
    _isLoading = true;
    
    _announcementSubscription?.cancel();

    _announcementSubscription = _databaseService
        .getAnnouncementsByCourse(courseId)
        .listen((announcements) {
      _announcements = announcements;
      _isLoading = false;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  // Create announcement
  Future<String> createAnnouncement(AnnouncementModel announcement) async {
    try {
      return await _databaseService.createAnnouncement(announcement);
    } catch (e) {
      rethrow;
    }
  }

  // Update announcement
  Future<void> updateAnnouncement(AnnouncementModel announcement) async {
    try {
      await _databaseService.updateAnnouncement(announcement);
    } catch (e) {
      rethrow;
    }
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _databaseService.deleteAnnouncement(announcementId);
    } catch (e) {
      rethrow;
    }
  }

  // Mark as viewed
  Future<void> markAsViewed(String announcementId, String userId) async {
    try {
      await _databaseService.markAnnouncementAsViewed(announcementId, userId);
    } catch (e) {
      rethrow;
    }
  }

  // Track download
  Future<void> trackDownload(String announcementId, int attachmentIndex, String userId) async {
    try {
      await _databaseService.trackAttachmentDownload(announcementId, attachmentIndex, userId);
    } catch (e) {
      rethrow;
    }
  }

  // Add comment
  Future<String> addComment(AnnouncementCommentModel comment) async {
    try {
      return await _databaseService.addAnnouncementComment(comment);
    } catch (e) {
      rethrow;
    }
  }

  // Update comment
  Future<void> updateComment(AnnouncementCommentModel comment) async {
    try {
      await _databaseService.updateAnnouncementComment(comment);
    } catch (e) {
      rethrow;
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _databaseService.deleteAnnouncementComment(commentId);
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _announcements = [];
    _currentCourseId = null;
    _announcementSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _announcementSubscription?.cancel();
    super.dispose();
  }
}