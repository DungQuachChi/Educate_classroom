import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart';
import '../../models/forum_model.dart';
import '../../providers/forum_provider.dart';
import 'student_forum_detail_screen.dart';
import '../instructor/forum_form_screen.dart';

class StudentForumListScreen extends StatefulWidget {
  final CourseModel course;

  const StudentForumListScreen({super.key, required this.course});

  @override
  State<StudentForumListScreen> createState() => _StudentForumListScreenState();
}

class _StudentForumListScreenState extends State<StudentForumListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ForumModel>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchForums(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final forumProvider = Provider.of<ForumProvider>(context, listen: false);
    final results = await forumProvider.searchForums(widget.course.id, query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumProvider = Provider.of<ForumProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Forums'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search forums...',
                prefixIcon: const Icon(Icons. search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchForums('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchForums,
            ),
          ),

          // Forum List
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults != null
                    ? _buildSearchResults()
                    : StreamBuilder<List<ForumModel>>(
                        stream: forumProvider.getForumsByCourse(widget.course.id),
                        builder: (context, snapshot) {
                          if (snapshot. connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot. data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.forum, size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No forum topics yet',
                                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }

                          final forums = snapshot.data!;
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: forums.length,
                            itemBuilder: (context, index) {
                              return _StudentForumCard(
                                forum: forums[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentForumDetailScreen(
                                        forum: forums[index],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton. extended(
        onPressed: () {
          // Students can also create topics
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ForumFormScreen(course: widget.course),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Topic'),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        return _StudentForumCard(
          forum: _searchResults![index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentForumDetailScreen(
                  forum: _searchResults![index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StudentForumCard extends StatelessWidget {
  final ForumModel forum;
  final VoidCallback onTap;

  const _StudentForumCard({
    required this. forum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: forum.isPinned ? 3 : 1,
      color: forum. isPinned ? Colors.amber. shade50 : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (forum.isPinned) ...[
                    const Icon(Icons.push_pin, size: 20, color: Colors. orange),
                    const SizedBox(width: 8),
                  ],
                  if (forum.isLocked) ...[
                    const Icon(Icons. lock, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      forum. title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                forum.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tags
              if (forum.tags. isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: forum.tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.blue.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Attachments indicator
              if (forum.attachmentUrls.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${forum.attachmentUrls.length} attachment(s)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Footer
              Row(
                children: [
                  const Icon(Icons. comment, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${forum.replyCount} replies',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Last activity: ${DateFormat('MMM dd, HH:mm').format(forum.lastActivityAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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