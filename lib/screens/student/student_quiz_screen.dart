import 'package:educate_classroom/screens/student/quiz_taking_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/question_model.dart';
import '../../services/database_service.dart';

class StudentQuizScreen extends StatefulWidget {
  final QuizModel quiz;

  const StudentQuizScreen({super.key, required this.quiz});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<QuizAttemptModel> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final attempts = await quizProvider.getStudentAttempts(
          widget.quiz.id,
          authProvider.user!.uid,
        );

        setState(() {
          _attempts = attempts;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _startQuiz() async {
    // Check if quiz is open
    if (!widget.quiz.isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.quiz.isUpcoming
                ? 'Quiz opens on ${DateFormat('MMM dd, yyyy HH:mm').format(widget.quiz.openTime)}'
                : 'Quiz has closed',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check max attempts
    final completedAttempts = _attempts.where((a) => a.isCompleted).length;
    if (widget.quiz.maxAttempts > 0 && completedAttempts >= widget.quiz.maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum attempts (${widget.quiz.maxAttempts}) reached'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Load questions
      List<QuestionModel> questions = [];
      for (String qid in widget.quiz.questionIds) {
        final q = await _databaseService.getQuestionById(qid);
        if (q != null) questions.add(q);
      }

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions available'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Randomize if needed
      List<String> questionOrder = questions.map((q) => q.id).toList();
      if (widget.quiz.randomizeQuestions) {
        questionOrder.shuffle();
      }

      // Create attempt
      final attempt = QuizAttemptModel(
        id: '',
        quizId: widget.quiz.id,
        studentId: authProvider.user!.uid,
        attemptNumber: _attempts.length + 1,
        startedAt: DateTime.now(),
        questionOrder: questionOrder,
        totalQuestions: questions.length,
      );

      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final attemptId = await quizProvider.startQuizAttempt(attempt);

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizTakingScreen(
              quiz: widget.quiz,
              attempt: attempt.copyWith(id: attemptId),
              questions: questions,
            ),
          ),
        );

        _loadAttempts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = widget.quiz.isOpen &&
        (widget.quiz.maxAttempts == 0 ||
            _attempts.where((a) => a.isCompleted).length < widget.quiz.maxAttempts);

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quiz Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.quiz.isClosed
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : widget.quiz.isUpcoming
                                ? [Colors.orange.shade400, Colors.orange.shade600]
                                : [Colors.indigo.shade400, Colors.indigo.shade600],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.quiz.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildHeaderChip(Icons.event, 'Open: ${DateFormat('MMM dd, HH:mm').format(widget.quiz.openTime)}'),
                            _buildHeaderChip(Icons.event_busy, 'Close: ${DateFormat('MMM dd, HH:mm').format(widget.quiz.closeTime)}'),
                            _buildHeaderChip(Icons.timer, '${widget.quiz.durationMinutes} minutes'),
                            _buildHeaderChip(Icons.quiz, '${widget.quiz.totalQuestions} questions'),
                            _buildHeaderChip(Icons.repeat, 'Max ${widget.quiz.maxAttempts == 0 ? '∞' : widget.quiz.maxAttempts} attempts'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.quiz.isUpcoming
                                ? Colors.orange[50]
                                : widget.quiz.isClosed
                                    ? Colors.red[50]
                                    : canStart
                                        ? Colors.green[50]
                                        : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.quiz.isUpcoming
                                  ? Colors.orange
                                  : widget.quiz.isClosed
                                      ? Colors.red
                                      : canStart
                                          ? Colors.green
                                          : Colors.blue,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.quiz.isUpcoming
                                    ? Icons.schedule
                                    : widget.quiz.isClosed
                                        ? Icons.lock
                                        : canStart
                                            ? Icons.play_circle
                                            : Icons.info,
                                color: widget.quiz.isUpcoming
                                    ? Colors.orange
                                    : widget.quiz.isClosed
                                        ? Colors.red
                                        : canStart
                                            ? Colors.green
                                            : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.quiz.isUpcoming
                                      ? 'Quiz has not started yet'
                                      : widget.quiz.isClosed
                                          ? 'Quiz has closed'
                                          : canStart
                                              ? 'You can take this quiz now'
                                              : 'Maximum attempts reached',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.quiz.isUpcoming
                                        ? Colors.orange[700]
                                        : widget.quiz.isClosed
                                            ? Colors.red[700]
                                            : canStart
                                                ? Colors.green[700]
                                                : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(widget.quiz.description, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),

                        // Quiz Info
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Quiz Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('• Duration: ${widget.quiz.durationMinutes} minutes'),
                                Text('• Total Questions: ${widget.quiz.totalQuestions}'),
                                Text('• Question Structure:'),
                                Text('  - Easy: ${widget.quiz.structure.easyCount}'),
                                Text('  - Medium: ${widget.quiz.structure.mediumCount}'),
                                Text('  - Hard: ${widget.quiz.structure.hardCount}'),
                                if (widget.quiz.randomizeQuestions)
                                  const Text('• Questions will appear in random order'),
                                if (widget.quiz.randomizeChoices)
                                  const Text('• Answer choices will be randomized'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Attempts History
                        if (_attempts.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Attempts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(
                                '${_attempts.where((a) => a.isCompleted).length}/${widget.quiz.maxAttempts == 0 ? '∞' : widget.quiz.maxAttempts}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._attempts.reversed.map((attempt) => _AttemptCard(attempt: attempt, quiz: widget.quiz)),
                          const SizedBox(height: 24),
                        ],

                        // Start Button
                        if (canStart) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _startQuiz,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green,
                              ),
                              child: Text(
                                'START ATTEMPT ${_attempts.length + 1}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

class _AttemptCard extends StatelessWidget {
  final QuizAttemptModel attempt;
  final QuizModel quiz;

  const _AttemptCard({required this.attempt, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: attempt.isCompleted ? Colors.green[50] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: attempt.isCompleted ? Colors.green : Colors.grey,
                  child: Text(
                    '${attempt.attemptNumber}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attempt ${attempt.attemptNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Started: ${DateFormat('MMM dd, yyyy HH:mm').format(attempt.startedAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (attempt.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score: ${attempt.score}/${quiz.totalQuestions}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            if (attempt.isCompleted) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Completed: ${DateFormat('MMM dd, HH:mm').format(attempt.submittedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Time: ${attempt.timeTaken!.inMinutes}m ${attempt.timeTaken!.inSeconds % 60}s',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.percent, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${attempt.percentage?.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Not completed',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}