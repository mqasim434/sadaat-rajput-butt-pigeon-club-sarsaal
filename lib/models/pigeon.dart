import 'package:cloud_firestore/cloud_firestore.dart';

class Pigeon {
  final String id;
  final String teamId;
  final String tournamentId;
  final String name;
  final bool isHelper;
  final int day;
  final List<Flight> flights;
  final DateTime createdAt;

  Pigeon({
    required this.id,
    required this.teamId,
    required this.tournamentId,
    required this.name,
    required this.isHelper,
    required this.day,
    required this.flights,
    required this.createdAt,
  });

  factory Pigeon.fromJson(Map<String, dynamic> json) {
    return Pigeon(
      id: json['id'] ?? '',
      teamId: json['teamId'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      name: json['name'] ?? '',
      isHelper: json['isHelper'] ?? false,
      day: json['day'] ?? 1,
      flights:
          (json['flights'] as List<dynamic>?)
              ?.map((flight) => Flight.fromJson(flight))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamId': teamId,
      'tournamentId': tournamentId,
      'name': name,
      'isHelper': isHelper,
      'day': day,
      'flights': flights.map((flight) => flight.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Method to get JSON without the id field for Firestore storage
  Map<String, dynamic> toFirestoreJson() {
    return {
      'teamId': teamId,
      'tournamentId': tournamentId,
      'name': name,
      'isHelper': isHelper,
      'day': day,
      'flights': flights.map((flight) => flight.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Duration get totalFlightTime {
    return flights.fold(
      Duration.zero,
      (total, flight) => total + flight.flightDuration,
    );
  }
}

class Flight {
  final String id;
  final String pigeonId;
  final String teamId;
  final String tournamentId;
  final int day;
  final DateTime takeoffTime;
  final DateTime? landingTime;
  final Duration flightDuration;
  final String notes;
  final DateTime createdAt;

  Flight({
    required this.id,
    required this.pigeonId,
    required this.teamId,
    required this.tournamentId,
    required this.day,
    required this.takeoffTime,
    this.landingTime,
    required this.flightDuration,
    required this.notes,
    required this.createdAt,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] ?? '',
      pigeonId: json['pigeonId'] ?? '',
      teamId: json['teamId'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      day: json['day'] ?? 1,
      takeoffTime: (json['takeoffTime'] as Timestamp).toDate(),
      landingTime: json['landingTime'] != null
          ? (json['landingTime'] as Timestamp).toDate()
          : null,
      flightDuration: Duration(milliseconds: json['flightDuration'] ?? 0),
      notes: json['notes'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pigeonId': pigeonId,
      'teamId': teamId,
      'tournamentId': tournamentId,
      'day': day,
      'takeoffTime': Timestamp.fromDate(takeoffTime),
      'landingTime': landingTime != null
          ? Timestamp.fromDate(landingTime!)
          : null,
      'flightDuration': flightDuration.inMilliseconds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Method to get JSON without the id field for Firestore storage
  Map<String, dynamic> toFirestoreJson() {
    return {
      'pigeonId': pigeonId,
      'teamId': teamId,
      'tournamentId': tournamentId,
      'day': day,
      'takeoffTime': Timestamp.fromDate(takeoffTime),
      'landingTime': landingTime != null
          ? Timestamp.fromDate(landingTime!)
          : null,
      'flightDuration': flightDuration.inMilliseconds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isCompleted => landingTime != null;
}
