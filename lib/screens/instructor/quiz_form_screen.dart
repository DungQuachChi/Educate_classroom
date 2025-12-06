import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/quiz_model.dart';
import '../../models/question_model.dart';

class QuizFormScreen extends StatefulWidget {
  final String courseId;
  final QuizModel? quiz;

  const QuizFormScreen({super.key, required this.courseId, this.quiz});

  @override
  State<QuizFormScreen> createState() => _QuizFormScreenState();
}

class _QuizFormScreenState extends State<QuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _easyCountController = TextEditingController();
  final _mediumCountController = TextEditingController();
  final _hardCountController = TextEditingController();

  DateTime _openTime = DateTime.now();
  TimeOfDay _openTimeOfDay = TimeOfDay.now();
  DateTime _closeTime = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _closeTimeOfDay = const TimeOfDay(hour: 23, minute: 59);

  int _maxAttempts = 1;
  List<String> _selectedGroupIds = [];
  bool _randomizeQuestions = true;
  bool _randomizeChoices = true;
  bool _isSaving = false;
  bool get isEditing => widget.quiz != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      groupProvider.loadGroupsByCourse(widget.courseId);
      quizProvider.forceReloadQuestions(widget.courseId);
    });

    if (isEditing) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _durationController.text = widget.quiz!.durationMinutes.toString();
      _easyCountController.text = widget.quiz!.structure.easyCount.toString();
      _mediumCountController.text = widget.quiz!.structure.mediumCount
          .toString();
      _hardCountController.text = widget.quiz!.structure.hardCount.toString();

      _openTime = widget.quiz!.openTime;
      _openTimeOfDay = TimeOfDay.fromDateTime(widget.quiz!.openTime);
      _closeTime = widget.quiz!.closeTime;
      _closeTimeOfDay = TimeOfDay.fromDateTime(widget.quiz!.closeTime);
      _maxAttempts = widget.quiz!.maxAttempts;
      _selectedGroupIds = List.from(widget.quiz!.groupIds);
      _randomizeQuestions = widget.quiz!.randomizeQuestions;
      _randomizeChoices = widget.quiz!.randomizeChoices;
    } else {
      _durationController.text = '60';
      _easyCountController.text = '0';
      _mediumCountController.text = '0';
      _hardCountController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _easyCountController.dispose();
    _mediumCountController.dispose();
    _hardCountController.dispose();
    super.dispose();
  }

  Future<void> _selectOpenDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _openTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _openTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _openTimeOfDay.hour,
          _openTimeOfDay.minute,
        );
      });
    }
  }

  Future<void> _selectOpenTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openTimeOfDay,
    );
    if (picked != null) {
      setState(() {
        _openTimeOfDay = picked;
        _openTime = DateTime(
          _openTime.year,
          _openTime.month,
          _openTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectCloseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _closeTime,
      firstDate: _openTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _closeTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _closeTimeOfDay.hour,
          _closeTimeOfDay.minute,
        );
      });
    }
  }

  Future<void> _selectCloseTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _closeTimeOfDay,
    );
    if (picked != null) {
      setState(() {
        _closeTimeOfDay = picked;
        _closeTime = DateTime(
          _closeTime.year,
          _closeTime.month,
          _closeTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  // Validate dates
  if (_closeTime.isBefore(_openTime)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Close time must be after open time'),
        backgroundColor: Colors. red,
      ),
    );
    return;
  }

  // Validate question counts
  final easyCount = int.parse(_easyCountController.text);
  final mediumCount = int.parse(_mediumCountController. text);
  final hardCount = int.parse(_hardCountController. text);

  if (easyCount + mediumCount + hardCount == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add at least one question'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final quizProvider = Provider.of<QuizProvider>(context, listen: false);
  final questions = quizProvider.questions;
  final availableEasy = questions
      .where((q) => q.difficulty == QuestionDifficulty.easy)
      .length;
  final availableMedium = questions
      . where((q) => q.difficulty == QuestionDifficulty. medium)
      .length;
  final availableHard = questions
      .where((q) => q.difficulty == QuestionDifficulty.hard)
      . length;

  if (easyCount > availableEasy) {
    ScaffoldMessenger. of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Not enough easy questions (available: $availableEasy)',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (mediumCount > availableMedium) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Not enough medium questions (available: $availableMedium)',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

<<<<<<< HEAD
  if (hardCount > availableHard) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Not enough hard questions (available: $availableHard)',
=======
    // ← CHANGED: Get available counts from provider
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final questions = quizProvider.questions;
    final availableEasy = questions
        .where((q) => q.difficulty == QuestionDifficulty.easy)
        .length;
    final availableMedium = questions
        .where((q) => q.difficulty == QuestionDifficulty.medium)
        .length;
    final availableHard = questions
        .where((q) => q.difficulty == QuestionDifficulty.hard)
        .length;

    if (easyCount > availableEasy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough easy questions (available: $availableEasy)',
          ),
          backgroundColor: Colors.red,
>>>>>>> 4f8b7139c2e35257fd233404af4a63349c388fd9
        ),
        backgroundColor: Colors. red,
      ),
    );
    return;
  }

