import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../../models/course_model.dart';
import '../../models/forum_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/forum_provider.dart';

class ForumFormScreen extends StatefulWidget {
  final CourseModel course;
  final ForumModel?  forum;

  const ForumFormScreen({
    super.key,
    required this.course,
    this. forum,
  });

  @override
  State<ForumFormScreen> createState() => _ForumFormScreenState();
}

class _ForumFormScreenState extends State<ForumFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  List<String> _tags = [];
  List<PlatformFile> _selectedFiles = [];
  List<String> _existingAttachmentUrls = [];
  List<String> _existingAttachmentNames = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super. initState();
    if (widget.forum != null) {
      _titleController.text = widget. forum!.title;
      _descriptionController.text = widget. forum!.description;
      _tags = List.from(widget.forum!. tags);
      _existingAttachmentUrls = List.from(widget.forum!. attachmentUrls);
      _existingAttachmentNames = List.from(widget.forum!. attachmentNames);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super. dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform. pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _selectedFiles. addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeExistingAttachment(int index) {
    setState(() {
      _existingAttachmentUrls.removeAt(index);
      _existingAttachmentNames.removeAt(index);
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final forumProvider = Provider. of<ForumProvider>(context, listen: false);

    try {
      // Upload new attachments
      List<String> newAttachmentUrls = List.from(_existingAttachmentUrls);
      List<String> newAttachmentNames = List.from(_existingAttachmentNames);

      if (_selectedFiles.isNotEmpty) {
        // Use temporary ID for uploads if creating new forum
        final tempId = widget. forum?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

        for (var file in _selectedFiles) {
          final url = await forumProvider.uploadForumAttachment(tempId, file);
          newAttachmentUrls.add(url);
          newAttachmentNames.add(file.name);
        }
      }

      if (widget.forum == null) {
        // Create new forum
        final forum = ForumModel(
          id: '',
          courseId: widget.course.id,
          title: _titleController. text. trim(),
          description: _descriptionController.text.trim(),
          createdBy: authProvider.user! .uid,
          createdAt: DateTime.now(),
          tags: _tags,
          attachmentUrls: newAttachmentUrls,
          attachmentNames: newAttachmentNames,
          lastActivityAt: DateTime.now(),
          lastActivityBy: authProvider.user!. uid,
        );

        await forumProvider.createForum(forum);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forum topic created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing forum
        await forumProvider.updateForum(widget.forum!.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'tags': _tags,
          'attachmentUrls': newAttachmentUrls,
          'attachmentNames': newAttachmentNames,
          'updatedAt': DateTime.now(),
        });

        if (mounted) {
          ScaffoldMessenger. of(context).showSnackBar(
            const SnackBar(
              content: Text('Forum topic updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.forum != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Forum Topic' : 'Create Forum Topic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment. start,
            children: [
              // Course Info
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Course',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              widget.course.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight. bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Topic Title *',
                  hintText: 'Enter a clear, descriptive title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Provide details about this topic.. .',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
                maxLength: 2000,
              ),
              const SizedBox(height: 16),

              // Tags
              const Text(
                'Tags',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag (e.g., homework, discussion)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton. icon(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Existing Attachments (for editing)
              if (_existingAttachmentUrls.isNotEmpty) ...[
                const Text(
                  'Current Attachments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._existingAttachmentUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  final name = _existingAttachmentNames[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_file, color: Colors.blue),
                      title: Text(name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new, color: Colors.blue),
                            onPressed: () => html.window.open(url, '_blank'),
                            tooltip: 'Open',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeExistingAttachment(index),
                            tooltip: 'Remove',
                          ),
                        ],
                      ),
                    ),
                  );
                }). toList(),
                const SizedBox(height: 16),
              ],

              // New Attachments
              const Text(
                'Attachments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons. attach_file),
                label: const Text('Add Files'),
              ),
              const SizedBox(height: 8),
              if (_selectedFiles.isNotEmpty)
                Column(
                  children: _selectedFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons. insert_drive_file, color: Colors.blue),
                        title: Text(file.name),
                        subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _removeFile(index),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ?  const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Topic' : 'Create Topic',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}