import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/announcement_model.dart';
import '../../models/announcement_comment_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _commentController = TextEditingController();
  List<UserModel> _viewers = [];
  Map<String, List<UserModel>> _downloaders = {};
  bool _isLoadingTracking = true;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    await _loadTrackingDataForAnnouncement(widget.announcement);
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(
      context,
      listen: false,
    );

    try {
      final comment = AnnouncementCommentModel(
        id: '',
        announcementId: widget.announcement.id,
        userId: authProvider.user!.uid,
        userName: authProvider.user!.displayName,
        userRole: authProvider.user!.role,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await announcementProvider.addComment(comment);
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment added')));
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            . doc(widget.announcement.id)
            .snapshots(),
        builder: (context, snapshot) {
          // Use the streamed data or fallback to widget data
          AnnouncementModel currentAnnouncement = widget.announcement;
          
          if (snapshot.hasData && snapshot.data! .exists) {
            currentAnnouncement = AnnouncementModel.fromMap(
              snapshot.data!.data() as Map<String, dynamic>,
              snapshot.data!.id,
            );
            
            // DEBUG: Print the fresh data
            print('🔄 Direct stream update for announcement: ${currentAnnouncement.id}');
            print('   Downloaded by data: ${currentAnnouncement.downloadedBy}');
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple. shade400, Colors.deepPurple. shade600],
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
                              currentAnnouncement.title,
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
                        'Published ${DateFormat('MMM dd, yyyy HH:mm').format(currentAnnouncement.createdAt)}',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Content',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentAnnouncement.content,
                                style: const TextStyle(fontSize: 16, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Attachments
                      if (currentAnnouncement.attachmentUrls.isNotEmpty) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons. attach_file, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Attachments',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ... currentAnnouncement.attachmentUrls
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final url = entry.value;
                                      final name = currentAnnouncement.attachmentNames[index];
                                      
                                      // Get download count directly from the model
                                      final downloadKey = index.toString();
                                      final downloadList = currentAnnouncement.downloadedBy[downloadKey] ?? [];
                                      final downloadCount = downloadList.length;
                                      
                                      print('🔍 Attachment $index ($name):');
                                      print('   Key: $downloadKey');
                                      print('   Downloaded by: $downloadList');
                                      print('   Count: $downloadCount');

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.insert_drive_file,
                                              color: Colors.blue,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '$downloadCount downloads',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: downloadCount > 0 
                                                              ? Colors.green 
                                                              : Colors. grey,
                                                          fontWeight: downloadCount > 0 
                                                              ? FontWeight.bold 
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                      if (downloadCount > 0) ...[
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          Icons.check_circle,
                                                          size: 14,
                                                          color: Colors.green,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.download,
                                                color: Colors.blue,
                                              ),
                                              onPressed: () => _downloadAttachment(
                                                index,
                                                url,
                                                name,
                                              ),
                                              tooltip: 'Download',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.people,
                                                color: downloadCount > 0 
                                                    ? Colors.deepPurple 
                                                    : Colors.grey,
                                              ),
                                              onPressed: () async {
                                                await _loadTrackingDataForAnnouncement(
                                                  currentAnnouncement,
                                                );
                                                await Future.delayed(const Duration(milliseconds: 100));
                                                if (mounted) {
                                                  _showDownloaders(index, name);
                                                }
                                              },
                                              tooltip: 'View downloaders ($downloadCount)',
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tracking Stats
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons. analytics, color: Colors.green),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Engagement Tracking',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  TextButton. icon(
                                    onPressed: () {
                                      _loadTrackingDataForAnnouncement(currentAnnouncement);
                                      _showViewers();
                                    },
                                    icon: const Icon(Icons. visibility, size: 18),
                                    label: Text('${currentAnnouncement.viewCount} views'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isLoadingTracking)
                                const Center(child: CircularProgressIndicator())
                              else
                                Text(
                                  'Viewed by ${_viewers.length} student(s)',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Comments Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets. all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.comment, color: Colors.deepPurple),
                                  SizedBox(width: 8),
                                  Text(
                                    'Comments',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                stream: _databaseService.getAnnouncementComments(currentAnnouncement.id),
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
                                    children: snapshot.data!. map((comment) {
                                      return _CommentCard(comment: comment);
                                    }). toList(),
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
          );
        },
      ),
    );
  }
  Future<void> _loadTrackingDataForAnnouncement(
    AnnouncementModel announcement,
  ) async {
    try {
      final viewers = await _databaseService.getStudentsByIds(
        announcement.viewedBy,
      );

      Map<String, List<UserModel>> downloaders = {};
      for (var entry in announcement.downloadedBy.entries) {
        final users = await _databaseService.getStudentsByIds(entry.value);
        downloaders[entry.key] = users;
      }

      if (mounted) {
        setState(() {
          _viewers = viewers;
          _downloaders = downloaders;
          _isLoadingTracking = false;
        });
      }
    } catch (e) {
      print('Error loading tracking: $e');
    }
  }

  Future<void> _downloadAttachment(
    int index,
    String url,
    String fileName,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(
      context,
      listen: false,
    );

    print('🔽 Starting download: index=$index, file=$fileName');
    print('📄 Announcement ID: ${widget.announcement.id}');
    print('👤 User ID: ${authProvider.user?.uid}');

    try {
      // Track download
      if (authProvider.user != null) {
        print('📊 Calling trackDownload...');
        await announcementProvider.trackDownload(
          widget.announcement.id,
          index,
          authProvider.user!.uid,
        );
        print('✅ trackDownload completed');
      } else {
        print('❌ No user logged in! ');
      }

      // Open/download file
      html.window.open(url, '_blank');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showViewers() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Viewers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_viewers.isEmpty)
              const Text('No views yet', style: TextStyle(color: Colors.grey))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _viewers.length,
                  itemBuilder: (context, index) {
                    final user = _viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.displayName[0].toUpperCase()),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDownloaders(int index, String fileName) {
    print('👥 Showing downloaders for index: $index');
    print('📊 All downloaders data: $_downloaders');

    final downloaders = _downloaders[index.toString()] ?? [];

    print('📋 Downloaders for index $index: ${downloaders.length} users');
    if (downloaders.isNotEmpty) {
      for (var user in downloaders) {
        print('  - ${user.displayName} (${user.email})');
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloaded: $fileName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Attachment Index: $index',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Total Downloads: ${downloaders.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (downloaders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No downloads yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: downloaders.length,
                  itemBuilder: (context, idx) {
                    final user = downloaders[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(user.displayName[0].toUpperCase()),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Comment Card Widget
class _CommentCard extends StatelessWidget {
  final AnnouncementCommentModel comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final announcementProvider = Provider.of<AnnouncementProvider>(
      context,
      listen: false,
    );
    final isOwner = comment.userId == authProvider.user?.uid;

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
                backgroundColor: comment.userRole == 'instructor'
                    ? Colors.deepPurple
                    : Colors.blue,
                child: Text(
                  comment.userName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (comment.userRole == 'instructor')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Instructor',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(comment.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
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
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
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
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.comment, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
