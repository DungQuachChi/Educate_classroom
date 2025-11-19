import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum QuestionDifficulty { easy, medium, hard }

class QuestionModel {
  final String id;
  final String courseId;
  final String question;
  final List<String> choices; // Multiple choice options
  final int correctAnswerIndex; // Index of correct answer in choices
  final QuestionDifficulty difficulty;
  final String createdBy; // Instructor UID
  final DateTime createdAt;
  final DateTime? updatedAt;

  QuestionModel({
    required this.id,
    required this.courseId,
    required this.question,
    required this.choices,
    required this.correctAnswerIndex,
    required this.difficulty,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'question': question,
      'choices': choices,
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty.toString().split('.').last,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return QuestionModel(
      id: documentId,
      courseId: map['courseId'] ?? '',
      question: map['question'] ?? '',
      choices: List<String>.from(map['choices'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == map['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  QuestionModel copyWith({
    String? id,
    String? courseId,
    String? question,
    List<String>? choices,
    int? correctAnswerIndex,
    QuestionDifficulty? difficulty,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      question: question ?? this.question,
      choices: choices ?? this.choices,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      difficulty: difficulty ?? this.difficulty,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return const Color(0xFF4CAF50); // Green
      case QuestionDifficulty.medium:
        return const Color(0xFFFF9800); // Orange
      case QuestionDifficulty.hard:
        return const Color(0xFFF44336); // Red
    }
  }
}