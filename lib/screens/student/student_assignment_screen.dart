import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../services/database_service.dart';
import 'package:universal_html/html.dart' as html;

class StudentAssignmentScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const StudentAssignmentScreen({super.key, required this.assignment});

  @override
  State<StudentAssignmentScreen> createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  
  List<SubmissionModel> _submissionHistory = [];
  List<PlatformFile> _selectedFiles = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadSubmissionHistory();
  }

  Future<void> _loadSubmissionHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final history = await assignmentProvider.getSubmissionHistory(
          widget.assignment.id,
          authProvider.user!.uid,
        );

        setState(() {
          _submissionHistory = history;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading history: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: widget.assignment.allowedFileFormats.isNotEmpty 
            ? FileType.custom 
            : FileType.any,
        allowedExtensions: widget.assignment.allowedFileFormats.isNotEmpty 
            ? widget.assignment.allowedFileFormats 
            : null,
      );

      if (result != null) {
        // Check file sizes
        List<PlatformFile> validFiles = [];
        List<String> oversizedFiles = [];

        for (var file in result.files) {
          final fileSizeMB = (file.size / (1024 * 1024));
          if (fileSizeMB <= widget.assignment.maxFileSizeMB) {
            validFiles.add(file);
          } else {
            oversizedFiles.add('${file.name} (${fileSizeMB.toStringAsFixed(1)} MB)');
          }
        }

        if (oversizedFiles.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Files exceed ${widget.assignment.maxFileSizeMB} MB limit:\n${oversizedFiles.join('\n')}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        setState(() {
          _selectedFiles.addAll(validFiles);
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

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file to upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    // Check if assignment has started
    if (!widget.assignment.hasStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment starts on ${DateFormat('MMM dd, yyyy HH:mm').format(widget.assignment.startDate)}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if can still submit
    if (widget.assignment.isPastLateDeadline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submission deadline has passed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check max attempts
    if (widget.assignment.maxAttempts > 0 && _submissionHistory.length >= widget.assignment.maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum attempts (${widget.assignment.maxAttempts}) reached'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Warn if overdue
    if (widget.assignment.isOverdue && widget.assignment.allowLateSubmission) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Late Submission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This assignment is past the due date.'),
              const SizedBox(height: 8),
              Text(
                'Due: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.assignment.dueDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (widget.assignment.lateDeadline != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Late deadline: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.assignment.lateDeadline!)}',
                  style: TextStyle(color: Colors.orange[700]),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Your submission will be marked as late. Continue?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload files
      setState(() => _isUploadingFiles = true);
      List<String> uploadedUrls = [];

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final path = 'submissions/${widget.assignment.id}/${authProvider.user!.uid}/$fileName';

        try {
          String url;
          if (file.bytes != null) {
            // Web upload
            url = await _databaseService.uploadFileBytes(file.bytes!, file.name, path);
          } else {
            throw 'File bytes not available';
          }
          uploadedUrls.add(url);

          if (mounted) {
            setState(() {
              // Show progress
            });
          }
        } catch (e) {
          throw 'Failed to upload ${file.name}: $e';
        }
      }

      setState(() => _isUploadingFiles = false);

      // Submit assignment
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);

      await assignmentProvider.submitAssignment(
        assignmentId: widget.assignment.id,
        studentId: authProvider.user!.uid,
        assignment: widget.assignment,
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        attachmentUrls: uploadedUrls,
      );

      if (mounted) {
        _contentController.clear();
        _selectedFiles.clear();
        await _loadSubmissionHistory();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission ${_submissionHistory.length} submitted successfully!'),
            backgroundColor: Colors.green,
          ),
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
          _isSubmitting = false;
          _isUploadingFiles = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.assignment.canSubmit &&
        (widget.assignment.maxAttempts == 0 || _submissionHistory.length < widget.assignment.maxAttempts);

    final latestSubmission = _submissionHistory.isNotEmpty ? _submissionHistory.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissionHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.assignment.isPastLateDeadline
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : widget.assignment.isOverdue
                                ? [Colors.orange.shade400, Colors.orange.shade600]
                                : [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assignment.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildHeaderChip(Icons.calendar_today, 'Start: ${DateFormat('MMM dd, HH:mm').format(widget.assignment.startDate)}'),
                            _buildHeaderChip(Icons.event, 'Due: ${DateFormat('MMM dd, HH:mm').format(widget.assignment.dueDate)}'),
                            if (widget.assignment.allowLateSubmission && widget.assignment.lateDeadline != null)
                              _buildHeaderChip(Icons.access_time, 'Late: ${DateFormat('MMM dd, HH:mm').format(widget.assignment.lateDeadline!)}'),
                            _buildHeaderChip(Icons.grade, '${widget.assignment.maxScore} points'),
                            _buildHeaderChip(Icons.repeat, 'Max ${widget.assignment.maxAttempts == 0 ? '∞' : widget.assignment.maxAttempts} attempts'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: !widget.assignment.hasStarted
                                ? Colors.grey[100]
                                : widget.assignment.isPastLateDeadline
                                    ? Colors.red[50]
                                    : widget.assignment.isOverdue
                                        ? Colors.orange[50]
                                        : canSubmit
                                            ? Colors.green[50]
                                            : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !widget.assignment.hasStarted
                                  ? Colors.grey
                                  : widget.assignment.isPastLateDeadline
                                      ? Colors.red
                                      : widget.assignment.isOverdue
                                          ? Colors.orange
                                          : canSubmit
                                              ? Colors.green
                                              : Colors.blue,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                !widget.assignment.hasStarted
                                    ? Icons.schedule
                                    : widget.assignment.isPastLateDeadline
                                        ? Icons.lock
                                        : widget.assignment.isOverdue
                                            ? Icons.warning
                                            : canSubmit
                                                ? Icons.check_circle
                                                : Icons.info,
                                color: !widget.assignment.hasStarted
                                    ? Colors.grey
                                    : widget.assignment.isPastLateDeadline
                                        ? Colors.red
                                        : widget.assignment.isOverdue
                                            ? Colors.orange
                                            : canSubmit
                                                ? Colors.green
                                                : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  !widget.assignment.hasStarted
                                      ? 'This assignment has not started yet'
                                      : widget.assignment.isPastLateDeadline
                                          ? 'Submission deadline has passed'
                                          : widget.assignment.isOverdue
                                              ? 'This assignment is overdue (late submission allowed)'
                                              : canSubmit
                                                  ? 'You can submit your work'
                                                  : 'Maximum attempts reached',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !widget.assignment.hasStarted
                                        ? Colors.grey[700]
                                        : widget.assignment.isPastLateDeadline
                                            ? Colors.red[700]
                                            : widget.assignment.isOverdue
                                                ? Colors.orange[700]
                                                : canSubmit
                                                    ? Colors.green[700]
                                                    : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.assignment.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),

                        // File Requirements
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'File Upload Requirements',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (widget.assignment.allowedFileFormats.isNotEmpty)
                                  Text(
                                    '• Allowed formats: ${widget.assignment.allowedFileFormats.map((f) => f.toUpperCase()).join(', ')}',
                                    style: const TextStyle(fontSize: 14),
                                  )
                                else
                                  const Text(
                                    '• All file formats allowed',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                Text(
                                  '• Max file size: ${widget.assignment.maxFileSizeMB} MB per file',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Text(
                                  '• You can upload multiple files',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submission History
                        if (_submissionHistory.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your Submissions',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_submissionHistory.length}/${widget.assignment.maxAttempts == 0 ? '∞' : widget.assignment.maxAttempts}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._submissionHistory.reversed.map((submission) {
                            return _SubmissionCard(
                              submission: submission,
                              assignment: widget.assignment,
                            );
                          }).toList(),
                          const SizedBox(height: 24),
                        ],

                        // Submission Form
                        if (canSubmit && widget.assignment.hasStarted) ...[
                          const Text(
                            'New Submission',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Optional comment
                                TextFormField(
                                  controller: _contentController,
                                  decoration: const InputDecoration(
                                    labelText: 'Comment (Optional)',
                                    hintText: 'Add any notes about your submission...',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),

                                // File picker button
                                OutlinedButton.icon(
                                  onPressed: _isSubmitting ? null : _pickFiles,
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Select Files'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Selected files list
                                if (_selectedFiles.isNotEmpty) ...[
                                  const Text(
                                    'Selected Files:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._selectedFiles.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final file = entry.value;
                                    final fileSizeMB = (file.size / (1024 * 1024)).toStringAsFixed(2);

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Icon(
                                          _getFileIcon(file.extension ?? ''),
                                          color: Colors.blue,
                                        ),
                                        title: Text(file.name),
                                        subtitle: Text('$fileSizeMB MB'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: _isSubmitting ? null : () => _removeFile(index),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 16),
                                ],

                                // Upload progress
                                if (_isUploadingFiles) ...[
                                  const LinearProgressIndicator(),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Uploading files...',
                                    style: TextStyle(fontSize: 14, color: Colors.blue),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isSubmitting ? null : _submitAssignment,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: widget.assignment.isOverdue ? Colors.orange : Colors.green,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            'SUBMIT ATTEMPT ${_submissionHistory.length + 1}',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (!widget.assignment.hasStarted) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.schedule, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text(
                                  'Assignment Not Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Available from ${DateFormat('MMM dd, yyyy HH:mm').format(widget.assignment.startDate)}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else if (widget.assignment.isPastLateDeadline) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.lock, size: 48, color: Colors.red),
                                SizedBox(height: 8),
                                Text(
                                  'Submission Closed',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'The deadline has passed',
                                  style: TextStyle(fontSize: 14, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else if (!canSubmit) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.block, size: 48, color: Colors.orange),
                                const SizedBox(height: 8),
                                const Text(
                                  'Maximum Attempts Reached',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You have used all ${widget.assignment.maxAttempts} attempts',
                                  style: const TextStyle(fontSize: 14, color: Colors.orange),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;
  final AssignmentModel assignment;

  const _SubmissionCard({
    required this.submission,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: submission.isGraded ? Colors.green[50] : Colors.blue[50],
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: submission.isGraded ? Colors.green : Colors.blue,
          child: Text(
            '${submission.attemptNumber}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Attempt ${submission.attemptNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(submission.submittedAt)}'),
            if (submission.isLate)
              const Text(
                '⚠️ Late submission',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment
                if (submission.content != null && submission.content!.isNotEmpty) ...[
                  const Text('Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(submission.content!),
                  ),
                  const SizedBox(height: 12),
                ],

                // Uploaded files
                if (submission.attachmentUrls.isNotEmpty) ...[
                  const Text('Uploaded Files:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...submission.attachmentUrls.map((url) {
                    final fileName = url.split('/').last.split('?').first;
                    final decodedName = Uri.decodeComponent(fileName);
                    
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.attach_file, color: Colors.blue),
                        title: Text(decodedName, style: const TextStyle(fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          onPressed: () {
                            html.window.open(url, '_blank');
                          },
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                ],

                // Grade
                if (submission.isGraded) ...[
                  Row(
                    children: [
                      const Text('Score: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${submission.score}/${assignment.maxScore}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${((submission.score! / assignment.maxScore) * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Graded on ${DateFormat('MMM dd, yyyy HH:mm').format(submission.gradedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Feedback
                if (submission.feedback != null) ...[
                  const Text('Instructor Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(submission.feedback!),
                  ),
                ],

                // Pending grade
                if (!submission.isGraded)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.pending, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Waiting for instructor to grade',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}