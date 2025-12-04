import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/forum_model.dart';
import '../../models/forum_reply_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/forum_provider.dart';
import '../../services/database_service.dart';

class StudentForumDetailScreen extends StatefulWidget {
  final ForumModel forum;

  const StudentForumDetailScreen({super.key, required this.forum});

  @override
  State<StudentForumDetailScreen> createState() => _StudentForumDetailScreenState();
}

class _StudentForumDetailScreenState extends State<StudentForumDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _replyController = TextEditingController();
  final Map<String, TextEditingController> _nestedReplyControllers = {};
  final Map<String, bool> _showReplyBox = {};
  
  List<PlatformFile> _selectedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    for (var controller in _nestedReplyControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitReply({String? parentReplyId, int level = 0}) async {
    final controller = parentReplyId == null 
        ? _replyController 
        : _nestedReplyControllers[parentReplyId];

    if (controller == null || controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final forumProvider = Provider.of<ForumProvider>(context, listen: false);

    try {
      // Upload attachments (only for top-level replies)
      List<String> attachmentUrls = [];
      List<String> attachmentNames = [];

      if (parentReplyId == null && _selectedFiles.isNotEmpty) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        for (var file in _selectedFiles) {
          final url = await forumProvider.uploadReplyAttachment(tempId, file);
          attachmentUrls.add(url);
          attachmentNames.add(file.name);
        }
      }

      final reply = ForumReplyModel(
        id: '',
        forumId: widget.forum.id,
        parentReplyId: parentReplyId,
        content: controller.text. trim(),
        createdBy: authProvider.user! .uid,
        createdAt: DateTime.now(),
        attachmentUrls: attachmentUrls,
        attachmentNames: attachmentNames,
        level: level,
      );

      await forumProvider.createReply(reply);

      controller.clear();
      setState(() {
        _selectedFiles. clear();
        _showReplyBox[parentReplyId ??  ''] = false;
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteReply(ForumReplyModel reply) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final forumProvider = Provider.of<ForumProvider>(context, listen: false);
      await forumProvider. deleteReply(reply.id, reply.forumId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final forumProvider = Provider.of<ForumProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum Discussion'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            . collection('forums')
            . doc(widget.forum.id)
            .snapshots(),
        builder: (context, forumSnapshot) {
          ForumModel currentForum = widget.forum;

          if (forumSnapshot.hasData && forumSnapshot.data! .exists) {
            currentForum = ForumModel.fromMap(
              forumSnapshot.data!. data() as Map<String, dynamic>,
              forumSnapshot.data!.id,
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Forum Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (currentForum.isPinned) ...[
                            const Icon(Icons.push_pin, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                          ],
                          if (currentForum.isLocked) ...[
                            const Icon(Icons.lock, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.forum, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentForum.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<UserModel?>(
                        future: _databaseService.getUserById(currentForum.createdBy),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            );
                          }

                          if (!userSnapshot.hasData || userSnapshot.data == null) {
                            return Text(
                              'Posted by Unknown • ${DateFormat('MMM dd, yyyy HH:mm').format(currentForum.createdAt)}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            );
                          }

                          final userName = userSnapshot.data!.displayName;
                          return Text(
                            'Posted by $userName • ${DateFormat('MMM dd, yyyy HH:mm'). format(currentForum.createdAt)}',
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            currentForum. description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      if (currentForum.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentForum.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: Colors.blue.shade50,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Attachments
                      if (currentForum.attachmentUrls. isNotEmpty) ...[
                        const Text(
                          'Attachments',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ... currentForum.attachmentUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final url = entry.value;
                          final name = currentForum.attachmentNames[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.attach_file, color: Colors.blue),
                              title: Text(name),
                              trailing: IconButton(
                                icon: const Icon(Icons.download, color: Colors.blue),
                                onPressed: () => html. window.open(url, '_blank'),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],

                      const Divider(),
                      const SizedBox(height: 16),

                      // Reply Section
                      if (! currentForum.isLocked) ...[
                        const Text(
                          'Post a Reply',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _replyController,
                          decoration: const InputDecoration(
                            hintText: 'Write your reply...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 8),

                        // Attachments for reply
                        if (_selectedFiles.isNotEmpty) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _selectedFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;

                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
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
                          const SizedBox(height: 8),
                        ],

                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Attach Files'),
                            ),
                            const Spacer(),
                            ElevatedButton. icon(
                              onPressed: _isSubmitting ? null : () => _submitReply(),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Post Reply'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ] else ...[
                        Card(
                          color: Colors.orange.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.lock, color: Colors.orange),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This topic is locked. No new replies allowed.',
                                    style: TextStyle(color: Colors. orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Replies List
                      Text(
                        'Replies (${currentForum.replyCount})',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      StreamBuilder<List<ForumReplyModel>>(
                        stream: forumProvider.getReplies(currentForum.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (! snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No replies yet. Be the first to reply!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          final replies = snapshot.data!;
                          final topLevelReplies = replies.where((r) => r.parentReplyId == null).toList();

                          return Column(
                            children: topLevelReplies.map((reply) {
                              return _ReplyCard(
                                reply: reply,
                                allReplies: replies,
                                isLocked: currentForum.isLocked,
                                currentUserId: authProvider.user?. uid ?? '',
                                onDelete: _deleteReply,
                                onReply: (parentId, level) {
                                  setState(() {
                                    _showReplyBox[parentId] = ! (_showReplyBox[parentId] ?? false);
                                    if (_showReplyBox[parentId]!  && ! _nestedReplyControllers. containsKey(parentId)) {
                                      _nestedReplyControllers[parentId] = TextEditingController();
                                    }
                                  });
                                },
                                showReplyBox: _showReplyBox,
                                replyControllers: _nestedReplyControllers,
                                onSubmitReply: _submitReply,
                                isSubmitting: _isSubmitting,
                              );
                            }). toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Reply Card Widget (same as instructor version but for students)
class _ReplyCard extends StatelessWidget {
  final ForumReplyModel reply;
  final List<ForumReplyModel> allReplies;
  final bool isLocked;
  final String currentUserId;
  final Function(ForumReplyModel) onDelete;
  final Function(String, int) onReply;
  final Map<String, bool> showReplyBox;
  final Map<String, TextEditingController> replyControllers;
  final Function({String?  parentReplyId, int level}) onSubmitReply;
  final bool isSubmitting;

  const _ReplyCard({
    required this.reply,
    required this.allReplies,
    required this.isLocked,
    required this.currentUserId,
    required this.onDelete,
    required this.onReply,
    required this.showReplyBox,
    required this. replyControllers,
    required this.onSubmitReply,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();
    final nestedReplies = allReplies. where((r) => r.parentReplyId == reply.id). toList();
    final canDelete = currentUserId == reply.createdBy;

    return Card(
      margin: EdgeInsets.only(
        bottom: 12,
        left: reply.level * 24.0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply Header
            FutureBuilder<UserModel?>(
              future: databaseService.getUserById(reply.createdBy),
              builder: (context, userSnapshot) {
                // Handle loading state
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Loading...',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(reply. createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => onDelete(reply),
                          tooltip: 'Delete',
                        ),
                    ],
                  );
                }

                // Handle null or no data
                if (! userSnapshot.hasData || userSnapshot.data == null) {
                  return Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unknown User',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(reply. createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(Icons. delete, color: Colors.red, size: 20),
                          onPressed: () => onDelete(reply),
                          tooltip: 'Delete',
                        ),
                    ],
                  );
                }

                // User data exists
                final user = userSnapshot.data!;
                final userName = user.displayName. isNotEmpty ? user.displayName : 'Unknown';
                final userRole = user.role;
                final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: userRole == 'instructor' 
                          ? Colors.deepPurple 
                          : Colors.blue,
                      child: Text(
                        userInitial,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontWeight: FontWeight. bold),
                              ),
                              const SizedBox(width: 8),
                              if (userRole == 'instructor')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Instructor',
                                    style: TextStyle(fontSize: 10, color: Colors. white),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(reply. createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons. delete, color: Colors.red, size: 20),
                        onPressed: () => onDelete(reply),
                        tooltip: 'Delete',
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Reply Content
            Text(
              reply.content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 8),

            // Attachments
            if (reply.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              ... reply.attachmentUrls.asMap().entries.map((entry) {
                final index = entry. key;
                final url = entry.value;
                final name = reply.attachmentNames[index];

                return InkWell(
                  onTap: () => html.window.open(url, '_blank'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],

            // Reply Button
            if (! isLocked && reply.level < 2) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => onReply(reply.id, reply.level + 1),
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],

            // Nested Reply Box
            if (showReplyBox[reply.id] == true) ...[
              const SizedBox(height: 12),
              TextField(
                controller: replyControllers[reply.id],
                decoration: const InputDecoration(
                  hintText: 'Write your reply...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onReply(reply.id, reply. level + 1),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isSubmitting 
                        ? null 
                        : () => onSubmitReply(parentReplyId: reply.id, level: reply.level + 1),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],

            // Nested Replies
            if (nestedReplies. isNotEmpty) ...[
              const SizedBox(height: 12),
              ... nestedReplies.map((nestedReply) {
                return _ReplyCard(
                  reply: nestedReply,
                  allReplies: allReplies,
                  isLocked: isLocked,
                  currentUserId: currentUserId,
                  onDelete: onDelete,
                  onReply: onReply,
                  showReplyBox: showReplyBox,
                  replyControllers: replyControllers,
                  onSubmitReply: onSubmitReply,
                  isSubmitting: isSubmitting,
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}