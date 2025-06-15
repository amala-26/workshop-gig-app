import 'package:cloud_firestore/cloud_firestore.dart';

class GigModel {
  final String? id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String startTime;
  final String endTime;
  final double remuneration;
  final int foremenNeeded;
  final String ownerId;

  GigModel({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.remuneration,
    required this.foremenNeeded,
    required this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'remuneration': remuneration,
      'foremenNeeded': foremenNeeded,
      'ownerId': ownerId,
    };
  }

  factory GigModel.fromMap(Map<String, dynamic> map) {
    return GigModel(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      remuneration: (map['remuneration'] ?? 0.0).toDouble(),
      foremenNeeded: map['foremenNeeded'] ?? 0,
      ownerId: map['ownerId'] ?? '',
    );
  }

  GigModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    String? startTime,
    String? endTime,
    double? remuneration,
    int? foremenNeeded,
    String? ownerId,
  }) {
    return GigModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      remuneration: remuneration ?? this.remuneration,
      foremenNeeded: foremenNeeded ?? this.foremenNeeded,
      ownerId: ownerId ?? this.ownerId,
    );
  }
} 