// lib/controllers/workout_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // [NEW]
import 'package:firebase_auth/firebase_auth.dart';     // [NEW]
import 'package:get/get.dart';
import '../models/workout_session.dart';               // [NEW]
import 'ble_controller.dart';
import 'profile_controller.dart';

enum WorkoutState { idle, running }

class WorkoutController extends GetxController {
  final BLEController bleController = Get.find();
  final ProfileController profileController = Get.find();
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var workoutState = WorkoutState.idle.obs;
  var sessionDuration = Duration.zero.obs;
  var sessionSteps = 0.obs;
  var sessionDistance = 0.0.obs;
  var sessionCalories = 0.obs;
  var goalDisplay = "---".obs;

  Timer? _sessionTimer;
  StreamSubscription? _stepsSubscription;
  StreamSubscription? _caloriesSubscription;
  int _initialSteps = 0;
  int _initialCalories = 0;
  
  // Lưu thời gian bắt đầu để lưu vào history
  DateTime? _startTime;

  void startWorkout(String goalType, int goalValue) {
    _initialSteps = int.tryParse(bleController.steps.value) ?? 0;
    _initialCalories = int.tryParse(bleController.calories.value) ?? 0;
    _startTime = DateTime.now(); // [NEW]

    sessionDuration.value = Duration.zero;
    sessionSteps.value = 0;
    sessionDistance.value = 0.0;
    sessionCalories.value = 0;

    if (goalType == 'time') {
      goalDisplay.value = "Mục tiêu: $goalValue phút";
    } else {
      goalDisplay.value = "Mục tiêu: $goalValue kcal";
    }

    bleController.sendCommand("S");

    workoutState.value = WorkoutState.running;
    _startTimer();
    _listenToMetrics();
  }

  // [UPDATED] End Workout and Save to Firebase
  Future<void> endWorkout() async {
    bleController.sendCommand("E");

    // 1. Lưu session hiện tại vào biến tạm trước khi reset
    final finishedSession = WorkoutSession(
      id: '', // Firestore sẽ tự tạo ID
      startTime: _startTime ?? DateTime.now(),
      durationSeconds: sessionDuration.value.inSeconds,
      steps: sessionSteps.value,
      calories: sessionCalories.value,
      distanceKm: sessionDistance.value,
      goalType: goalDisplay.value,
    );

    // 2. Reset trạng thái
    workoutState.value = WorkoutState.idle;
    _sessionTimer?.cancel();
    _stepsSubscription?.cancel();
    _caloriesSubscription?.cancel();

    // 3. Lưu vào Firebase
    await _saveSessionToFirebase(finishedSession);
  }

  Future<void> _saveSessionToFirebase(WorkoutSession session) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('workouts') // Collection mới cho Workouts
          .add(session.toMap());
      
      Get.snackbar("Thành công", "Đã lưu kết quả tập luyện!");
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể lưu kết quả tập luyện: $e");
    }
  }

  void _startTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sessionDuration.value += const Duration(seconds: 1);
    });
  }

  void _listenToMetrics() {
    _stepsSubscription?.cancel();
    _stepsSubscription = bleController.steps.listen((totalStepsStr) {
      int totalSteps = int.tryParse(totalStepsStr) ?? 0;
      // Đảm bảo không âm nếu thiết bị reset
      int diff = totalSteps - _initialSteps;
      if (diff < 0) _initialSteps = totalSteps; 
      
      sessionSteps.value = diff > 0 ? diff : 0;
      sessionDistance.value = _calculateDistanceKm(sessionSteps.value);
    });

    _caloriesSubscription?.cancel();
    _caloriesSubscription = bleController.calories.listen((totalCaloriesStr) {
      int totalCalories = int.tryParse(totalCaloriesStr) ?? 0;
      int diff = totalCalories - _initialCalories;
      sessionCalories.value = diff > 0 ? diff : 0;
    });
  }

  double _calculateDistanceKm(int steps) {
    int heightCm = profileController.height.value;
    if (heightCm == 0) heightCm = 170;
    double strideLengthCm = heightCm * 0.414;
    double totalMeters = (steps * strideLengthCm) / 100;
    return totalMeters / 1000;
  }

  @override
  void onClose() {
    _sessionTimer?.cancel();
    _stepsSubscription?.cancel();
    _caloriesSubscription?.cancel();
    super.onClose();
  }
}