import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/semester_provider.dart';
import '../../models/semester_model.dart';

class SemesterFormScreen extends StatefulWidget {
  final SemesterModel? semester; // null for create, non-null for edit

  const SemesterFormScreen({super.key, this.semester});

  @override
  State<SemesterFormScreen> createState() => _SemesterFormScreenState();
}

class _SemesterFormScreenState extends State<SemesterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isCurrent = false;
  bool _isSaving = false;

  bool get isEditing => widget.semester != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _codeController.text = widget.semester!.code;
      _nameController.text = widget.semester!.name;
      _isCurrent = widget.semester!.isCurrent;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);

    try {
      if (isEditing) {
        // Update existing semester
        await semesterProvider.updateSemester(
          widget.semester!.copyWith(
            code: _codeController.text.trim(),
            name: _nameController.text.trim(),
            isCurrent: _isCurrent,
          ),
        );
      } else {
        // Create new semester
        final newSemester = SemesterModel(
          id: '', // Firestore will generate
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          isCurrent: _isCurrent,
          createdAt: DateTime.now(),
        );
        await semesterProvider.createSemester(newSemester);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Semester updated successfully'
                  : 'Semester created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Semester' : 'New Semester'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Semester Code
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Semester Code *',
                hintText: 'e.g., 2024-1, Fall2024',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter semester code';
                }
                return null;
              },
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Semester Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Semester Name *',
                hintText: 'e.g., Fall Semester 2024',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter semester name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Current Semester Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Set as Current Semester'),
                subtitle: const Text(
                  'This semester will be shown by default',
                ),
                value: _isCurrent,
                onChanged: (value) {
                  setState(() => _isCurrent = value);
                },
                secondary: const Icon(Icons.star),
              ),
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
                      isEditing ? 'UPDATE SEMESTER' : 'CREATE SEMESTER',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}