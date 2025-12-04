import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/database_service.dart';
import 'chat_screen.dart';
import '../../models/conversation_model.dart';

class NewInstructorMessageScreen extends StatefulWidget {
  const NewInstructorMessageScreen({super.key});

  @override
  State<NewInstructorMessageScreen> createState() => _NewInstructorMessageScreenState();
}

class _NewInstructorMessageScreenState extends State<NewInstructorMessageScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<UserModel> _students = [];
  List<UserModel> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        // Get students from instructor's courses
        final students = await _databaseService.getStudentsForInstructor(
          authProvider.user!.uid,
        );

        if (! mounted) return;

        setState(() {
          _students = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final nameLower = student.displayName.toLowerCase();
          final emailLower = student.email.toLowerCase();
          final studentIdLower = (student.studentId ??  '').toLowerCase();
          final searchLower = query.toLowerCase();

          return nameLower.contains(searchLower) ||
              emailLower.contains(searchLower) ||
              studentIdLower.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _startConversation(UserModel student) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    try {
      if (! mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting conversation.. .')),
      );

      // Get or create conversation
      final conversationId = await messageProvider.getOrCreateConversation(
        student.uid,  
        authProvider.user! .uid,  
      );

      // Create conversation model
      final conversation = ConversationModel(
        id: conversationId,
        studentId: student.uid,
        instructorId: authProvider. user!.uid,
        lastMessage: '',
        lastMessageAt: DateTime.now(),
        lastMessageSenderId: '',
        createdAt: DateTime.now(),
      );

      if (!mounted) return;

      // Navigate to chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversation: conversation,
            otherUser: student,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets. all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterStudents,
            ),
          ),

          // Student list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isEmpty
                                  ? Icons.people_outline
                                  : Icons. search_off,
                              size: 80,
                              color: Colors. grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No students found'
                                  : 'No matching students',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Students will appear here when they enroll in your courses'
                                  : 'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors. grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredStudents. length,
                        itemBuilder: (context, index) {
                          final student = _filteredStudents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  student.displayName. isNotEmpty
                                      ?  student.displayName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(student.displayName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student.email),
                                  if (student.studentId != null)
                                    Text(
                                      'ID: ${student.studentId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _startConversation(student),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}