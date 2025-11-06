import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isInstructor => _user?.isInstructor ?? false;
  bool get isStudent => _user?.isStudent ?? false;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider.initialize');
      var currentUser = _authService.currentUser;
      print('Current Firebase user: ${currentUser?.uid}');
      
      if (currentUser != null) {
        _user = await _authService.getUserData(currentUser.uid);
        print('User data loaded: ${_user?.displayName}');
      } else {
        print('No current user');
      }
    } catch (e) {
      _error = e.toString();
      print('Initialize error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      print('AuthProvider.signIn called');
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signIn(email, password);
      
      print('AuthProvider: User after sign in: ${_user?.displayName}');

      _isLoading = false;
      notifyListeners();

      if (_user == null) {
        _error = 'Login failed: User data not found';
        return false;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('AuthProvider sign in error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Sign out error: $e');
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}