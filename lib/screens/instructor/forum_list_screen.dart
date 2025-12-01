import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/course_model.dart';
import '../../models/forum_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/forum_provider.dart';
import 'forum_detail_screen.dart';
import 'forum_form_screen.dart';

class ForumListScreen extends StatefulWidget {
  final CourseModel course;

  const ForumListScreen({super.key, required this.course});

  @override
  State<ForumListScreen> createState() => _ForumListScreenState();
}

class _ForumListScreenState extends State<ForumListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ForumModel>? _searchResults;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController. dispose();
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

  Future<void> _deleteForum(ForumModel forum) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forum Topic'),
        content: Text('Are you sure you want to delete "${forum.title}"?'),
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
      await forumProvider.deleteForum(forum.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forum topic deleted'),
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
    }
  }

  Future<void> _togglePin(ForumModel forum) async {
    try {
      final forumProvider = Provider.of<ForumProvider>(context, listen: false);
      await forumProvider.togglePin(forum.id, ! forum.isPinned);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleLock(ForumModel forum) async {
    try {
      final forumProvider = Provider.of<ForumProvider>(context, listen: false);
      await forumProvider.toggleLock(forum.id, !forum.isLocked);
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
    final forumProvider = Provider.of<ForumProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Forums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForumFormScreen(course: widget.course),
                ),
              );
            },
            tooltip: 'Create New Topic',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets. all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search forums...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons. clear),
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (! snapshot.hasData || snapshot.data!.isEmpty) {
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
                                  const SizedBox(height: 8),
                                  ElevatedButton. icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ForumFormScreen(course: widget.course),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create First Topic'),
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
                              return _ForumCard(
                                forum: forums[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForumDetailScreen(
                                        forum: forums[index],
                                      ),
                                    ),
                                  );
                                },
                                onEdit: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ForumFormScreen(
                                        course: widget.course,
                                        forum: forums[index],
                                      ),
                                    ),
                                  );
                                },
                                onDelete: () => _deleteForum(forums[index]),
                                onTogglePin: () => _togglePin(forums[index]),
                                onToggleLock: () => _toggleLock(forums[index]),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults! .isEmpty) {
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
      itemCount: _searchResults!. length,
      itemBuilder: (context, index) {
        return _ForumCard(
          forum: _searchResults![index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ForumDetailScreen(
                  forum: _searchResults![index],
                ),
              ),
            );
          },
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ForumFormScreen(
                  course: widget.course,
                  forum: _searchResults![index],
                ),
              ),
            );
          },
          onDelete: () => _deleteForum(_searchResults![index]),
          onTogglePin: () => _togglePin(_searchResults![index]),
          onToggleLock: () => _toggleLock(_searchResults![index]),
        );
      },
    );
  }
}

class _ForumCard extends StatelessWidget {
  final ForumModel forum;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleLock;

  const _ForumCard({
    required this.forum,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: forum.isPinned ? 3 : 1,
      color: forum.isPinned ? Colors.amber. shade50 : null,
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
                    const Icon(Icons.push_pin, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                  ],
                  if (forum.isLocked) ...[
                    const Icon(Icons.lock, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      forum.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'pin':
                          onTogglePin();
                          break;
                        case 'lock':
                          onToggleLock();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              forum.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(forum. isPinned ? 'Unpin' : 'Pin'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'lock',
                        child: Row(
                          children: [
                            Icon(
                              forum.isLocked ? Icons. lock_open : Icons.lock,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(forum. isLocked ? 'Unlock' : 'Lock'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                forum. description,
                style: TextStyle(fontSize: 14, color: Colors. grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tags
              if (forum.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: forum. tags.map((tag) {
                    return Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors. blue.shade50,
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
                  const Icon(Icons.comment, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${forum.replyCount} replies',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Last activity: ${DateFormat('MMM dd, HH:mm').format(forum. lastActivityAt)}',
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