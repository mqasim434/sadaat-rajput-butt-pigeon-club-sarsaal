import 'user.dart';

/// Result model for login operations
class LoginResult {
  final bool success;
  final User? user;
  final String? token;
  final String? errorMessage;

  const LoginResult({
    required this.success,
    this.user,
    this.token,
    this.errorMessage,
  });

  /// Creates a successful login result
  factory LoginResult.success({required User user, String? token}) {
    return LoginResult(success: true, user: user, token: token);
  }

  /// Creates a failed login result
  factory LoginResult.failure({required String errorMessage}) {
    return LoginResult(success: false, errorMessage: errorMessage);
  }

  /// Creates a LoginResult from JSON data
  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      success: json['success'] as bool,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      token: json['token'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Converts LoginResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user?.toJson(),
      'token': token,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'LoginResult(success: $success, user: $user, errorMessage: $errorMessage)';
  }
}

