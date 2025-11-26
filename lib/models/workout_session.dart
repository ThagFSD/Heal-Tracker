// lib/models/workout_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  final String id;
  final DateTime startTime;
  final int durationSeconds;
  final int steps;
  final int calories;
  final double distanceKm;
  final String goalType; // 'time' or 'calories' or 'none'

  WorkoutSession({
    required this.id,
    required this.startTime,
    required this.durationSeconds,
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.goalType,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'durationSeconds': durationSeconds,
      'steps': steps,
      'calories': calories,
      'distanceKm': distanceKm,
      'goalType': goalType,
    };
  }

  factory WorkoutSession.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutSession(
      id: id,
      startTime: (map['startTime'] as Timestamp).toDate(),
      durationSeconds: map['durationSeconds'] ?? 0,
      steps: map['steps'] ?? 0,
      calories: map['calories'] ?? 0,
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      goalType: map['goalType'] ?? 'none',
    );
  }
}