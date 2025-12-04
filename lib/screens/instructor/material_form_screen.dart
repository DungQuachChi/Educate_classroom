import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/material_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/material_model.dart';
import '../../models/group_model.dart';
import '../../services/database_service.dart';

class MaterialFormScreen extends StatefulWidget {
  final String courseId;
  final MaterialModel? material;

  const MaterialFormScreen({
    super.key,
    required this.courseId,
    this.material,
  });

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  List<String> _selectedGroupIds = [];
  PlatformFile? _selectedFile;
  bool _isSaving = false;
  bool _isUploading = false;

  bool get isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.loadGroupsByCourse(widget.courseId);
    });

    if (isEditing) {
      _titleController.text = widget.material!.title;
      _descriptionController.text = widget.material!.description;
      _selectedGroupIds = List.from(widget.material!.groupIds);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size
        const maxSizeMB = 100;
        final fileSizeMB = file.size / (1024 * 1024);

        if (fileSizeMB > maxSizeMB) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File too large (${fileSizeMB.toStringAsFixed(1)} MB). Maximum size is $maxSizeMB MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isEditing && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final materialProvider = Provider.of<MaterialProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      String fileUrl = widget.material?.fileUrl ?? '';
      String fileName = widget.material?.fileName ?? '';
      String fileType = widget.material?.fileType ?? '';
      int fileSizeBytes = widget.material?.fileSizeBytes ?? 0;

      // Upload file if a new one is selected
      if (_selectedFile != null) {
        setState(() => _isUploading = true);

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = _selectedFile!.name;
        fileType = _selectedFile!.extension ?? '';
        fileSizeBytes = _selectedFile!.size;

        final path = 'materials/${widget.courseId}/${timestamp}_$fileName';

        if (_selectedFile!.bytes != null) {
          fileUrl = await _databaseService.uploadFileBytes(
            _selectedFile!.bytes!,
            _selectedFile!.name,
            path,
          );
        } else {
          throw 'File bytes not available';
        }

        setState(() => _isUploading = false);
      }

      if (isEditing) {
        await materialProvider.updateMaterial(
          widget.material!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            groupIds: _selectedGroupIds,
            fileUrl: fileUrl,
            fileName: fileName,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
          ),
        );
      } else {
        final newMaterial = MaterialModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          courseId: widget.courseId,
          groupIds: _selectedGroupIds,
          fileUrl: fileUrl,
          fileName: fileName,
          fileType: fileType,
          fileSizeBytes: fileSizeBytes,
          uploadedBy: authProvider.user!.uid,
          createdAt: DateTime.now(),
        );

        await materialProvider.createMaterial(newMaterial);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Material updated' : 'Material uploaded')),
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
        title: Text(isEditing ? 'Edit Material' : 'Upload Material'),
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
                hintText: 'e.g., Lecture 1: Introduction',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the content...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // File picker
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedFile != null || isEditing) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(_selectedFile?.extension ?? widget.material?.fileType ?? ''),
                              color: Colors.teal,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile?.name ?? widget.material?.fileName ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFile != null
                                        ? '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB'
                                        : widget.material?.fileSizeFormatted ?? '',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            if (!isEditing || _selectedFile != null)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFile != null || isEditing ? 'Change File' : 'Select File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported: PDF, Word, PowerPoint, Excel, Images, Videos, ZIP (Max 100 MB)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Leave empty for all students',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
            const SizedBox(height: 24),

            // Upload progress
            if (_isUploading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Uploading file...',
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
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'UPDATE MATERIAL' : 'UPLOAD MATERIAL',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}