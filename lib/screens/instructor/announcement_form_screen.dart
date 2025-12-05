import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/announcement_model.dart';
import '../../services/database_service.dart';

class AnnouncementFormScreen extends StatefulWidget {
  final String courseId;
  final AnnouncementModel? announcement;

  const AnnouncementFormScreen({
    super.key,
    required this. courseId,
    this.announcement,
  });

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  List<String> _selectedGroupIds = [];
  List<PlatformFile> _selectedFiles = [];
  List<String> _existingAttachmentUrls = [];
  List<String> _existingAttachmentNames = [];
  bool _isSaving = false;
  bool _isUploading = false;

  bool get isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.loadGroupsByCourse(widget.courseId);
    });

    if (isEditing) {
      _titleController.text = widget. announcement! .title;
      _contentController.text = widget.announcement!. content;
      _selectedGroupIds = List.from(widget.announcement!. groupIds);
      _existingAttachmentUrls = List.from(widget.announcement!. attachmentUrls);
      _existingAttachmentNames = List.from(widget.announcement!. attachmentNames);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Check total file size
        int totalSize = result.files.fold(0, (sum, file) => sum + file.size);
        const maxSizeMB = 50;
        final totalSizeMB = totalSize / (1024 * 1024);

        if (totalSizeMB > maxSizeMB) {
          if (mounted) {
            ScaffoldMessenger.of(context). showSnackBar(
              SnackBar(
                content: Text('Total file size too large (${totalSizeMB.toStringAsFixed(1)} MB).  Maximum is $maxSizeMB MB. '),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

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

  Future<void> _sendNotificationsToStudents(AnnouncementModel announcement) async {
    try {
      print('Sending notifications for announcement: ${announcement.title}');
      
      // Get students from groups
      List<String> studentIds = [];
      
      if (announcement.groupIds.isEmpty) {
        // All students in course
        print('  → Sending to all students in course');
        final groups = await _databaseService.getGroupsByCourseAsync(widget.courseId);
        for (var group in groups) {
          studentIds.addAll(group.studentIds);
        }
      } else {
        // Specific groups
        print('  → Sending to ${announcement.groupIds.length} specific groups');
        for (var groupId in announcement.groupIds) {
          final group = await _databaseService.getGroupById(groupId);
          if (group != null) {
            studentIds.addAll(group.studentIds);
          }
        }
      }

      // Remove duplicates
      studentIds = studentIds.toSet(). toList();

      // Send notifications
      if (studentIds.isNotEmpty) {
        await _databaseService.notifyAnnouncementCreated(announcement, studentIds);
        print('Sent notifications to ${studentIds.length} students');
      } else {
        print('No students to notify');
      }
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      List<String> attachmentUrls = List.from(_existingAttachmentUrls);
      List<String> attachmentNames = List.from(_existingAttachmentNames);

      // Upload new files
      if (_selectedFiles. isNotEmpty) {
        setState(() => _isUploading = true);

        for (var file in _selectedFiles) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final path = 'announcements/${widget.courseId}/${timestamp}_${file.name}';

          if (file.bytes != null) {
            final url = await _databaseService.uploadFileBytes(
              file.bytes!,
              file.name,
              path,
            );
            attachmentUrls. add(url);
            attachmentNames.add(file.name);
          }
        }

        setState(() => _isUploading = false);
      }

      if (isEditing) {
        await announcementProvider.updateAnnouncement(
          widget.announcement!.copyWith(
            title: _titleController.text. trim(),
            content: _contentController.text.trim(),
            groupIds: _selectedGroupIds,
            attachmentUrls: attachmentUrls,
            attachmentNames: attachmentNames,
          ),
        );
      } else {
        final newAnnouncement = AnnouncementModel(
          id: '',
          title: _titleController. text.trim(),
          content: _contentController.text.trim(),
          courseId: widget.courseId,
          groupIds: _selectedGroupIds,
          attachmentUrls: attachmentUrls,
          attachmentNames: attachmentNames,
          createdBy: authProvider.user! .uid,
          createdAt: DateTime.now(),
        );

        // Create announcement first to get the ID
        final announcementId = await announcementProvider.createAnnouncement(newAnnouncement);
        
        // Send notifications
        if (mounted) {
          _sendNotificationsToStudents(
            newAnnouncement. copyWith(id: announcementId),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
              ? 'Announcement updated' 
              : 'Announcement published & notifications sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors. red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Announcement' : 'New Announcement'),
      ),
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
                hintText: 'e.g., Important: Midterm Schedule',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter title';
                }
                return null;
              },
              textCapitalization: TextCapitalization. words,
            ),
            const SizedBox(height: 16),

            // Content
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content *',
                hintText: 'Write your announcement here...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter content';
                }
                return null;
              },
              maxLines: 10,
              textCapitalization: TextCapitalization. sentences,
            ),
            const SizedBox(height: 16),

            // Attachments
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.attach_file, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Existing attachments
                    if (_existingAttachmentNames.isNotEmpty) ...[
                      const Text('Current files:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ..._existingAttachmentNames. asMap().entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14))),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                onPressed: () => _removeExistingAttachment(entry.key),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    // New files
                    if (_selectedFiles. isNotEmpty) ...[
                      const Text('New files:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final file = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(file.name, style: const TextStyle(fontSize: 14)),
                                    Text(
                                      '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                onPressed: () => _removeFile(entry.key),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickFiles,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Files'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Groups
            Consumer<GroupProvider>(
              builder: (context, groupProvider, child) {
                final groups = groupProvider. groups;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.group, color: Colors. deepPurple),
                            SizedBox(width: 8),
                            Text('Target Audience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Leave empty to send to all students', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        if (groups.isEmpty)
                          const Text('No groups available', style: TextStyle(color: Colors. grey))
                        else
                          Wrap(
                            spacing: 8,
                            children: groups.map((group) {
                              final isSelected = _selectedGroupIds.contains(group. id);
                              return FilterChip(
                                label: Text(group.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedGroupIds. add(group.id);
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

            // Upload progress
            if (_isUploading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Uploading files...',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEditing ? 'UPDATE ANNOUNCEMENT' : 'PUBLISH ANNOUNCEMENT',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}