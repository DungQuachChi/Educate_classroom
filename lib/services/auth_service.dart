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
      print('AuthService.signIn called with email: $email');
      
      String loginEmail = email;
      String loginPassword = password;
      
      // Special handling for admin credentials
      if (email == AppConstants.adminEmail) {
        print('Admin login detected');
        loginEmail = AppConstants.adminEmailFull;
        
        // Allow "admin" as password but use Firebase-compliant password internally
        if (password == "admin") {
          loginPassword = AppConstants.adminPassword; // "admin123"
        }
        
        print('Using email: $loginEmail');
        
        // Check if admin account exists, if not create it
        try {
          print('Attempting to sign in admin...');
          UserCredential result = await _auth.signInWithEmailAndPassword(
            email: loginEmail,
            password: loginPassword,
          );
          print('Admin sign in successful, UID: ${result.user?.uid}');
          
          UserModel? userData = await getUserData(result.user!.uid);
          print('User data retrieved: ${userData?.displayName}');
          return userData;
        } on FirebaseAuthException catch (e) {
          print('Firebase auth error: ${e.code} - ${e.message}');
          
          // Admin doesn't exist, create it
          if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
            if (password == "admin" || password == AppConstants.adminPassword) {
              print('Creating admin account...');
              return await _createAdminAccount();
            }
          }
          throw 'Invalid admin credentials: ${e.message}';
        }
      }

      // Regular user login
      print('Regular user login for: $loginEmail');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: loginEmail,
        password: password,
      );
      
      print('User sign in successful, UID: ${result.user?.uid}');
      return await getUserData(result.user!.uid);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      throw 'Authentication error: ${e.message ?? e.code}';
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Create admin account (first time only)
  Future<UserModel> _createAdminAccount() async {
    try {
      print('Creating new admin account...');
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: AppConstants.adminEmailFull,
        password: AppConstants.adminPassword, // "admin123"
      );

      print('Admin account created, UID: ${result.user?.uid}');

      UserModel adminUser = UserModel(
        uid: result.user!.uid,
        email: AppConstants.adminEmailFull,
        displayName: 'Administrator',
        role: AppConstants.roleInstructor,
        createdAt: DateTime.now(),
      );

      print('Saving admin user data to Firestore...');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(result.user!.uid)
          .set(adminUser.toMap());

      print('Admin user data saved successfully');
      return adminUser;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException creating admin: ${e.code} - ${e.message}');
      throw 'Failed to create admin account: ${e.message ?? e.code}';
    } catch (e) {
      print('Create admin error: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
// Get user data from Firestore
Future<UserModel?> getUserData(String uid) async {
  try {
    print('Getting user data for UID: $uid');
    
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (doc.exists) {
      print('User document found');
      UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      print('User parsed: ${user.displayName}, role: ${user.role}');
      
      // Check if user is active
      if (!user.isActive) {
        print('User account is disabled');
        throw 'This account has been disabled. Please contact administrator.';
      }
      
      return user;
    } else {
      print('User document not found in Firestore');
      return null;
    }
  } catch (e) {
    print('Get user data error: $e');
    rethrow;
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
      // Ensure password is at least 6 characters
      if (password.length < 6) {
        throw 'Password must be at least 6 characters';
      }
      
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