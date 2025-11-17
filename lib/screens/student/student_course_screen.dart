import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../../providers/auth_provider.dart';
import '../../models/course_model.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../models/material_model.dart';
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

                // Tabs
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(
                              icon: Icon(Icons.assignment),
                              text: 'Assignments',
                            ),
                            Tab(
                              icon: Icon(Icons.folder),
                              text: 'Materials',
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Assignments Tab
                              _buildAssignmentsTab(),

                              // Materials Tab
                              _StudentMaterialsTab(course: widget.course),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No assignments yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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

// Student Materials Tab
class _StudentMaterialsTab extends StatefulWidget {
  final CourseModel course;

  const _StudentMaterialsTab({required this.course});

  @override
  State<_StudentMaterialsTab> createState() => _StudentMaterialsTabState();
}

class _StudentMaterialsTabState extends State<_StudentMaterialsTab> {
  final DatabaseService _databaseService = DatabaseService();
  List<MaterialModel> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        final materials = await _databaseService.getStudentMaterials(
          authProvider.user!.uid,
          widget.course.id,
        );

        setState(() {
          _materials = materials;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No materials yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Text(
              'Your instructor will upload course materials here',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMaterials,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          final material = _materials[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    material.fileIcon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              title: Text(
                material.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    material.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.insert_drive_file, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          material.fileName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        material.fileSizeFormatted,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(material.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.teal),
                    onPressed: () {
                      html.window.open(material.fileUrl, '_blank');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening ${material.fileName}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Download',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}