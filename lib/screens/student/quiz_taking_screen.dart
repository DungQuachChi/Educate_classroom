import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/quiz_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/question_model.dart';

class QuizTakingScreen extends StatefulWidget {
  final QuizModel quiz;
  final QuizAttemptModel attempt;
  final List<QuestionModel> questions;

  const QuizTakingScreen({
    super.key,
    required this.quiz,
    required this.attempt,
    required this.questions,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late List<QuestionModel> _orderedQuestions;
  late Map<String, int?> _answers;
  late Map<String, List<int>> _shuffledChoices;
  int _currentQuestionIndex = 0;
  Timer? _timer;
  late DateTime _endTime;
  Duration _remainingTime = Duration.zero;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Order questions based on attempt's question order
    _orderedQuestions = [];
    for (String qid in widget.attempt.questionOrder) {
      final question = widget.questions.firstWhere((q) => q.id == qid);
      _orderedQuestions.add(question);
    }

    // Initialize answers
    _answers = {};
    for (var q in _orderedQuestions) {
      _answers[q.id] = null;
    }

    // Shuffle choices if needed
    _shuffledChoices = {};
    if (widget.quiz.randomizeChoices) {
      for (var q in _orderedQuestions) {
        List<int> indices = List.generate(q.choices.length, (i) => i);
        indices.shuffle();
        _shuffledChoices[q.id] = indices;
      }
    }

    // Start timer
    _endTime = widget.attempt.startedAt.add(Duration(minutes: widget.quiz.durationMinutes));
    _remainingTime = _endTime.difference(DateTime.now());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime = _endTime.difference(DateTime.now());
        if (_remainingTime.isNegative) {
          _remainingTime = Duration.zero;
          _timer?.cancel();
          _autoSubmit();
        }
      });
    });
  }

  Future<void> _autoSubmit() async {
    if (_isSubmitting) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time is up! Auto-submitting...'),
        backgroundColor: Colors.orange,
      ),
    );

    await _submitQuiz();
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    // Check if all questions are answered
    final unanswered = _answers.values.where((a) => a == null).length;
    if (unanswered > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unanswered Questions'),
          content: Text('You have $unanswered unanswered question(s).\n\nSubmit anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submit Quiz'),
          content: const Text('Are you sure you want to submit?\n\nYou cannot change your answers after submission.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Calculate score
      int score = 0;
      List<QuizAnswer> answers = [];

      for (var question in _orderedQuestions) {
        final selectedIndex = _answers[question.id];
        
        if (selectedIndex != null) {
          // If choices were shuffled, convert back to original index
          int originalIndex = selectedIndex;
          if (widget.quiz.randomizeChoices && _shuffledChoices.containsKey(question.id)) {
            originalIndex = _shuffledChoices[question.id]![selectedIndex];
          }

          answers.add(QuizAnswer(
            questionId: question.id,
            selectedAnswerIndex: originalIndex,
          ));

          // Check if correct
          if (originalIndex == question.correctAnswerIndex) {
            score++;
          }
        } else {
          answers.add(QuizAnswer(
            questionId: question.id,
            selectedAnswerIndex: -1, 
          ));
        }
      }

      // Submit to database
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      await quizProvider.submitQuizAttempt(
        attemptId: widget.attempt.id,
        answers: answers,
        score: score,
        totalQuestions: _orderedQuestions.length,
      );

      if (mounted) {
        _timer?.cancel();
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quiz submitted! Score: $score/${_orderedQuestions.length}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _orderedQuestions[_currentQuestionIndex];
    final answeredCount = _answers.values.where((a) => a != null).length;

    // Get timer color
    Color timerColor = Colors.green;
    if (_remainingTime.inMinutes < 5) {
      timerColor = Colors.red;
    } else if (_remainingTime.inMinutes < 15) {
      timerColor = Colors.orange;
    }

    return WillPopScope(
      onWillPop: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text('Your progress will be lost if you exit.\n\nAre you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${_currentQuestionIndex + 1}/${_orderedQuestions.length}'),
          backgroundColor: timerColor,
          actions: [
            // Timer
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 18, color: timerColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_remainingTime),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: answeredCount / _orderedQuestions.length,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),

            // Progress text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Text(
                'Answered: $answeredCount/${_orderedQuestions.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            // Question
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: currentQuestion.difficultyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: currentQuestion.difficultyColor),
                        ),
                        child: Text(
                          currentQuestion.difficultyLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: currentQuestion.difficultyColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Question text
                      Text(
                        currentQuestion.question,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      // Choices
                      ..._buildChoices(currentQuestion),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous button
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _currentQuestionIndex--);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),

                  // Next/Submit button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_currentQuestionIndex < _orderedQuestions.length - 1) {
                          setState(() => _currentQuestionIndex++);
                        } else {
                          _submitQuiz();
                        }
                      },
                      icon: Icon(
                        _currentQuestionIndex < _orderedQuestions.length - 1
                            ? Icons.arrow_forward
                            : Icons.check,
                      ),
                      label: Text(
                        _currentQuestionIndex < _orderedQuestions.length - 1
                            ? 'Next'
                            : 'Submit Quiz',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentQuestionIndex < _orderedQuestions.length - 1
                            ? Colors.blue
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Question grid button
                  IconButton(
                    icon: const Icon(Icons.grid_view),
                    onPressed: () => _showQuestionGrid(),
                    tooltip: 'View all questions',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChoices(QuestionModel question) {
    List<int> choiceIndices = widget.quiz.randomizeChoices && _shuffledChoices.containsKey(question.id)
        ? _shuffledChoices[question.id]!
        : List.generate(question.choices.length, (i) => i);

    return choiceIndices.asMap().entries.map((entry) {
      final displayIndex = entry.key; 
      final originalIndex = entry.value; 
      final choice = question.choices[originalIndex];
      final isSelected = _answers[question.id] == displayIndex;

      return GestureDetector(
        onTap: () {
          setState(() {
            _answers[question.id] = displayIndex;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + displayIndex),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  choice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showQuestionGrid() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question Navigator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _orderedQuestions.length,
              itemBuilder: (context, index) {
                final isAnswered = _answers[_orderedQuestions[index].id] != null;
                final isCurrent = index == _currentQuestionIndex;

                return InkWell(
                  onTap: () {
                    setState(() => _currentQuestionIndex = index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Colors.blue
                          : isAnswered
                              ? Colors.green
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent || isAnswered ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendItem(Colors.blue, 'Current'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.green, 'Answered'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.grey[300]!, 'Unanswered'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}