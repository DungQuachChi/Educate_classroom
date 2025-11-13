import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../models/course_model.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../services/database_service.dart';
import 'student_assignment_screen.dart';

class StudentCourseScreen extends StatefulWidget {
  final CourseModel course;

  const StudentCourseScreen({super.key, required this.course});

  @override
  State<StudentCourseScreen> createState() => _StudentCourseScreenState();
}

class _StudentCourseScreenState extends State<StudentCourseScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<AssignmentModel> _assignments = [];
  Map<String, List<SubmissionModel>> _submissionHistory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        final assignments = await _databaseService.getStudentAssignments(
          authProvider.user!.uid,
          widget.course.id,
        );

        // Load submission history for each assignment
        Map<String, List<SubmissionModel>> history = {};
        for (var assignment in assignments) {
          final subs = await _databaseService.getStudentSubmissionHistory(
            assignment.id,
            authProvider.user!.uid,
          );
          history[assignment.id] = subs;
        }

        setState(() {
          _assignments = assignments;
          _submissionHistory = history;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.code)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course.code, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      Text(
                        widget.course.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (widget.course.description != null) ...[
                        const SizedBox(height: 8),
                        Text(widget.course.description!, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                      ],
                    ],
                  ),
                ),

                // Assignments Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Assignments (${_assignments.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: _assignments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No assignments yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _assignments.length,
                          itemBuilder: (context, index) {
                            final assignment = _assignments[index];
                            final submissions = _submissionHistory[assignment.id] ?? [];
                            final latestSubmission = submissions.isNotEmpty ? submissions.last : null;

                            return _AssignmentCard(
                              assignment: assignment,
                              latestSubmission: latestSubmission,
                              totalAttempts: submissions.length,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentAssignmentScreen(assignment: assignment),
                                  ),
                                );
                                _loadAssignments();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final SubmissionModel? latestSubmission;
  final int totalAttempts;
  final VoidCallback onTap;

  const _AssignmentCard({
    required this.assignment,
    required this.latestSubmission,
    required this.totalAttempts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pending;
    String statusText = 'Not started';

    if (!assignment.hasStarted) {
      statusColor = Colors.grey;
      statusIcon = Icons.schedule;
      statusText = 'Not started';
    } else if (latestSubmission != null) {
      if (latestSubmission!.isGraded) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Graded: ${latestSubmission!.score}/${assignment.maxScore}';
      } else {
        statusColor = Colors.blue;
        statusIcon = Icons.done;
        statusText = 'Submitted';
      }
    } else if (assignment.isPastLateDeadline) {
      statusColor = Colors.red;
      statusIcon = Icons.lock;
      statusText = 'Closed';
    } else if (assignment.isOverdue) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = assignment.allowLateSubmission ? 'Overdue - Late OK' : 'Overdue';
    } else if (assignment.isDueSoon) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer;
      statusText = 'Due soon';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.assignment;
      statusText = 'Active';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                assignment.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (!assignment.hasStarted)
                    _buildInfoChip(Icons.calendar_today, 'Starts: ${DateFormat('MMM dd, HH:mm').format(assignment.startDate)}', Colors.grey[600]!),
                  _buildInfoChip(Icons.event, 'Due: ${DateFormat('MMM dd, HH:mm').format(assignment.dueDate)}', Colors.grey[600]!),
                  if (assignment.allowLateSubmission && assignment.lateDeadline != null)
                    _buildInfoChip(Icons.access_time, 'Late: ${DateFormat('MMM dd, HH:mm').format(assignment.lateDeadline!)}', Colors.orange[600]!),
                  _buildInfoChip(Icons.grade, '${assignment.maxScore} pts', Colors.grey[600]!),
                  if (totalAttempts > 0)
                    _buildInfoChip(Icons.repeat, '$totalAttempts/${assignment.maxAttempts == 0 ? '∞' : assignment.maxAttempts}', Colors.grey[600]!),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Text(statusText, style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}