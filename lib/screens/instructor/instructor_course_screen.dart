import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart';
import 'material_management_screen.dart';
import 'assignment_management_screen.dart';
import 'quiz_management_screen.dart';
import 'announcement_management_screen.dart';
import 'forum_list_screen.dart';
import 'group_management_screen.dart';

class InstructorCourseScreen extends StatelessWidget {
  final CourseModel course;

  const InstructorCourseScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Header
            if (course.coverImage != null)
              Image.network(
                course.coverImage! ,
                height: 200,
                width: double.infinity,
                fit: BoxFit. cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultHeader(),
              )
            else
              _buildDefaultHeader(),

            // Course Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course. code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course. name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (course.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      course.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors. grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.sessions} sessions',
                        style: TextStyle(fontSize: 14, color: Colors. grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons. calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(course.createdAt),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Course Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Groups - FIXED: Pass course
                  _CourseActionCard(
                    icon: Icons.groups,
                    title: 'Groups',
                    subtitle: 'Manage student groups',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupManagementScreen(
                            preselectedCourse: course, // ← Pass the course
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Materials - FIXED: Pass course
                  _CourseActionCard(
                    icon: Icons.folder,
                    title: 'Materials',
                    subtitle: 'Upload and manage course materials',
                    color: Colors.teal,
                    onTap: () {
                      Navigator. push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MaterialManagementScreen(
                            preselectedCourse: course, // ← Pass the course
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Assignments - FIXED: Pass course
                  _CourseActionCard(
                    icon: Icons.assignment,
                    title: 'Assignments',
                    subtitle: 'Create and grade assignments',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignmentManagementScreen(
                            preselectedCourse: course, // ← Pass the course
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quizzes - FIXED: Pass course
                  _CourseActionCard(
                    icon: Icons.quiz,
                    title: 'Quizzes',
                    subtitle: 'Create and manage quizzes',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator. push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizManagementScreen(
                            preselectedCourse: course, // ← Pass the course
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Announcements - FIXED: Pass course
                  _CourseActionCard(
                    icon: Icons.campaign,
                    title: 'Announcements',
                    subtitle: 'Post updates and announcements',
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnnouncementManagementScreen(
                            preselectedCourse: course, // ← Pass the course
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forums - Already has course! 
                  _CourseActionCard(
                    icon: Icons. forum,
                    title: 'Forums',
                    subtitle: 'Course discussions and Q&A',
                    color: Colors. orange,
                    onTap: () {
                      Navigator. push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForumListScreen(course: course),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
      ),
      child: const Center(
        child: Icon(Icons.book, size: 80, color: Colors. white),
      ),
    );
  }
}

class _CourseActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CourseActionCard({
    required this.icon,
    required this.title,
    required this. subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}