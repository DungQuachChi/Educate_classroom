import 'package:educate_classroom/screens/instructor/announcement_management_screen.dart';
import 'package:educate_classroom/screens/instructor/assignment_management_screen.dart';
import 'package:educate_classroom/screens/instructor/group_management_screen.dart';
import 'package:educate_classroom/screens/instructor/material_management_screen.dart';
import 'package:educate_classroom/screens/instructor/question_bank_screen.dart';
import 'package:educate_classroom/screens/instructor/quiz_management_screen.dart';
import 'package:educate_classroom/screens/instructor/student_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/semester_provider.dart';
import '../auth/login_screen.dart';
import 'semester_management_screen.dart';
import 'course_management_screen.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      if (semesterProvider.semesters.isEmpty && !semesterProvider.isLoading) {
        semesterProvider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final semesterProvider = Provider.of<SemesterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: semesterProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Text(
                    'Welcome, ${authProvider.user?.displayName ?? "Instructor"}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (semesterProvider.currentSemester != null)
                    Text(
                      'Current Semester: ${semesterProvider.currentSemester!.name}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    Text(
                      'No semester created yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Management Cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _DashboardCard(
                          icon: Icons.calendar_today,
                          title: 'Semesters',
                          subtitle: '${semesterProvider.semesters.length} total',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SemesterManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.book,
                          title: 'Courses',
                          subtitle: 'Manage courses',
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CourseManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.group,
                          title: 'Students',
                          subtitle: 'Manage students',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.groups,
                          title: 'Groups',
                          subtitle: 'Manage groups',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GroupManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.assignment,
                          title: 'Assignments',
                          subtitle: 'Manage assignments',
                          color: Colors.red,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssignmentManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.folder,
                          title: 'Materials',
                          subtitle: 'Upload materials',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MaterialManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.quiz,
                          title: 'Question Bank',
                          subtitle: 'Manage questions',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuestionBankScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.assignment_turned_in,
                          title: 'Quizzes',
                          subtitle: 'Create & track',
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuizManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _DashboardCard(
                          icon: Icons.campaign,
                          title: 'Announcements',
                          subtitle: 'Post updates',
                          color: Colors.deepPurple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnnouncementManagementScreen(),
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
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}