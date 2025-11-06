import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      // Special handling for admin credentials
      String loginEmail = email;
      if (email == AppConstants.adminEmail) {
        loginEmail = AppConstants.adminEmailFull;
        
        // Check if admin account exists, if not create it
        try {
          UserCredential result = await _auth.signInWithEmailAndPassword(
            email: loginEmail,
            password: password,
          );
          return await getUserData(result.user!.uid);
        } catch (e) {
          // Admin doesn't exist, create it
          if (password == AppConstants.adminPassword) {
            return await _createAdminAccount();
          }
          throw 'Invalid admin credentials';
        }
      }

      // Regular user login
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );

      return await getUserData(result.user!.uid);
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Create admin account (first time only)
  Future<UserModel> _createAdminAccount() async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: AppConstants.adminEmailFull,
        password: AppConstants.adminPassword,
      );

      UserModel adminUser = UserModel(
        uid: result.user!.uid,
        email: AppConstants.adminEmailFull,
        displayName: 'Administrator',
        role: AppConstants.roleInstructor,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(result.user!.uid)
          .set(adminUser.toMap());

      return adminUser;
    } catch (e) {
      print('Create admin error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create student account (by instructor)
  Future<UserModel> createStudentAccount({
    required String email,
    required String password,
    required String displayName,
    String? studentId,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel student = UserModel(
        uid: result.user!.uid,
        email: email,
        displayName: displayName,
        role: AppConstants.roleStudent,
        studentId: studentId,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(result.user!.uid)
          .set(student.toMap());

      return student;
    } catch (e) {
      print('Create student error: $e');
      rethrow;
    }
  }
}