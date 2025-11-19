import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/semester_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/question_model.dart';
import '../../models/course_model.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  CourseModel? _selectedCourse;
  QuestionDifficulty? _filterDifficulty;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      if (semesterProvider.currentSemester != null) {
        courseProvider.loadCoursesBySemester(semesterProvider.currentSemester!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank'),
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

          return Column(
            children: [
              // Course Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.purple.shade50,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose a course'),
                      items: courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text('${course.code} - ${course.name}'),
                        );
                      }).toList(),
                      onChanged: (course) {
                        setState(() {
                          _selectedCourse = course;
                          _filterDifficulty = null;
                          _searchQuery = '';
                        });
                        if (course != null) {
                          quizProvider.loadQuestionsByCourse(course.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Filters
              if (_selectedCourse != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search questions...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Difficulty filter
                      DropdownButton<QuestionDifficulty?>(
                        value: _filterDifficulty,
                        hint: const Text('Difficulty'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          ...QuestionDifficulty.values.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d.toString().split('.').last),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filterDifficulty = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Questions List
              Expanded(
                child: _selectedCourse == null
                    ? const Center(child: Text('Please select a course'))
                    : quizProvider.isLoadingQuestions
                        ? const Center(child: CircularProgressIndicator())
                        : _buildQuestionsList(quizProvider.questions),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _selectedCourse != null
          ? FloatingActionButton.extended(
              onPressed: () => _showQuestionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Question'),
            )
          : null,
    );
  }

  Widget _buildQuestionsList(List<QuestionModel> questions) {
    // Apply filters
    var filteredQuestions = questions.where((q) {
      if (_filterDifficulty != null && q.difficulty != _filterDifficulty) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !q.question.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    if (filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No questions yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            const Text('Start building your question bank', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    // Group by difficulty
    final easyQuestions = filteredQuestions.where((q) => q.difficulty == QuestionDifficulty.easy).toList();
    final mediumQuestions = filteredQuestions.where((q) => q.difficulty == QuestionDifficulty.medium).toList();
    final hardQuestions = filteredQuestions.where((q) => q.difficulty == QuestionDifficulty.hard).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistics
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip('Total', filteredQuestions.length, Colors.blue),
                _buildStatChip('Easy', easyQuestions.length, Colors.green),
                _buildStatChip('Medium', mediumQuestions.length, Colors.orange),
                _buildStatChip('Hard', hardQuestions.length, Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Questions
        ...filteredQuestions.map((question) => _QuestionCard(
              question: question,
              onEdit: () => _showQuestionDialog(context, question: question),
            )),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  void _showQuestionDialog(BuildContext context, {QuestionModel? question}) {
    showDialog(
      context: context,
      builder: (context) => _QuestionFormDialog(
        courseId: _selectedCourse!.id,
        question: question,
      ),
    );
  }
}

// Question Card Widget
class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final VoidCallback onEdit;

  const _QuestionCard({required this.question, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: question.difficultyColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: question.difficultyColor),
          ),
          child: Text(
            question.difficultyLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: question.difficultyColor,
            ),
          ),
        ),
        title: Text(question.question, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              _showDeleteDialog(context, quizProvider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choices:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...question.choices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final choice = entry.value;
                  final isCorrect = index == question.correctAnswerIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.grey.shade300,
                        width: isCorrect ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCorrect ? Colors.green : Colors.grey.shade400,
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(choice)),
                        if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, QuizProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Delete this question?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteQuestion(question.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question deleted')),
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

// Question Form Dialog
class _QuestionFormDialog extends StatefulWidget {
  final String courseId;
  final QuestionModel? question;

  const _QuestionFormDialog({required this.courseId, this.question});

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _choiceControllers = List.generate(4, (_) => TextEditingController());
  
  QuestionDifficulty _difficulty = QuestionDifficulty.medium;
  int _correctAnswerIndex = 0;
  bool _isSaving = false;

  bool get isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _questionController.text = widget.question!.question;
      _difficulty = widget.question!.difficulty;
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
      
      for (int i = 0; i < widget.question!.choices.length && i < 4; i++) {
        _choiceControllers[i].text = widget.question!.choices[i];
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final choices = _choiceControllers.map((c) => c.text.trim()).toList();

      if (isEditing) {
        await quizProvider.updateQuestion(
          widget.question!.copyWith(
            question: _questionController.text.trim(),
            choices: choices,
            correctAnswerIndex: _correctAnswerIndex,
            difficulty: _difficulty,
          ),
        );
      } else {
        final newQuestion = QuestionModel(
          id: '',
          courseId: widget.courseId,
          question: _questionController.text.trim(),
          choices: choices,
          correctAnswerIndex: _correctAnswerIndex,
          difficulty: _difficulty,
          createdBy: authProvider.user!.uid,
          createdAt: DateTime.now(),
        );

        await quizProvider.createQuestion(newQuestion);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Question updated' : 'Question added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Question' : 'Add Question',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      TextFormField(
                        controller: _questionController,
                        decoration: const InputDecoration(
                          labelText: 'Question *',
                          hintText: 'Enter your question...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Difficulty
                      DropdownButtonFormField<QuestionDifficulty>(
                        value: _difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty *',
                          border: OutlineInputBorder(),
                        ),
                        items: QuestionDifficulty.values.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text(d.toString().split('.').last.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _difficulty = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Choices
                      const Text('Choices *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._choiceControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final controller = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: _correctAnswerIndex,
                                onChanged: (value) {
                                  setState(() => _correctAnswerIndex = value!);
                                },
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: 'Choice ${String.fromCharCode(65 + index)}',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Select the correct answer using the radio button',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'UPDATE' : 'ADD'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}