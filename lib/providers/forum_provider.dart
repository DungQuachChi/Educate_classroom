import 'package:flutter/foundation.dart';
import '../models/forum_model.dart';
import '../models/forum_reply_model.dart';
import '../services/database_service.dart';
import 'package:file_picker/file_picker.dart';

class ForumProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  // Create forum
  Future<String> createForum(ForumModel forum) async {
    try {
      return await _databaseService.createForum(forum);
    } catch (e) {
      rethrow;
    }
  }

  // Get forums by course
  Stream<List<ForumModel>> getForumsByCourse(String courseId) {
    return _databaseService.getForumsByCourse(courseId);
  }

  // Get forum
  Future<ForumModel?> getForum(String forumId) async {
    return await _databaseService.getForum(forumId);
  }

  // Update forum
  Future<void> updateForum(String forumId, Map<String, dynamic> updates) async {
    try {
      await _databaseService.updateForum(forumId, updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete forum
  Future<void> deleteForum(String forumId) async {
    try {
      await _databaseService.deleteForum(forumId);
    } catch (e) {
      rethrow;
    }
  }

  // Toggle pin
  Future<void> togglePin(String forumId, bool isPinned) async {
    try {
      await _databaseService.togglePinForum(forumId, isPinned);
    } catch (e) {
      rethrow;
    }
  }

  // Toggle lock
  Future<void> toggleLock(String forumId, bool isLocked) async {
    try {
      await _databaseService.toggleLockForum(forumId, isLocked);
    } catch (e) {
      rethrow;
    }
  }

  // Search forums
  Future<List<ForumModel>> searchForums(String courseId, String query) async {
    return await _databaseService.searchForums(courseId, query);
  }

  // Upload forum attachment
  Future<String> uploadForumAttachment(String forumId, PlatformFile file) async {
    try {
      return await _databaseService.uploadForumAttachment(forumId, file);
    } catch (e) {
      rethrow;
    }
  }

  // Create reply
  Future<String> createReply(ForumReplyModel reply) async {
    try {
      return await _databaseService. createForumReply(reply);
    } catch (e) {
      rethrow;
    }
  }

  // Get replies
  Stream<List<ForumReplyModel>> getReplies(String forumId) {
    return _databaseService.getForumReplies(forumId);
  }

  // Update reply
  Future<void> updateReply(String replyId, Map<String, dynamic> updates) async {
    try {
      await _databaseService.updateForumReply(replyId, updates);
    } catch (e) {
      rethrow;
    }
  }

  // Delete reply
  Future<void> deleteReply(String replyId, String forumId) async {
    try {
      await _databaseService. deleteForumReply(replyId, forumId);
    } catch (e) {
      rethrow;
    }
  }

  // Upload reply attachment
  Future<String> uploadReplyAttachment(String replyId, PlatformFile file) async {
    try {
      return await _databaseService.uploadForumReplyAttachment(replyId, file);
    } catch (e) {
      rethrow;
    }
  }
}