<<<<<<< HEAD
  setState(() => _isSaving = true);
  
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  try {
    final structure = QuizStructure(
      easyCount: easyCount,
      mediumCount: mediumCount,
      hardCount: hardCount,
    );

    // Randomly select questions
    final questionIds = await quizProvider.selectRandomQuestions(
      widget.courseId,
      structure,
    );

    if (isEditing) {
      // Update existing quiz
      await quizProvider.updateQuiz(
        widget.quiz! .copyWith(
          title: _titleController.text. trim(),
          description: _descriptionController.text.trim(),
          openTime: _openTime,
          closeTime: _closeTime,
          durationMinutes: int.parse(_durationController.text),
          maxAttempts: _maxAttempts,
          structure: structure,
          questionIds: questionIds,
          randomizeQuestions: _randomizeQuestions,
          randomizeChoices: _randomizeChoices,
          groupIds: _selectedGroupIds,
        ),
      );
    } else {
      // Create new quiz
      final newQuiz = QuizModel(
        id: '',
        title: _titleController. text.trim(),
        description: _descriptionController.text.trim(),
        courseId: widget.courseId,
        groupIds: _selectedGroupIds,
        openTime: _openTime,
        closeTime: _closeTime,
        durationMinutes: int.parse(_durationController. text),
        maxAttempts: _maxAttempts,
        structure: structure,
        questionIds: questionIds,
        randomizeQuestions: _randomizeQuestions,
        randomizeChoices: _randomizeChoices,
        createdBy: authProvider.user!.uid,
        createdAt: DateTime.now(),
      );

      await quizProvider.createQuiz(newQuiz);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Quiz updated successfully' : 'Quiz created successfully'),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors. red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
=======
    if (mediumCount > availableMedium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough medium questions (available: $availableMedium)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hardCount > availableHard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough hard questions (available: $availableHard)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);


>>>>>>> 4f8b7139c2e35257fd233404af4a63349c388fd9
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Quiz' : 'New Quiz')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Midterm Exam',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the quiz...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Open Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Open Time *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectOpenDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('MMM dd, yyyy').format(_openTime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectOpenTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_openTimeOfDay.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Close Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Close Time *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectCloseDate,
                            icon: const Icon(Icons.event),
                            label: Text(
                              DateFormat('MMM dd, yyyy').format(_closeTime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectCloseTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(_closeTimeOfDay.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration & Attempts
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (min) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final duration = int.tryParse(value);
                      if (duration == null || duration <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _maxAttempts,
                    decoration: const InputDecoration(
                      labelText: 'Max Attempts *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 0,
                        child: Text('Unlimited'),
                      ),
                      ...List.generate(5, (i) => i + 1).map(
                        (n) => DropdownMenuItem(value: n, child: Text('$n')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _maxAttempts = value ?? 1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quiz Structure - FIXED with Consumer
            Consumer<QuizProvider>(
              builder: (context, quizProvider, child) {
                // Calculate available questions from provider
                final questions = quizProvider.questions;
                final availableEasy = questions
                    .where((q) => q.difficulty == QuestionDifficulty.easy)
                    .length;
                final availableMedium = questions
                    .where((q) => q.difficulty == QuestionDifficulty.medium)
                    .length;
                final availableHard = questions
                    .where((q) => q.difficulty == QuestionDifficulty.hard)
                    .length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quiz Structure',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Questions will be randomly selected',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        // Easy Questions
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _easyCountController,
                                decoration: InputDecoration(
                                  labelText: 'Easy Questions',
                                  border: const OutlineInputBorder(),
                                  suffixText: '/ $availableEasy',
                                  prefixIcon: const Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final count = int.tryParse(value);
                                  if (count == null || count < 0)
                                    return 'Invalid';
                                  if (count > availableEasy) {
                                    return 'Max $availableEasy available';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Medium Questions
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mediumCountController,
                                decoration: InputDecoration(
                                  labelText: 'Medium Questions',
                                  border: const OutlineInputBorder(),
                                  suffixText: '/ $availableMedium',
                                  prefixIcon: const Icon(
                                    Icons.circle,
                                    color: Colors.orange,
                                    size: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final count = int.tryParse(value);
                                  if (count == null || count < 0)
                                    return 'Invalid';
                                  if (count > availableMedium) {
                                    return 'Max $availableMedium available';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Hard Questions
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _hardCountController,
                                decoration: InputDecoration(
                                  labelText: 'Hard Questions',
                                  border: const OutlineInputBorder(),
                                  suffixText: '/ $availableHard',
                                  prefixIcon: const Icon(
                                    Icons.circle,
                                    color: Colors.red,
                                    size: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final count = int.tryParse(value);
                                  if (count == null || count < 0)
                                    return 'Invalid';
                                  if (count > availableHard) {
                                    return 'Max $availableHard available';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quiz Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Randomize Question Order'),
                      subtitle: const Text('Each student gets different order'),
                      value: _randomizeQuestions,
                      onChanged: (value) {
                        setState(() => _randomizeQuestions = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Randomize Choice Order'),
                      subtitle: const Text(
                        'Shuffle A, B, C, D for each student',
                      ),
                      value: _randomizeChoices,
                      onChanged: (value) {
                        setState(() => _randomizeChoices = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Groups
            Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                final groups = groupProvider.groups;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign to Groups',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Leave empty for all students',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        if (groups.isEmpty)
                          const Text(
                            'No groups available',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: groups.map((group) {
                              final isSelected = _selectedGroupIds.contains(
                                group.id,
                              );
                              return FilterChip(
                                label: Text(group.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedGroupIds.add(group.id);
                                    } else {
                                      _selectedGroupIds.remove(group.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'UPDATE QUIZ' : 'CREATE QUIZ',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
