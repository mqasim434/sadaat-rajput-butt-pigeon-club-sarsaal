import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_request.dart';
import '../models/login_result.dart';
import '../models/user.dart';
import 'exceptions.dart';

/// Service responsible for handling authentication operations
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Storage keys
  static const String _userKey = 'pigeon_track_user';
  static const String _tokenKey = 'pigeon_track_token';

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  User? _currentUser;
  String? _currentToken;
  bool _isInitialized = false;

  /// Gets the currently authenticated user
  User? get currentUser => _currentUser;

  /// Gets the current authentication token
  String? get currentToken => _currentToken;

  /// Checks if a user is currently authenticated
  bool get isAuthenticated {
    if (!_isInitialized) {
      // If not initialized, try to load from storage synchronously
      _loadAuthStateSync();
    }
    return _currentUser != null && _currentToken != null;
  }

  /// Authenticates a user with the provided credentials using Firestore
  Future<LoginResult> login(LoginRequest request) async {
    try {
      // Validate the request
      if (!request.isValid) {
        throw const ValidationException('Username and password are required');
      }

      // Query Firestore for the user
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: request.username.trim())
          .where('password', isEqualTo: request.password.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw const AuthenticationException('Invalid username or password');
      }

      // Get the user document
      final DocumentSnapshot userDoc = querySnapshot.docs.first;
      final Map<String, dynamic> userData =
          userDoc.data() as Map<String, dynamic>;

      // Create User object from Firestore data
      final user = User(
        id: userDoc.id,
        username: userData['username'] as String,
      );

      // Generate a mock token
      final token = _generateMockToken(user);

      // Store authentication state
      _currentUser = user;
      _currentToken = token;

      // Save to persistent storage
      await _saveAuthState();

      return LoginResult.success(user: user, token: token);
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServiceException(
        'Firebase error during login: ${e.message ?? 'Unknown error'}',
        code: e.code,
        originalError: e,
      );
    } catch (error) {
      throw ServiceException(
        'An unexpected error occurred during login',
        originalError: error,
      );
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Clear authentication state
      _currentUser = null;
      _currentToken = null;

      // Clear from persistent storage
      await _clearAuthState();
    } catch (error) {
      throw ServiceException(
        'An error occurred during logout',
        originalError: error,
      );
    }
  }

  /// Validates the current session
  Future<bool> validateSession() async {
    try {
      // In a real app, this would validate the token with the server
      await Future.delayed(const Duration(milliseconds: 200));

      return isAuthenticated;
    } catch (error) {
      throw ServiceException(
        'An error occurred while validating session',
        originalError: error,
      );
    }
  }

  /// Refreshes the authentication token
  Future<String?> refreshToken() async {
    try {
      if (!isAuthenticated) {
        throw const UnauthorizedException('No active session to refresh');
      }

      // Simulate token refresh
      await Future.delayed(const Duration(milliseconds: 500));

      final newToken = _generateMockToken(_currentUser!);
      _currentToken = newToken;

      return newToken;
    } catch (error) {
      throw ServiceException(
        'An error occurred while refreshing token',
        originalError: error,
      );
    }
  }

  /// Generates a mock authentication token
  String _generateMockToken(User user) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'mock_token_${user.id}_$timestamp';
  }

  /// Resets the authentication state (for testing purposes)
  void reset() {
    _currentUser = null;
    _currentToken = null;
    _isInitialized = false;
  }

  /// Initializes the auth service by loading persisted state
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);

      if (userJson != null && token != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userMap);
        _currentToken = token;
      }

      _isInitialized = true;
    } on FirebaseException catch (e) {
      // Firebase initialization error - start fresh
      _currentUser = null;
      _currentToken = null;
      _isInitialized = true;
      print('Firebase error during auth initialization: ${e.message}');
    } catch (e) {
      // If there's any other error loading from storage, just start fresh
      _currentUser = null;
      _currentToken = null;
      _isInitialized = true;
      print('Error during auth initialization: $e');
    }
  }

  /// Synchronously loads auth state (for use in getter)
  void _loadAuthStateSync() {
    // This is a fallback - ideally initialize() should be called during app startup
    _isInitialized = true;
    initialize(); // This will load async but we mark as initialized to prevent loops
  }

  /// Saves current authentication state to persistent storage
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentUser != null && _currentToken != null) {
        await prefs.setString(_userKey, json.encode(_currentUser!.toJson()));
        await prefs.setString(_tokenKey, _currentToken!);
      }
    } catch (e) {
      // If saving fails, we can still continue - it just won't persist
      print('Failed to save auth state: $e');
    }
  }

  /// Clears authentication state from persistent storage
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
    } catch (e) {
      // If clearing fails, log but don't throw
      print('Failed to clear auth state: $e');
    }
  }
}
