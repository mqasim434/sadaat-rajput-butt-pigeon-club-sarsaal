import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String tournamentId;
  final String name;
  final String captain;
  final List<String> pigeonIds;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.captain,
    required this.pigeonIds,
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      name: json['name'] ?? '',
      captain: json['captain'] ?? '',
      pigeonIds: List<String>.from(json['pigeonIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'name': name,
      'captain': captain,
      'pigeonIds': pigeonIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Method to get JSON without the id field for Firestore storage
  Map<String, dynamic> toFirestoreJson() {
    return {
      'tournamentId': tournamentId,
      'name': name,
      'captain': captain,
      'pigeonIds': pigeonIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
