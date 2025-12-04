import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../../providers/auth_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../models/announcement_model.dart';
import '../../models/announcement_comment_model.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';

class StudentAnnouncementScreen extends StatefulWidget {
  final CourseModel course;

  const StudentAnnouncementScreen({super.key, required this.course});

  @override
  State<StudentAnnouncementScreen> createState() => _StudentAnnouncementScreenState();
}

class _StudentAnnouncementScreenState extends State<StudentAnnouncementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      try {
        final announcements = await _databaseService.getStudentAnnouncements(
          authProvider.user!.uid,
          widget.course.id,
        );

        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No announcements yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      return _StudentAnnouncementCard(
                        announcement: _announcements[index],
                        onTap: _loadAnnouncements,
                      );
                    },
                  ),
                ),
    );
  }
}

class _StudentAnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;

  const _StudentAnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final hasViewed = announcement.hasViewed(authProvider.user?.uid ??  '');

    return Card(
      elevation: hasViewed ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 12),
      color: hasViewed ? Colors.white : Colors.deepPurple. shade50,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentAnnouncementDetailScreen(
                announcement: announcement,
              ),
            ),
          );
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.campaign,
                    color: hasViewed ? Colors.grey : Colors.deepPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: hasViewed ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  if (! hasViewed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors. white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                announcement.content,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (announcement.attachmentUrls.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    ...announcement.attachmentNames.take(2).map((name) {
                      return Chip(
                        avatar: const Icon(Icons.attach_file, size: 14),
                        label: Text(name, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.blue.shade50,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }),
                    if (announcement.attachmentNames.length > 2)
                      Chip(
                        label: Text(
                          '+${announcement.attachmentNames.length - 2}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.grey.shade200,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(announcement. createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

// Student Announcement Detail Screen
class StudentAnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const StudentAnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<StudentAnnouncementDetailScreen> createState() =>
      _StudentAnnouncementDetailScreenState();
}

class _StudentAnnouncementDetailScreenState
    extends State<StudentAnnouncementDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _markAsViewed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);

    if (authProvider.user != null &&
        ! widget.announcement.hasViewed(authProvider.user! .uid)) {
      try {
        await announcementProvider. markAsViewed(
          widget.announcement.id,
          authProvider.user!.uid,
        );
      } catch (e) {
        print('Error marking as viewed: $e');
      }
    }
  }

  Future<void> _downloadAttachment(int index, String url, String fileName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);

    try {
      // Track download with index
      if (authProvider. user != null) {
        await announcementProvider.trackDownload(
          widget.announcement.id,
          index,
          authProvider.user!.uid,
        );
      }

      // For Firebase Storage, open in new tab with download parameter
      final downloadUrl = url.contains('? ') 
          ? '$url&response-content-disposition=attachment;filename=$fileName'
          : '$url?response-content-disposition=attachment;filename=$fileName';
      
      html.window.open(downloadUrl, '_blank');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors. red),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim(). isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);

    try {
      final comment = AnnouncementCommentModel(
        id: '',
        announcementId: widget.announcement. id,
        userId: authProvider.user!.uid,
        userName: authProvider.user!.displayName,
        userRole: authProvider.user!.role,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await announcementProvider.addComment(comment);
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade400, Colors.deepPurple. shade600],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget. announcement.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(widget. announcement.createdAt),
                    style: const TextStyle(fontSize: 14, color: Colors. white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.announcement. content,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attachments
                  if (widget.announcement.attachmentUrls.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets. all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.attach_file, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...widget. announcement.attachmentUrls
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              final name = widget.announcement.attachmentNames[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border. all(color: Colors.blue. shade200),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                                  title: Text(name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download, color: Colors.blue),
                                    onPressed: () => _downloadAttachment(index, url, name),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Comments Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.comment, color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                'Comments',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Add comment field
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    hintText: 'Write a comment...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.send, color: Colors.deepPurple),
                                onPressed: _addComment,
                                tooltip: 'Post comment',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Comments list
                          StreamBuilder<List<AnnouncementCommentModel>>(
                            stream: _databaseService
                                .getAnnouncementComments(widget. announcement.id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (! snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No comments yet.  Be the first to comment!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: snapshot. data!. map((comment) {
                                  return _StudentCommentCard(comment: comment);
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Student Comment Card
class _StudentCommentCard extends StatelessWidget {
  final AnnouncementCommentModel comment;

  const _StudentCommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(context, listen: false);
    final isOwner = comment. userId == authProvider.user?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    comment.userRole == 'instructor' ? Colors.deepPurple : Colors.blue,
                child: Text(
                  comment.userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors. white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        if (comment. userRole == 'instructor')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Instructor',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(comment. createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Comment'),
                        content: const Text('Delete this comment?'),
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

                    if (confirm == true) {
                      try {
                        await announcementProvider.deleteComment(comment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Comment deleted')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.comment,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}