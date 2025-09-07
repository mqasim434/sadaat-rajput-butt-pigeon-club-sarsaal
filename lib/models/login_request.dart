/// Request model for login operations
class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  /// Creates a LoginRequest from JSON data
  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  /// Converts LoginRequest to JSON
  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }

  /// Validates the login request
  bool get isValid {
    return username.isNotEmpty && password.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginRequest &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => username.hashCode ^ password.hashCode;

  @override
  String toString() {
    return 'LoginRequest(username: $username, password: [PROTECTED])';
  }
}

