import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'student_chat_screen.dart';
import '../../models/conversation_model.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  List<UserModel> _instructors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final instructors = await messageProvider.getInstructorsForStudent(
          authProvider.user!.uid,
        );

        if (! mounted) return;

        setState(() {
          // Explicit cast to List<UserModel>
          _instructors = List<UserModel>.from(instructors);
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startConversation(UserModel instructor) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageProvider = Provider. of<MessageProvider>(context, listen: false);

    try {
      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting conversation.. .')),
      );

      // Get or create conversation
      final conversationId = await messageProvider.getOrCreateConversation(
        authProvider.user!.uid,
        instructor.uid,
      );

      // Create conversation model for navigation
      final conversation = ConversationModel(
        id: conversationId,
        studentId: authProvider.user!. uid,
        instructorId: instructor.uid,
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
          builder: (_) => StudentChatScreen(
            conversation: conversation,
            otherUser: instructor,
          ),
        ),
      );
    } catch (e) {
      if (! mounted) return;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _instructors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No instructors found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You need to be enrolled in a course first',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _instructors.length,
                  itemBuilder: (context, index) {
                    final instructor = _instructors[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            instructor.displayName. isNotEmpty
                                ? instructor. displayName[0].toUpperCase()
                                : 'I',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(instructor.displayName),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius: BorderRadius.circular(4),
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
                        subtitle: Text(instructor.email),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _startConversation(instructor),
                      ),
                    );
                  },
                ),
    );
  }
}