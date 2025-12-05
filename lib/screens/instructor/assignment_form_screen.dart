import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/assignment_model.dart';
import '../../models/group_model.dart';

class AssignmentFormScreen extends StatefulWidget {
  final String courseId;
  final AssignmentModel? assignment;

  const AssignmentFormScreen({
    super.key,
    required this.courseId,
    this.assignment,
  });

  @override
  State<AssignmentFormScreen> createState() => _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends State<AssignmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _maxFileSizeController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  DateTime? _lateDeadline;
  TimeOfDay? _lateTime;
  
  bool _allowLateSubmission = false;
  int _maxAttempts = 1;
  List<String> _selectedGroupIds = [];
  List<String> _selectedFileFormats = [];
  bool _isSaving = false;

  final List<String> _availableFormats = [
    'pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'zip', 'rar'
  ];

  bool get isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.loadGroupsByCourse(widget.courseId);
    });

    if (isEditing) {
      _titleController.text = widget.assignment!.title;
      _descriptionController.text = widget.assignment!.description;
      _maxScoreController.text = widget.assignment!.maxScore.toString();
      _maxFileSizeController.text = widget.assignment!.maxFileSizeMB.toString();
      
      _startDate = widget.assignment!.startDate;
      _startTime = TimeOfDay.fromDateTime(widget.assignment!.startDate);
      _dueDate = widget.assignment!.dueDate;
      _dueTime = TimeOfDay.fromDateTime(widget.assignment!.dueDate);
      _allowLateSubmission = widget.assignment!.allowLateSubmission;
      _lateDeadline = widget.assignment!.lateDeadline;
      _lateTime = widget.assignment!.lateDeadline != null 
          ? TimeOfDay.fromDateTime(widget.assignment!.lateDeadline!) 
          : null;
      _maxAttempts = widget.assignment!.maxAttempts;
      _selectedGroupIds = List.from(widget.assignment!.groupIds);
      _selectedFileFormats = List.from(widget.assignment!.allowedFileFormats);
    } else {
      _maxScoreController.text = '100';
      _maxFileSizeController.text = '10';
      _lateDeadline = _dueDate.add(const Duration(days: 2));
      _lateTime = _dueTime;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    _maxFileSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateTime(picked.year, picked.month, picked.day, _startTime.hour, _startTime.minute);
      });
    }
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day, _dueTime.hour, _dueTime.minute);
        if (_allowLateSubmission && _lateDeadline != null && _lateDeadline!.isBefore(_dueDate)) {
          _lateDeadline = _dueDate.add(const Duration(days: 2));
        }
      });
    }
  }

  Future<void> _selectDueTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _dueTime);
    if (picked != null) {
      setState(() {
        _dueTime = picked;
        _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _selectLateDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lateDeadline ?? _dueDate.add(const Duration(days: 2)),
      firstDate: _dueDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && _lateTime != null) {
      setState(() {
        _lateDeadline = DateTime(picked.year, picked.month, picked.day, _lateTime!.hour, _lateTime!.minute);
      });
    }
  }

  Future<void> _selectLateTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _lateTime ?? _dueTime,
    );
    if (picked != null) {
      setState(() {
        _lateTime = picked;
        if (_lateDeadline == null) {
          _lateDeadline = _dueDate.add(const Duration(days: 2));
        }
        _lateDeadline = DateTime(
          _lateDeadline!.year,
          _lateDeadline!.month,
          _lateDeadline!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_dueDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Due date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_allowLateSubmission && _lateDeadline != null && _lateDeadline!.isBefore(_dueDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Late deadline must be after due date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    try {
      if (isEditing) {
        await assignmentProvider.updateAssignment(
          widget.assignment!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            startDate: _startDate,
            dueDate: _dueDate,
            allowLateSubmission: _allowLateSubmission,
            lateDeadline: _allowLateSubmission ? _lateDeadline : null,
            maxAttempts: _maxAttempts,
            groupIds: _selectedGroupIds,
            allowedFileFormats: _selectedFileFormats,
            maxFileSizeMB: int.parse(_maxFileSizeController.text),
            maxScore: int.parse(_maxScoreController.text),
          ),
        );
      } else {
        final newAssignment = AssignmentModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          courseId: widget.courseId,
          groupIds: _selectedGroupIds,
          startDate: _startDate,
          dueDate: _dueDate,
          allowLateSubmission: _allowLateSubmission,
          lateDeadline: _allowLateSubmission ? _lateDeadline : null,
          maxAttempts: _maxAttempts,
          allowedFileFormats: _selectedFileFormats,
          maxFileSizeMB: int.parse(_maxFileSizeController.text),
          maxScore: int.parse(_maxScoreController.text),
          createdAt: DateTime.now(),
        );
        await assignmentProvider.createAssignment(newAssignment);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Assignment updated' : 'Assignment created')),
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
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Assignment' : 'New Assignment')),
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
                hintText: 'e.g., Homework 1: Variables',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the assignment...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Start Date & Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Date & Time *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectStartDate,
                            icon: const Icon(Icons.calendar_today),
                            label: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectStartTime,
                            icon: const Icon(Icons.access_time),
                            label: Text(_startTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Due Date & Time
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Due Date & Time *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDueDate,
                            icon: const Icon(Icons.event),
                            label: Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectDueTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(_dueTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Late Submission
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Allow Late Submission'),
                      value: _allowLateSubmission,
                      onChanged: (value) {
                        setState(() {
                          _allowLateSubmission = value;
                          if (value && _lateDeadline == null) {
                            _lateDeadline = _dueDate.add(const Duration(days: 2));
                            _lateTime = _dueTime;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_allowLateSubmission) ...[
                      const SizedBox(height: 12),
                      const Text('Late Deadline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectLateDate,
                              icon: const Icon(Icons.calendar_today, size: 20),
                              label: Text(
                                DateFormat('MMM dd, yyyy').format(_lateDeadline ?? DateTime.now()),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectLateTime,
                              icon: const Icon(Icons.access_time, size: 20),
                              label: Text(
                                (_lateTime ?? _dueTime).format(context),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Max Score & Attempts
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxScoreController,
                    decoration: const InputDecoration(
                      labelText: 'Max Score *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grade),
                      suffixText: 'pts',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final score = int.tryParse(value);
                      if (score == null || score <= 0) return 'Invalid';
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
                      const DropdownMenuItem(value: 0, child: Text('Unlimited')),
                      ...List.generate(10, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n'))),
                    ],
                    onChanged: (value) {
                      setState(() => _maxAttempts = value ?? 1);
                    },
                  ),
                ),
              ],
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
                        const Text('Assign to Groups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Leave empty for all students', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        if (groups.isEmpty)
                          const Text('No groups available', style: TextStyle(color: Colors.grey))
                        else
                          Wrap(
                            spacing: 8,
                            children: groups.map((group) {
                              final isSelected = _selectedGroupIds.contains(group.id);
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
            const SizedBox(height: 16),

            // File Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('File Upload Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxFileSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Max File Size (MB)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cloud_upload),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final size = int.tryParse(value);
                        if (size == null || size <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Allowed File Formats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableFormats.map((format) {
                        final isSelected = _selectedFileFormats.contains(format);
                        return FilterChip(
                          label: Text(format.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFileFormats.add(format);
                              } else {
                                _selectedFileFormats.remove(format);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEditing ? 'UPDATE ASSIGNMENT' : 'CREATE ASSIGNMENT', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}