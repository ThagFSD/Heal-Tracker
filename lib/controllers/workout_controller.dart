// lib/controllers/workout_controller.dart

import 'dart:async';
import 'package:get/get.dart';
import 'ble_controller.dart';
import 'profile_controller.dart';

// Định nghĩa các trạng thái tập luyện
enum WorkoutState { idle, running }

class WorkoutController extends GetxController {
  final BLEController bleController = Get.find();
  final ProfileController profileController = Get.find();

  // Biến trạng thái
  var workoutState = WorkoutState.idle.obs;
  var sessionDuration = Duration.zero.obs;
  var sessionSteps = 0.obs;
  var sessionDistance = 0.0.obs;
  var sessionCalories = 0.obs; // Calo trong phiên
  var goalDisplay = "---".obs;

  // Biến nội bộ
  Timer? _sessionTimer;
  StreamSubscription? _stepsSubscription;
  StreamSubscription? _caloriesSubscription;
  int _initialSteps = 0;
  int _initialCalories = 0;

  // Bắt đầu một buổi tập mới
  void startWorkout(String goalType, int goalValue) {
    // 1. Lấy giá trị ban đầu để so sánh
    _initialSteps = int.tryParse(bleController.steps.value) ?? 0;
    _initialCalories = int.tryParse(bleController.calories.value) ?? 0;

    // 2. Reset giá trị phiên
    sessionDuration.value = Duration.zero;
    sessionSteps.value = 0;
    sessionDistance.value = 0.0;
    sessionCalories.value = 0;

    // 3. Đặt mục tiêu
    if (goalType == 'time') {
      goalDisplay.value = "Mục tiêu: $goalValue phút";
    } else {
      goalDisplay.value = "Mục tiêu: $goalValue kcal";
    }

    // 4. Gửi lệnh "S" (Start) đến ESP32
    bleController.sendCommand("S");

    // 5. Bắt đầu theo dõi
    workoutState.value = WorkoutState.running;
    _startTimer();
    _listenToMetrics();
  }

  // Kết thúc buổi tập
  void endWorkout() {
    // 1. Gửi lệnh "E" (End) đến ESP32
    bleController.sendCommand("E");

    // 2. Dừng theo dõi
    workoutState.value = WorkoutState.idle;
    _sessionTimer?.cancel();
    _stepsSubscription?.cancel();
    _caloriesSubscription?.cancel();
  }

  // Bắt đầu bộ đếm giờ
  void _startTimer() {
    _sessionTimer?.cancel(); // Hủy timer cũ
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sessionDuration.value += const Duration(seconds: 1);
      // (Bạn có thể thêm logic kiểm tra nếu đạt mục tiêu thời gian ở đây)
    });
  }

  // Lắng nghe thay đổi từ BLEController
  void _listenToMetrics() {
    // Lắng nghe Bước chân
    _stepsSubscription?.cancel();
    _stepsSubscription = bleController.steps.listen((totalStepsStr) {
      int totalSteps = int.tryParse(totalStepsStr) ?? 0;
      sessionSteps.value = totalSteps - _initialSteps;
      
      // Tính quãng đường (km)
      sessionDistance.value = _calculateDistanceKm(sessionSteps.value);
    });

    // Lắng nghe Calories
    _caloriesSubscription?.cancel();
    _caloriesSubscription = bleController.calories.listen((totalCaloriesStr) {
      int totalCalories = int.tryParse(totalCaloriesStr) ?? 0;
      sessionCalories.value = totalCalories - _initialCalories;
      // (Bạn có thể thêm logic kiểm tra nếu đạt mục tiêu calories ở đây)
    });
  }

  // Tính quãng đường (công thức giả định)
  double _calculateDistanceKm(int steps) {
    // Lấy chiều cao (cm) từ profile
    int heightCm = profileController.height.value;
    if (heightCm == 0) heightCm = 170; // Mặc định 1.7m

    // Ước tính độ dài sải chân (ví dụ: 41.4% chiều cao)
    double strideLengthCm = heightCm * 0.414;
    double totalMeters = (steps * strideLengthCm) / 100;
    return totalMeters / 1000; // Đổi sang km
  }

  // Dọn dẹp khi controller bị hủy
  @override
  void onClose() {
    _sessionTimer?.cancel();
    _stepsSubscription?.cancel();
    _caloriesSubscription?.cancel();
    super.onClose();
  }
}