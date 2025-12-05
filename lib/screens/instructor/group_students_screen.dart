import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';

class GroupStudentsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupStudentsScreen({super.key, required this.group});

  @override
  State<GroupStudentsScreen> createState() => _GroupStudentsScreenState();
}

class _GroupStudentsScreenState extends State<GroupStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons. person_add),
            onPressed: () => _showAddStudentDialog(),
          ),
        ],
      ),
      body: StreamBuilder<GroupModel? >(
        stream: _databaseService.getGroupsByCourse(widget.group.courseId)
            .map((groups) => groups.firstWhere(
                  (g) => g.id == widget. group.id,
                  orElse: () => widget.group,
                )),
        builder: (context, groupSnapshot) {
          if (groupSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentGroup = groupSnapshot.data ??  widget.group;

          if (currentGroup. studentIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors. grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students in this group',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add students',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<UserModel>>(
            future: _databaseService.getStudentsByIds(currentGroup.studentIds),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState. waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (! studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No students found'),
                );
              }

              final students = studentSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _StudentCard(
                    student: student,
                    groupId: currentGroup.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddStudentDialog(
        group: widget.group,
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final String groupId;

  const _StudentCard({
    required this.student,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          backgroundImage: student.avatarUrl != null
              ? NetworkImage(student.avatarUrl!)
              : null,
          child: student.avatarUrl == null
              ? Text(
                  student.displayName[0]. toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        title: Text(student.displayName),
        subtitle: Text(student.email),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _showRemoveDialog(context, student),
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, UserModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Remove ${student.displayName} from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              
              try {
                await groupProvider.removeStudentFromGroup(groupId, student.uid);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${student.displayName} removed from group'),
                    ),
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  final GroupModel group;

  const _AddStudentDialog({
    required this.group,
  });

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  String _searchQuery = '';
  final Set<String> _selectedStudentIds = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add Students',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search students...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 16),

            // Student List with real-time updates
            Expanded(
              child: StreamBuilder<GroupModel?>(
                stream: DatabaseService().getGroupsByCourse(widget.group.courseId)
                    .map((groups) => groups.firstWhere(
                          (g) => g.id == widget.group.id,
                          orElse: () => widget.group,
                        )),
                builder: (context, groupSnapshot) {
                  final currentGroup = groupSnapshot.data ?? widget.group;
                  
                  return Consumer<StudentProvider>(
                    builder: (context, studentProvider, child) {
                      var students = studentProvider.students
                          .where((s) => ! currentGroup.studentIds.contains(s.uid))
                          .toList();

                      if (_searchQuery.isNotEmpty) {
                        students = students.where((s) {
                          return s.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              s.email. toLowerCase().contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      if (students.isEmpty) {
                        return const Center(
                          child: Text('No students available'),
                        );
                      }

                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final isSelected = _selectedStudentIds.contains(student.uid);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStudentIds.add(student.uid);
                                } else {
                                  _selectedStudentIds.remove(student.uid);
                                }
                              });
                            },
                            title: Text(student.displayName),
                            subtitle: Text(student.email),
                            secondary: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(student.displayName[0].toUpperCase()),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // Add Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedStudentIds.isEmpty ?  null : _addStudents,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'ADD ${_selectedStudentIds.length} STUDENT${_selectedStudentIds.length != 1 ? 'S' : ''}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudents() async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    try {
      for (String studentId in _selectedStudentIds) {
        await groupProvider. addStudentToGroup(widget. group.id, studentId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedStudentIds.length} student${_selectedStudentIds.length != 1 ? 's' : ''} added to group',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}