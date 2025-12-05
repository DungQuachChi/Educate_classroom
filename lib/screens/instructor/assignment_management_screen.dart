import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import 'assignment_form_screen.dart';
import 'assignment_tracking_screen.dart';

class AssignmentManagementScreen extends StatefulWidget {
  final CourseModel? preselectedCourse;

  const AssignmentManagementScreen({
    super.key,
    this.preselectedCourse,
  });

  @override
  State<AssignmentManagementScreen> createState() => _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen> {
  CourseModel? _selectedCourse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

      if (semesterProvider.currentSemester != null) {
        courseProvider.loadCoursesBySemester(semesterProvider.currentSemester!. id);
      }

      if (widget. preselectedCourse != null) {
        assignmentProvider.loadAssignmentsByCourse(widget.preselectedCourse!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.preselectedCourse != null
            ? Text('Assignments - ${widget.preselectedCourse!.name}')
            : const Text('Assignment Management'),
      ),
      body: Consumer3<SemesterProvider, CourseProvider, AssignmentProvider>(
        builder: (context, semesterProvider, courseProvider, assignmentProvider, child) {
          if (semesterProvider.currentSemester == null) {
            return const Center(child: Text('Please create a semester first'));
          }

          if (courseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = courseProvider.courses;

          if (courses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No courses available'),
                ],
              ),
            );
          }
          if (widget.preselectedCourse != null) {
            return _buildAssignmentsList(
              assignmentProvider. assignments,
              assignmentProvider.isLoading,
              widget.preselectedCourse! ,
            );
          }
          return Column(
            children: [
              // Course Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.purple. shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Course',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CourseModel>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets. symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose a course'),
                      items: courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text('${course.code} - ${course.name}'),
                        );
                      }). toList(),
                      onChanged: (course) {
                        setState(() => _selectedCourse = course);
                        if (course != null) {
                          assignmentProvider.loadAssignmentsByCourse(course.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Assignments List
              Expanded(
                child: _selectedCourse == null
                    ? const Center(child: Text('Please select a course'))
                    : _buildAssignmentsList(
                        assignmentProvider.assignments,
                        assignmentProvider.isLoading,
                        _selectedCourse!,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: (widget.preselectedCourse != null || _selectedCourse != null)
          ? FloatingActionButton. extended(
              onPressed: () {
                final courseId = widget.preselectedCourse?. id ??  _selectedCourse! .id;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssignmentFormScreen(courseId: courseId),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Assignment'),
            )
          : null,
    );
  }

  Widget _buildAssignmentsList(List<AssignmentModel> assignments, bool isLoading, CourseModel course) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No assignments yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Text(
              'Create assignments for students to submit',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        return _AssignmentCard(
          assignment: assignments[index],
          courseId: course.id,
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final String courseId;

  const _AssignmentCard({required this.assignment, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = assignment.statusText;

    if (assignment. isPastLateDeadline) {
      statusColor = Colors.grey;
      statusIcon = Icons. lock;
    } else if (assignment.isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else if (assignment.isDueSoon) {
      statusColor = Colors.orange;
      statusIcon = Icons.timer;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator. push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignmentTrackingScreen(assignment: assignment),
            ),
          );
        },
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentFormScreen(
                                courseId: courseId,
                                assignment: assignment,
                              ),
                            ),
                          );
                          break;
                        case 'track':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssignmentTrackingScreen(assignment: assignment),
                            ),
                          );
                          break;
                        case 'delete':
                          _showDeleteDialog(context, assignmentProvider);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'track',
                        child: Row(
                          children: [
                            Icon(Icons.list_alt, size: 20),
                            SizedBox(width: 8),
                            Text('Track Submissions'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Start: ${DateFormat('MMM dd, HH:mm').format(assignment.startDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM dd, HH:mm').format(assignment. dueDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (assignment.allowLateSubmission && assignment.lateDeadline != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.orange[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Late: ${DateFormat('MMM dd, HH:mm').format(assignment.lateDeadline!)}',
                          style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Max ${assignment.maxAttempts == 0 ? '∞' : assignment.maxAttempts} attempt${assignment.maxAttempts != 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grade, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${assignment.maxScore} pts', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AssignmentProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Delete "${assignment.title}"?\n\nAll submissions will be deleted. '),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteAssignment(assignment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Assignment deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}