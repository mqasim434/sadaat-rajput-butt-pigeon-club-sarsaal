import 'package:cloud_firestore/cloud_firestore.dart';

class Tournament {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final int numberOfDays;
  final List<TournamentDay> days;
  final DateTime createdAt;
  final String createdBy;

  Tournament({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.numberOfDays,
    required this.days,
    required this.createdAt,
    required this.createdBy,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      location: json['location'] ?? '',
      numberOfDays: json['numberOfDays'] ?? 1,
      days:
          (json['days'] as List<dynamic>?)
              ?.map((day) => TournamentDay.fromJson(day))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'numberOfDays': numberOfDays,
      'days': days.map((day) => day.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // Method to get JSON without the id field for Firestore storage
  Map<String, dynamic> toFirestoreJson() {
    return {
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'numberOfDays': numberOfDays,
      'days': days.map((day) => day.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}

class TournamentDay {
  final int dayNumber;
  final DateTime date;
  final bool isActive;

  TournamentDay({
    required this.dayNumber,
    required this.date,
    this.isActive = false,
  });

  factory TournamentDay.fromJson(Map<String, dynamic> json) {
    return TournamentDay(
      dayNumber: json['dayNumber'] ?? 1,
      date: (json['date'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'date': Timestamp.fromDate(date),
      'isActive': isActive,
    };
  }
}
