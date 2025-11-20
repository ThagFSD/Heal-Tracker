class HealthDataPoint {
  final DateTime timestamp;
  final int spO2;
  final int heartRate;
  final int steps;
  final int calories;

  HealthDataPoint({
    required this.timestamp,
    required this.spO2,
    required this.heartRate,
    required this.steps,
    required this.calories,
  });
}