import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/semester_provider.dart';
import 'auth/login_screen.dart';
import 'instructor/instructor_home_screen.dart';
import 'student/student_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      if (!mounted) return;

      // Navigate based on auth state
      Widget nextScreen;
      
      if (authProvider.isLoggedIn && authProvider.user != null) {
        // Initialize semester provider for logged in users
        final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
        await semesterProvider.initialize();

        if (!mounted) return;

        if (authProvider.isInstructor) {
          nextScreen = const InstructorHomeScreen();
        } else {
          nextScreen = const StudentHomeScreen();
        }
      } else {
        nextScreen = const LoginScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } catch (e) {
      print('Initialization error: $e');
      if (!mounted) return;
      
      // On error, go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Educate Classroom',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}