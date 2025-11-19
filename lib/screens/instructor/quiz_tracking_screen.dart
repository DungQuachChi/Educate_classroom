import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../../providers/quiz_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class QuizTrackingScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizTrackingScreen({super.key, required this.quiz});

  @override
  State<QuizTrackingScreen> createState() => _QuizTrackingScreenState();
}

class _QuizTrackingScreenState extends State<QuizTrackingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<UserModel> _students = [];
  List<QuizAttemptModel> _attempts = [];
  Map<String, List<QuizAttemptModel>> _attemptsByStudent = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, completed, not_completed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get students for this quiz
      final students = await _databaseService.getStudentsForQuiz(widget.quiz);

      // Get all attempts
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final attempts = await quizProvider.getAllAttempts(widget.quiz.id);

      // Group by student
      Map<String, List<QuizAttemptModel>> byStudent = {};
      for (var attempt in attempts) {
        if (!byStudent.containsKey(attempt.studentId)) {
          byStudent[attempt.studentId] = [];
        }
        byStudent[attempt.studentId]!.add(attempt);
      }

      setState(() {
        _students = students;
        _attempts = attempts;
        _attemptsByStudent = byStudent;
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

  Future<void> _exportToCSV() async {
    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final csv = await quizProvider.exportToCSV(widget.quiz.id, widget.quiz);

      // Create blob and download for web
      final blob = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'quiz_${widget.quiz.title.replaceAll(' ', '_')}_results.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    final totalStudents = _students.length;
    final completedStudents = _attemptsByStudent.entries
        .where((e) => e.value.any((a) => a.isCompleted))
        .length;
    final notCompleted = totalStudents - completedStudents;

    // Calculate average score
    final completedAttempts = _attempts.where((a) => a.isCompleted).toList();
    double avgScore = 0;
    if (completedAttempts.isNotEmpty) {
      final totalScore = completedAttempts.fold<int>(0, (sum, a) => sum + (a.score ?? 0));
      avgScore = totalScore / completedAttempts.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToCSV,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quiz Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.quiz.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.event, 'Open: ${DateFormat('MMM dd, HH:mm').format(widget.quiz.openTime)}'),
                          _buildInfoChip(Icons.event_busy, 'Close: ${DateFormat('MMM dd, HH:mm').format(widget.quiz.closeTime)}'),
                          _buildInfoChip(Icons.timer, '${widget.quiz.durationMinutes} min'),
                          _buildInfoChip(Icons.quiz, '${widget.quiz.totalQuestions} questions'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Statistics
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _buildStatCard('Total', totalStudents, Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Completed', completedStudents, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Not Completed', notCompleted, Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Avg Score', avgScore.toStringAsFixed(1), Colors.purple)),
                    ],
                  ),
                ),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search students...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(value: 'not_completed', child: Text('Not Completed')),
                        ],
                        onChanged: (value) {
                          setState(() => _filterStatus = value!);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Results Table
                Expanded(
                  child: _buildResultsTable(),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTable() {
    // Apply filters
    var filteredStudents = _students.where((student) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!student.displayName.toLowerCase().contains(_searchQuery) &&
            !student.email.toLowerCase().contains(_searchQuery) &&
            !(student.studentId?.toLowerCase().contains(_searchQuery) ?? false)) {
          return false;
        }
      }

      // Status filter
      final attempts = _attemptsByStudent[student.uid] ?? [];
      final hasCompleted = attempts.any((a) => a.isCompleted);

      if (_filterStatus == 'completed' && !hasCompleted) return false;
      if (_filterStatus == 'not_completed' && hasCompleted) return false;

      return true;
    }).toList();

    if (filteredStudents.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
          columns: const [
            DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Attempts', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Best Score', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Latest Score', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Time Taken', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Submitted At', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredStudents.map((student) {
            final attempts = _attemptsByStudent[student.uid] ?? [];
            final completedAttempts = attempts.where((a) => a.isCompleted).toList();

            int? bestScore;
            int? latestScore;
            Duration? timeTaken;
            DateTime? submittedAt;

            if (completedAttempts.isNotEmpty) {
              bestScore = completedAttempts.map((a) => a.score ?? 0).reduce((a, b) => a > b ? a : b);
              latestScore = completedAttempts.last.score;
              timeTaken = completedAttempts.last.timeTaken;
              submittedAt = completedAttempts.last.submittedAt;
            }

            final status = completedAttempts.isEmpty ? 'Not Completed' : 'Completed';
            final statusColor = completedAttempts.isEmpty ? Colors.orange : Colors.green;

            return DataRow(cells: [
              DataCell(Text(student.studentId ?? '-')),
              DataCell(Text(student.displayName)),
              DataCell(Text(student.email, style: const TextStyle(fontSize: 12))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              DataCell(Text('${attempts.length}')),
              DataCell(Text(bestScore != null ? '$bestScore/${widget.quiz.totalQuestions}' : '-')),
              DataCell(Text(latestScore != null ? '$latestScore/${widget.quiz.totalQuestions}' : '-')),
              DataCell(Text(timeTaken != null ? '${timeTaken.inMinutes}m ${timeTaken.inSeconds % 60}s' : '-')),
              DataCell(Text(
                submittedAt != null ? DateFormat('MMM dd, HH:mm').format(submittedAt) : '-',
                style: const TextStyle(fontSize: 12),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}