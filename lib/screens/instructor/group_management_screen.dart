import 'package:educate_classroom/screens/instructor/group_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/group_model.dart';
import '../../models/course_model.dart';
import 'group_students_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  final CourseModel? preselectedCourse;

  const GroupManagementScreen({
    super.key,
    this.preselectedCourse,
  });

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  CourseModel? _selectedCourse;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      if (semesterProvider.currentSemester != null) {
        courseProvider.loadCoursesBySemester(semesterProvider.currentSemester!. id);
      }
      
      studentProvider.initialize();
      
      // If preselected course exists, just load its groups
      if (widget.preselectedCourse != null) {
        groupProvider.loadGroupsByCourse(widget.preselectedCourse!. id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.preselectedCourse != null
            ? Text('Groups - ${widget.preselectedCourse!.name}')
            : const Text('Group Management'),
      ),
      body: Consumer3<SemesterProvider, CourseProvider, GroupProvider>(
        builder: (context, semesterProvider, courseProvider, groupProvider, child) {
          if (semesterProvider.currentSemester == null) {
            return const Center(
              child: Text('Please create a semester first'),
            );
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
                  SizedBox(height: 8),
                  Text('Please create a course first'),
                ],
              ),
            );
          }

          // If we have a preselected course, skip the dropdown entirely
          if (widget.preselectedCourse != null) {
            return _buildGroupsList(
              groupProvider. groups,
              groupProvider.isLoading,
              widget.preselectedCourse!,
            );
          }

          // Otherwise show the course selector
          return Column(
            children: [
              // Course Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue. shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Course',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors. grey[600],
                      ),
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
                        setState(() {
                          _selectedCourse = course;
                        });
                        if (course != null) {
                          groupProvider.loadGroupsByCourse(course.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Groups List
              Expanded(
                child: _selectedCourse == null
                    ? const Center(
                        child: Text('Please select a course'),
                      )
                    : _buildGroupsList(
                        groupProvider.groups,
                        groupProvider.isLoading,
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
                    builder: (_) => GroupFormScreen(
                      courseId: courseId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Group'),
            )
          : null,
    );
  }

  Widget _buildGroupsList(List<GroupModel> groups, bool isLoading, CourseModel course) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create groups to organize students',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _GroupCard(
          group: groups[index],
          courseId: course.id,
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final String courseId;

  const _GroupCard({
    required this.group,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator. push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupStudentsScreen(group: group),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons. group,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.studentCount} student${group.studentCount != 1 ? 's' : ''}',
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

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupFormScreen(
                            courseId: courseId,
                            group: group,
                          ),
                        ),
                      );
                      break;
                    case 'manage':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupStudentsScreen(group: group),
                        ),
                      );
                      break;
                    case 'delete':
                      _showDeleteDialog(context, groupProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'manage',
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 20),
                        SizedBox(width: 8),
                        Text('Manage Students'),
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
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, GroupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"?\n\n'
          'Students will be removed from this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await provider.deleteGroup(group.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group deleted successfully'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}