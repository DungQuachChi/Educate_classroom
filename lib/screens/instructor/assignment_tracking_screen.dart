import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../../providers/assignment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../models/submission_tracking_model.dart';
import '../../services/database_service.dart';

class AssignmentTrackingScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const AssignmentTrackingScreen({super.key, required this.assignment});

  @override
  State<AssignmentTrackingScreen> createState() => _AssignmentTrackingScreenState();
}

class _AssignmentTrackingScreenState extends State<AssignmentTrackingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<SubmissionTrackingModel> _trackingData = [];
  List<SubmissionTrackingModel> _filteredData = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, submitted, not_submitted, graded, late
  String _sortBy = 'name'; // name, status, attempts, score, time
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() => _isLoading = true);

    try {
      // Get students for this assignment
      final students = await _databaseService.getStudentsForAssignment(widget.assignment);
      
      // Get all submissions
      final submissions = await _databaseService.getAllSubmissionsForAssignment(widget.assignment.id);
      
      // Group submissions by student
      Map<String, List<SubmissionModel>> submissionsByStudent = {};
      for (var sub in submissions) {
        if (!submissionsByStudent.containsKey(sub.studentId)) {
          submissionsByStudent[sub.studentId] = [];
        }
        submissionsByStudent[sub.studentId]!.add(sub);
      }

      // Build tracking data with group names
      List<SubmissionTrackingModel> trackingData = [];
      for (var student in students) {
        final studentSubs = submissionsByStudent[student.uid] ?? [];
        final groupName = await _databaseService.getStudentGroupNames(student.uid, widget.assignment);
        
        trackingData.add(SubmissionTrackingModel(
          student: student,
          submissions: studentSubs,
          groupName: groupName,
        ));
      }

      setState(() {
        _trackingData = trackingData;
        _filteredData = trackingData;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  void _applyFilters() {
    List<SubmissionTrackingModel> filtered = List.from(_trackingData);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.student.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.student.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.student.studentId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            item.groupName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Status filter
    switch (_filterStatus) {
      case 'submitted':
        filtered = filtered.where((item) => item.hasSubmitted).toList();
        break;
      case 'not_submitted':
        filtered = filtered.where((item) => !item.hasSubmitted).toList();
        break;
      case 'graded':
        filtered = filtered.where((item) => item.isGraded).toList();
        break;
      case 'late':
        filtered = filtered.where((item) => item.isLateSubmission).toList();
        break;
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.student.displayName.compareTo(b.student.displayName);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'attempts':
          comparison = a.totalAttempts.compareTo(b.totalAttempts);
          break;
        case 'score':
          final aScore = a.highestScore ?? -1;
          final bScore = b.highestScore ?? -1;
          comparison = aScore.compareTo(bScore);
          break;
        case 'time':
          final aTime = a.latestSubmission?.submittedAt ?? DateTime(1970);
          final bTime = b.latestSubmission?.submittedAt ?? DateTime(1970);
          comparison = aTime.compareTo(bTime);
          break;
        case 'group':
          comparison = a.groupName.compareTo(b.groupName);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() => _filteredData = filtered);
  }

  Future<void> _exportToCSV() async {
    try {
      final csv = await Provider.of<AssignmentProvider>(context, listen: false)
          .exportToCSV(widget.assignment.id, widget.assignment);

      // Create blob and download
      final bytes = csv.codeUnits;
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'assignment_${widget.assignment.id}_submissions.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully!')),
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
    final totalStudents = _trackingData.length;
    final submitted = _trackingData.where((t) => t.hasSubmitted).length;
    final notSubmitted = totalStudents - submitted;
    final graded = _trackingData.where((t) => t.isGraded).length;
    final late = _trackingData.where((t) => t.isLateSubmission).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrackingData,
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
                // Assignment Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.assignment.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.event, 'Due: ${DateFormat('MMM dd, HH:mm').format(widget.assignment.dueDate)}'),
                          _buildInfoChip(Icons.grade, '${widget.assignment.maxScore} pts'),
                          _buildInfoChip(Icons.repeat, 'Max ${widget.assignment.maxAttempts == 0 ? '∞' : widget.assignment.maxAttempts} attempts'),
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
                      Expanded(child: _buildStatCard('Submitted', submitted, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Not Submitted', notSubmitted, Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Graded', graded, Colors.purple)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Late', late, Colors.red)),
                    ],
                  ),
                ),

                // Search and Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, student ID, or group...',
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Filter and Sort Row
                      Row(
                        children: [
                          // Status Filter
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterStatus,
                              decoration: const InputDecoration(
                                labelText: 'Filter',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All')),
                                DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                                DropdownMenuItem(value: 'not_submitted', child: Text('Not Submitted')),
                                DropdownMenuItem(value: 'graded', child: Text('Graded')),
                                DropdownMenuItem(value: 'late', child: Text('Late')),
                              ],
                              onChanged: (value) {
                                setState(() => _filterStatus = value!);
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Sort By
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _sortBy,
                              decoration: const InputDecoration(
                                labelText: 'Sort By',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'name', child: Text('Name')),
                                DropdownMenuItem(value: 'group', child: Text('Group')),
                                DropdownMenuItem(value: 'status', child: Text('Status')),
                                DropdownMenuItem(value: 'attempts', child: Text('Attempts')),
                                DropdownMenuItem(value: 'score', child: Text('Score')),
                                DropdownMenuItem(value: 'time', child: Text('Time')),
                              ],
                              onChanged: (value) {
                                setState(() => _sortBy = value!);
                                _applyFilters();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Sort Direction
                          IconButton(
                            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                            onPressed: () {
                              setState(() => _sortAscending = !_sortAscending);
                              _applyFilters();
                            },
                            tooltip: _sortAscending ? 'Ascending' : 'Descending',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Results Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Showing ${_filteredData.length} of $totalStudents students',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Table
                Expanded(
                  child: _filteredData.isEmpty
                      ? const Center(child: Text('No results found'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: _buildDataTable(),
                          ),
                        ),
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

  Widget _buildStatCard(String label, int value, Color color) {
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

  Widget _buildDataTable() {
    return DataTable(
      columnSpacing: 20,
      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
      columns: const [
        DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Group', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Attempts', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Submitted At', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: _filteredData.map((item) {
        return DataRow(
          cells: [
            DataCell(Text(item.student.studentId ?? '-')),
            DataCell(Text(item.student.displayName)),
            DataCell(Text(item.student.email, style: const TextStyle(fontSize: 12))),
            DataCell(Text(item.groupName, style: const TextStyle(fontSize: 12))),
            DataCell(_buildStatusChip(item.status, item.isLateSubmission)),
            DataCell(Text('${item.totalAttempts}')),
            DataCell(Text(
              item.highestScore != null ? '${item.highestScore}/${widget.assignment.maxScore}' : '-',
              style: TextStyle(
                fontWeight: item.isGraded ? FontWeight.bold : null,
                color: item.isGraded ? Colors.green : null,
              ),
            )),
            DataCell(Text(
              item.latestSubmission != null
                  ? DateFormat('MMM dd, HH:mm').format(item.latestSubmission!.submittedAt)
                  : '-',
              style: const TextStyle(fontSize: 12),
            )),
            DataCell(
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _showSubmissionDetails(item),
                tooltip: 'View Details',
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status, bool isLate) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Graded':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Submitted':
      case 'Late submission':
        color = isLate ? Colors.orange : Colors.blue;
        icon = isLate ? Icons.warning : Icons.done;
        break;
      default:
        color = Colors.grey;
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSubmissionDetails(SubmissionTrackingModel item) {
    showDialog(
      context: context,
      builder: (context) => _SubmissionDetailsDialog(
        tracking: item,
        assignment: widget.assignment,
        onGraded: () {
          _loadTrackingData();
        },
      ),
    );
  }
}

// Submission Details Dialog
class _SubmissionDetailsDialog extends StatelessWidget {
  final SubmissionTrackingModel tracking;
  final AssignmentModel assignment;
  final VoidCallback onGraded;

  const _SubmissionDetailsDialog({
    required this.tracking,
    required this.assignment,
    required this.onGraded,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    tracking.student.displayName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(tracking.student.email, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 24),

            // Submission History
            if (tracking.submissions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No submissions yet'),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tracking.submissions.length,
                  itemBuilder: (context, index) {
                    final sub = tracking.submissions[index];
                    return _SubmissionAttemptCard(
                      submission: sub,
                      assignment: assignment,
                      onGraded: () {
                        Navigator.pop(context);
                        onGraded();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Individual Submission Attempt Card
class _SubmissionAttemptCard extends StatelessWidget {
  final SubmissionModel submission;
  final AssignmentModel assignment;
  final VoidCallback onGraded;

  const _SubmissionAttemptCard({
    required this.submission,
    required this.assignment,
    required this.onGraded,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: submission.isGraded ? Colors.green : Colors.blue,
          child: Text('${submission.attemptNumber}'),
        ),
        title: Text('Attempt ${submission.attemptNumber}'),
        subtitle: Text(
          'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(submission.submittedAt)}',
        ),
        trailing: submission.isLate
            ? const Icon(Icons.warning, color: Colors.orange, size: 20)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
// Attachments (around line 650 in the _SubmissionAttemptCard)
if (submission.attachmentUrls.isNotEmpty) ...[
  const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
  const SizedBox(height: 4),
  ...submission.attachmentUrls.map((url) {
    final fileName = url.split('/').last.split('?').first;
    final decodedName = Uri.decodeComponent(fileName);
    
    return Card(
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.attach_file, size: 20),
        title: Text(decodedName, style: const TextStyle(fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () {
                html.window.open(url, '_blank');
              },
              tooltip: 'Open',
            ),
            IconButton(
              icon: const Icon(Icons.download, size: 18),
              onPressed: () {
                final anchor = html.AnchorElement(href: url)
                  ..setAttribute('download', decodedName)
                  ..click();
              },
              tooltip: 'Download',
            ),
          ],
        ),
      ),
    );
  }).toList(),
  const SizedBox(height: 12),
],

                // Score
                if (submission.isGraded) ...[
                  Row(
                    children: [
                      const Text('Score: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${submission.score}/${assignment.maxScore}',
                        style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Feedback
                if (submission.feedback != null) ...[
                  const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(submission.feedback!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Grade Button
                ElevatedButton.icon(
                  onPressed: () => _showGradeDialog(context),
                  icon: Icon(submission.isGraded ? Icons.edit : Icons.grade),
                  label: Text(submission.isGraded ? 'Update Grade' : 'Grade Submission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: submission.isGraded ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGradeDialog(BuildContext context) {
    final scoreController = TextEditingController(text: submission.score?.toString() ?? '');
    final feedbackController = TextEditingController(text: submission.feedback ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Grade Attempt ${submission.attemptNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: scoreController,
                decoration: InputDecoration(
                  labelText: 'Score',
                  suffixText: '/ ${assignment.maxScore}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = int.tryParse(scoreController.text);
              if (score == null || score < 0 || score > assignment.maxScore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid score (0-${assignment.maxScore})'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
                
                await assignmentProvider.gradeSubmission(
                  submissionId: submission.id,
                  score: score,
                  feedback: feedbackController.text.trim().isEmpty ? null : feedbackController.text.trim(),
                  gradedBy: authProvider.user!.uid,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Graded successfully!')),
                  );
                }

                onGraded();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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