import 'package:educate_classroom/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../services/database_service.dart';

class MessageProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get total unread count
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  // Load conversations for user
  Stream<List<ConversationModel>> getConversationsStream(
    String userId,
    bool isInstructor,
  ) {
    return _databaseService. getConversations(userId, isInstructor);
  }

  // Get or create conversation
  Future<String> getOrCreateConversation(
    String studentId,
    String instructorId,
  ) async {
    try {
      _setLoading(true);
      final conversationId = await _databaseService.getOrCreateConversation(
        studentId,
        instructorId,
      );
      _setLoading(false);
      return conversationId;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      rethrow;
    }
  }

  // Send text message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
  }) async {
    try {
      final message = MessageModel(
        id: '',
        conversationId: conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        sentAt: DateTime.now(),
        attachmentUrls: attachmentUrls ??  [],
        attachmentNames: attachmentNames ?? [],
      );

      await _databaseService.sendMessage(message);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _databaseService.getMessages(conversationId);
  }

  // Mark messages as read
  Future<void> markAsRead(String conversationId, String userId) async {
    try {
      await _databaseService.markMessagesAsRead(conversationId, userId);
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  // Upload attachment
  Future<String> uploadAttachment(String conversationId, PlatformFile file) async {
    try {
      return await _databaseService.uploadMessageAttachment(conversationId, file);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Get instructors for student
  Future<List<UserModel>> getInstructorsForStudent(String studentId) async {
    try {
      return await _databaseService.getInstructorsForStudent(studentId);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String?  value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}