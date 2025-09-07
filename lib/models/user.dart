/// User model representing a user in the system
class User {
  final String id;
  final String username;

  const User({required this.id, required this.username});

  /// Creates a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'] as String, username: json['username'] as String);
  }

  /// Converts User to JSON
  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username};
  }

  /// Creates a copy of this User with updated fields
  User copyWith({String? id, String? username}) {
    return User(id: id ?? this.id, username: username ?? this.username);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username)';
  }
}
