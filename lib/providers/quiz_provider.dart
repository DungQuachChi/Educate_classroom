import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_attempt_model.dart';
import '../services/database_service.dart';
import 'dart:async';

class QuizProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  // Questions
  List<QuestionModel> _questions = [];
  bool _isLoadingQuestions = false;

  // Quizzes
  List<QuizModel> _quizzes = [];
  bool _isLoadingQuizzes = false;

  String?  _currentQuestionCourseId; // ← CHANGED: Separate tracking for questions
  String? _currentQuizCourseId;     // ← CHANGED: Separate tracking for quizzes
  StreamSubscription? _questionSubscription;
  StreamSubscription? _quizSubscription;

  List<QuestionModel> get questions => _questions;
  List<QuizModel> get quizzes => _quizzes;
  bool get isLoadingQuestions => _isLoadingQuestions;
  bool get isLoadingQuizzes => _isLoadingQuizzes;

  // ==================== QUESTION BANK ====================

  void loadQuestionsByCourse(String courseId) {
    // ← FIXED: Check against question-specific course ID
    if (_currentQuestionCourseId == courseId && _questionSubscription != null) return;
    
    _currentQuestionCourseId = courseId;
    _isLoadingQuestions = true;
    
    _questionSubscription?.cancel();

    _questionSubscription = _databaseService
        .getQuestionsByCourse(courseId)
        .listen((questions) {
      _questions = questions;
      _isLoadingQuestions = false;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  // ← ADD THIS: Force reload questions (useful when switching courses)
  void forceReloadQuestions(String courseId) {
    _currentQuestionCourseId = null; // Clear cache
    loadQuestionsByCourse(courseId);
  }

  Future<String> createQuestion(QuestionModel question) async {
    try {
      return await _databaseService.createQuestion(question);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuestion(QuestionModel question) async {
    try {
      await _databaseService. updateQuestion(question);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _databaseService.deleteQuestion(questionId);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== QUIZ ====================

  void loadQuizzesByCourse(String courseId) {
    // ← FIXED: Check against quiz-specific course ID
    if (_currentQuizCourseId == courseId && _quizSubscription != null) return;
    
    _currentQuizCourseId = courseId;
    _isLoadingQuizzes = true;
    
    _quizSubscription?.cancel();

    _quizSubscription = _databaseService
        .getQuizzesByCourse(courseId)
        .listen((quizzes) {
      _quizzes = quizzes;
      _isLoadingQuizzes = false;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  Future<String> createQuiz(QuizModel quiz) async {
    try {
      return await _databaseService.createQuiz(quiz);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateQuiz(QuizModel quiz) async {
    try {
      await _databaseService.updateQuiz(quiz);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    try {
      await _databaseService.deleteQuiz(quizId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> selectRandomQuestions(
    String courseId,
    QuizStructure structure,
  ) async {
    try {
      return await _databaseService.selectRandomQuestions(courseId, structure);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== QUIZ ATTEMPTS ====================

  Future<String> startQuizAttempt(QuizAttemptModel attempt) async {
    try {
      return await _databaseService.startQuizAttempt(attempt);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizAttemptModel>> getStudentAttempts(
    String quizId,
    String studentId,
  ) async {
    try {
      return await _databaseService.getStudentQuizAttempts(quizId, studentId);
    } catch (e) {
      return [];
    }
  }

  Future<void> submitQuizAttempt({
    required String attemptId,
    required List<QuizAnswer> answers,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      await _databaseService.submitQuizAttempt(
        attemptId: attemptId,
        answers: answers,
        score: score,
        totalQuestions: totalQuestions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<QuizAttemptModel>> getAllAttempts(String quizId) async {
    try {
      return await _databaseService.getAllQuizAttempts(quizId);
    } catch (e) {
      return [];
    }
  }

  Future<String> exportToCSV(String quizId, QuizModel quiz) async {
    try {
      return await _databaseService.exportQuizResultsToCSV(quizId, quiz);
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    _questions = [];
    _quizzes = [];
    _currentQuestionCourseId = null; // ← CHANGED
    _currentQuizCourseId = null;     // ← CHANGED
    _questionSubscription?.cancel();
    _quizSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _questionSubscription?. cancel();
    _quizSubscription?.cancel();
    super. dispose();
  }
}