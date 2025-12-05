import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/course_model.dart';
import 'quiz_form_screen.dart';
import 'quiz_tracking_screen.dart';

class QuizManagementScreen extends StatefulWidget {
  final CourseModel? preselectedCourse; // ← ADD THIS

  const QuizManagementScreen({
    super.key,
    this.preselectedCourse, // ← ADD THIS
  });

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen> {
  CourseModel? _selectedCourse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      if (semesterProvider.currentSemester != null) {
        courseProvider.loadCoursesBySemester(semesterProvider.currentSemester!.  id);
      }

      // ← Auto-load quizzes if course is preselected
      if (widget. preselectedCourse != null) {
        quizProvider.loadQuizzesByCourse(widget.preselectedCourse!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.preselectedCourse != null
            ? Text('Quizzes - ${widget.preselectedCourse!.name}') // ← Show course name
            : const Text('Quiz Management'),
      ),
      body: Consumer3<SemesterProvider, CourseProvider, QuizProvider>(
        builder: (context, semesterProvider, courseProvider, quizProvider, child) {
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

          // ← If preselected course, skip dropdown
          if (widget.preselectedCourse != null) {
            return _buildQuizzesList(
              quizProvider.  quizzes,
              quizProvider.isLoadingQuizzes,
              widget.preselectedCourse!,
            );
          }

          // Otherwise show course selector
          return Column(
            children: [
              // Course Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.indigo.  shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Course', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CourseModel>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.  symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose a course'),
                      items: courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text('${course.code} - ${course.name}'),
                        );
                      }).  toList(),
                      onChanged: (course) {
                        setState(() => _selectedCourse = course);
                        if (course != null) {
                          quizProvider.loadQuizzesByCourse(course.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Quizzes List
              Expanded(
                child: _selectedCourse == null
                    ? const Center(child: Text('Please select a course'))
                    : _buildQuizzesList(
                        quizProvider.quizzes,
                        quizProvider.isLoadingQuizzes,
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
                    builder: (_) => QuizFormScreen(courseId: courseId),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('New Quiz'),
            )
          : null,
    );
  }

  Widget _buildQuizzesList(List<QuizModel> quizzes, bool isLoading, CourseModel course) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No quizzes yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Text(
              'Create quizzes to assess student knowledge',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        return _QuizCard(
          quiz: quizzes[index],
          courseId: course.id,
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final String courseId;

  const _QuizCard({required this.quiz, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pending;

    if (quiz.isOpen) {
      statusColor = Colors.green;
      statusIcon = Icons. play_circle;
    } else if (quiz. isUpcoming) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    } else if (quiz.isClosed) {
      statusColor = Colors.red;
      statusIcon = Icons.lock;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator. push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizTrackingScreen(quiz: quiz),
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
                      quiz.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          quiz.statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'track':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizTrackingScreen(quiz: quiz),
                            ),
                          );
                          break;
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizFormScreen(
                                courseId: courseId,
                                quiz: quiz,
                              ),
                            ),
                          );
                          break;
                        case 'delete':
                          _showDeleteDialog(context, quizProvider);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'track',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 20),
                            SizedBox(width: 8),
                            Text('View Results'),
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
                quiz.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.calendar_today, 'Open: ${DateFormat('MMM dd, HH:mm').format(quiz. openTime)}'),
                  _buildInfoChip(Icons.event, 'Close: ${DateFormat('MMM dd, HH:mm').format(quiz.closeTime)}'),
                  _buildInfoChip(Icons.timer, '${quiz. durationMinutes} min'),
                  _buildInfoChip(Icons. quiz, '${quiz.totalQuestions} questions'),
                  _buildInfoChip(Icons. repeat, 'Max ${quiz.maxAttempts == 0 ? '∞' : quiz.maxAttempts} attempts'),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors. grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildDifficultyBadge('Easy', quiz.structure.easyCount, Colors.green),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge('Medium', quiz.structure.mediumCount, Colors.orange),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge('Hard', quiz.structure.hardCount, Colors. red),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildDifficultyBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight. bold, color: color),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, QuizProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Delete "${quiz.title}"?\n\nAll student attempts will be deleted. '),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteQuiz(quiz.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz deleted')),
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