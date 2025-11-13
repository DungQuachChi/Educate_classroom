import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/assignment_provider.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const AssignmentSubmissionsScreen({super.key, required this.assignment});

  @override
  State<AssignmentSubmissionsScreen> createState() => _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState extends State<AssignmentSubmissionsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
      ),
      body: Column(
        children: [
          // Assignment Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.assignment.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.assignment.dueDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.grade, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Max: ${widget.assignment.maxScore} pts',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Submissions List
          Expanded(
            child: Consumer<AssignmentProvider>(
              builder: (context, assignmentProvider, child) {
                return StreamBuilder<List<SubmissionModel>>(
                  stream: assignmentProvider.getSubmissions(widget.assignment.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final submissions = snapshot.data ?? [];

                    if (submissions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No submissions yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: submissions.length,
                      itemBuilder: (context, index) {
                        return _SubmissionCard(
                          submission: submissions[index],
                          assignment: widget.assignment,
                        );
                      },
                    );
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

class _SubmissionCard extends StatefulWidget {
  final SubmissionModel submission;
  final AssignmentModel assignment;

  const _SubmissionCard({
    required this.submission,
    required this.assignment,
  });

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final students = await _databaseService.getStudentsByIds([widget.submission.studentId]);
      if (students.isNotEmpty) {
        setState(() {
          _student = students.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_student == null) {
      return const SizedBox.shrink();
    }

    final isLate = widget.submission.isLate(widget.assignment.dueDate);
    final isGraded = widget.submission.isGraded;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(_student!.displayName[0].toUpperCase()),
        ),
        title: Text(
          _student!.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_student!.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isLate ? Icons.warning : Icons.check_circle,
                  size: 14,
                  color: isLate ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  isLate ? 'Late submission' : 'On time',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLate ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                if (isGraded) ...[
                  Icon(Icons.grade, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.submission.score}/${widget.assignment.maxScore}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else
                  const Text(
                    'Not graded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Submission Info
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.submission.submittedAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                if (widget.submission.content != null) ...[
                  const Text(
                    'Submission:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.submission.content!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Attachments
                if (widget.submission.attachmentUrls.isNotEmpty) ...[
                  const Text(
                    'Attachments:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...widget.submission.attachmentUrls.map((url) {
                    final fileName = url.split('/').last.split('?').first;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.attach_file, size: 20),
                      title: Text(
                        fileName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        onPressed: () {
                          // TODO: Download file
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],

                // Feedback
                if (widget.submission.feedback != null) ...[
                  const Text(
                    'Feedback:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.submission.feedback!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Grade Button
                ElevatedButton.icon(
                  onPressed: () => _showGradeDialog(),
                  icon: Icon(isGraded ? Icons.edit : Icons.grade),
                  label: Text(isGraded ? 'Update Grade' : 'Grade Submission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGraded ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGradeDialog() {
    final scoreController = TextEditingController(
      text: widget.submission.score?.toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: widget.submission.feedback ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${_student!.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: scoreController,
                decoration: InputDecoration(
                  labelText: 'Score',
                  hintText: 'e.g., 85',
                  suffixText: '/ ${widget.assignment.maxScore}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback (Optional)',
                  hintText: 'Great work! Consider...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = int.tryParse(scoreController.text);
              if (score == null || score < 0 || score > widget.assignment.maxScore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid score (0-${widget.assignment.maxScore})'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                await assignmentProvider.gradeSubmission(
                  widget.submission.id,
                  score,
                  feedbackController.text.trim().isEmpty ? null : feedbackController.text.trim(),
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Submission graded successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}