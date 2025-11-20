// lib/screens/tabs/workout_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/ble_controller.dart';
import '../../controllers/workout_controller.dart';
import 'package:flutter/cupertino.dart';


class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  final WorkoutController wc = Get.find();
  final BLEController bc = Get.find();

  // Biến cho UI cài đặt
  bool _isTimeGoal = true; // true = Time, false = Calories
  final TextEditingController _goalController = TextEditingController(text: "30"); // Mặc định 30 phút

  // Widget hiển thị khi CHƯA TẬP (Idle)
  Widget _buildSetupUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Thiết lập Mục tiêu",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Nút gạt chọn Thời gian / Calories
          CupertinoSegmentedControl<bool>(
            children: {
              true: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("Thời gian".tr, style: const TextStyle(fontSize: 16))),
              false: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text("Calories".tr, style: const TextStyle(fontSize: 16))),
            },
            groupValue: _isTimeGoal,
            onValueChanged: (bool newValue) {
              setState(() {
                _isTimeGoal = newValue;
                // Cập nhật giá trị mặc định khi gạt
                _goalController.text = newValue ? "30" : "100";
              });
            },
            selectedColor: Theme.of(context).primaryColor,
            borderColor: Theme.of(context).primaryColor,
            pressedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          
          // Trường nhập giá trị
          TextField(
            controller: _goalController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _isTimeGoal ? "Số phút" : "Số kcal",
              suffixText: _isTimeGoal ? "phút" : "kcal",
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 48),

          // Nút Start
          ElevatedButton(
            onPressed: () {
              int value = int.tryParse(_goalController.text) ?? 0;
              if (value > 0) {
                String goalType = _isTimeGoal ? 'time' : 'calories';
                wc.startWorkout(goalType, value);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
            child: const Text(
              "BẮT ĐẦU",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // Widget hiển thị khi ĐANG TẬP (Running)
  Widget _buildRunningUI(BuildContext context) {
    // Hàm helper để định dạng thời gian
    String formatDuration(Duration d) {
      final hours = d.inHours.toString().padLeft(2, '0');
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$hours:$minutes:$seconds";
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Mục tiêu
          Obx(() => Text(
            wc.goalDisplay.value,
            style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
          )),
          const SizedBox(height: 16),

          // Thời gian (chỉ số chính)
          Obx(() => Text(
            formatDuration(wc.sessionDuration.value),
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          )),
          Text("Thời gian", style: Theme.of(context).textTheme.headlineSmall),
          const Divider(height: 32),

          // Các chỉ số phụ
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  title: 'heart_rate'.tr,
                  value: bc.heartRate.value, // Lấy trực tiếp từ BLE
                  unit: "BPM",
                  color: Colors.red,
                ),
                _buildMetricCard(
                  title: 'spo2'.tr,
                  value: bc.spO2.value, // Lấy trực tiếp từ BLE
                  unit: "%",
                  color: Colors.blue,
                ),
                Obx(() => _buildMetricCard( // Lấy từ WorkoutController
                  title: 'steps'.tr,
                  value: wc.sessionSteps.value.toString(),
                  unit: "bước",
                  color: Colors.green,
                )),
                Obx(() => _buildMetricCard( // Lấy từ WorkoutController
                  title: "Quãng đường",
                  value: wc.sessionDistance.value.toStringAsFixed(2),
                  unit: "km",
                  color: Colors.purple,
                )),
              ],
            ),
          ),

          // Nút End
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                wc.endWorkout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "KẾT THÚC",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Card hiển thị chỉ số (cho UI đang chạy)
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tự động chọn UI dựa trên trạng thái
    return Obx(() {
      if (wc.workoutState.value == WorkoutState.running) {
        return _buildRunningUI(context);
      } else {
        return _buildSetupUI(context);
      }
    });
  }
}