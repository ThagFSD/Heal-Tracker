// lib/controllers/ble_controller.dart

import 'dart:async'; 
import 'dart:convert';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 

import '../models/health_data.dart';
import '../screens/connect_screen.dart';
import '../screens/home_screen.dart';

class BLEController extends GetxController {
  // Trạng thái BLE
  var scannedDevices = <BluetoothDevice>[].obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  
  // ===========================================
  // SỬA LỖI: Xóa các dòng bị lặp lại
  // ===========================================
  BluetoothCharacteristic? targetCharacteristic; // Dùng để ĐỌC (Notify)
  BluetoothCharacteristic? writeCharacteristic; // Dùng để GHI (Write)
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionStateSubscription;
  // (Đã xóa 3 dòng lặp lại)

  // Trạng thái dữ liệu sức khỏe
  var spO2 = "--".obs;
  var heartRate = "--".obs;
  var steps = "--".obs;
  var calories = "--".obs;
  var healthDataHistory = <HealthDataPoint>[].obs;
  var isScanning = false.obs;

  // Biến cho Chế độ Demo
  Timer? _demoTimer;
  final Random _random = Random();
  int _demoSteps = 1234;
  int _demoCalories = 321;
  var isDemoMode = false.obs;
  var rawDataLog = <String>[].obs;
  final int maxLogSize = 50;

  // Tham chiếu Firebase
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  @override
  void onInit() {
    super.onInit();
    requestPermissions();
  }

  @override
  void onClose() {
    _demoTimer?.cancel();
    _dataSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    super.onClose();
  }

  Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  void startScan() async {
    isDemoMode.value = false;
    _demoTimer?.cancel();
    scannedDevices.clear();
    rawDataLog.clear();
    isScanning(true);
    await FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.platformName.isNotEmpty &&
            !scannedDevices.any((d) => d.remoteId == result.device.remoteId)) {
          scannedDevices.add(result.device);
        }
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      FlutterBluePlus.stopScan();
      isScanning(false);
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    isDemoMode.value = false;
    _demoTimer?.cancel();
    await FlutterBluePlus.stopScan();
    isScanning(false);
    try {
      await device.connect();
      connectedDevice.value = device;

      _connectionStateSubscription?.cancel(); 
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          Get.snackbar(
            "Đã ngắt kết nối",
            "Thiết bị '${device.platformName}' đã mất kết nối.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[600],
            colorText: Colors.white,
          );
          disconnectDevice();
        }
      });

      Get.offAll(() => const HomeScreen());
      discoverServices(device);
    } catch (e) {
      Get.snackbar("Lỗi kết nối", "Không thể kết nối với thiết bị: $e",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void startDemoMode() {
    connectedDevice.value = BluetoothDevice.fromId('DEMO-ID');
    isDemoMode.value = true;
    rawDataLog.clear();

    Get.offAll(() => const HomeScreen());

    _generateFake7DayHistory();

    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _generateFakeData();
    });
  }

  void _addLogMessage(String message) {
    rawDataLog.insert(0, message);
    if (rawDataLog.length > maxLogSize) {
      rawDataLog.removeRange(maxLogSize, rawDataLog.length);
    }
  }

  void _generateFake7DayHistory() {
    healthDataHistory.clear();
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      int baseSteps = 3000 + _random.nextInt(5000);
      for (int j = 0; j < 10; j++) {
        final timestamp =
            day.copyWith(hour: 9 + j, minute: _random.nextInt(60));
        if (timestamp.isAfter(now)) break;
        int fakeSpo2 = 96 + _random.nextInt(4);
        int fakeHeartRate = 60 + _random.nextInt(30);
        int fakeSteps = baseSteps + (j * (_random.nextInt(50) + 20));
        int fakeCalories = (fakeSteps * 0.04).round();
        final dataPoint = HealthDataPoint(
          timestamp: timestamp,
          spO2: fakeSpo2,
          heartRate: fakeHeartRate,
          steps: fakeSteps,
          calories: fakeCalories,
        );
        healthDataHistory.add(dataPoint);
        _saveDataToFirestore(dataPoint); // Lưu dữ liệu giả vào Firebase
      }
    }
    if (healthDataHistory.isNotEmpty) {
      final lastData = healthDataHistory.last;
      _demoSteps = lastData.steps;
      _demoCalories = lastData.calories;
      spO2.value = lastData.spO2.toString();
      heartRate.value = lastData.heartRate.toString();
      steps.value = lastData.steps.toString();
      calories.value = lastData.calories.toString();
    }
  }

  void _generateFakeData() {
    spO2.value = (95 + _random.nextInt(5)).toString();
    heartRate.value = (65 + _random.nextInt(25)).toString();
    _demoSteps += _random.nextInt(10) + 1;
    _demoCalories = (_demoSteps * 0.04).round();
    steps.value = _demoSteps.toString();
    calories.value = _demoCalories.toString();
    final dataPoint = HealthDataPoint(
      timestamp: DateTime.now(),
      spO2: int.parse(spO2.value),
      heartRate: int.parse(heartRate.value),
      steps: _demoSteps,
      calories: _demoCalories,
    );
    healthDataHistory.add(dataPoint);
    String fakeRawData =
        "${spO2.value},${heartRate.value},${steps.value},${calories.value}";
    _addLogMessage(fakeRawData);
    _saveDataToFirestore(dataPoint); // Lưu dữ liệu demo (thời gian thực)
  }

  Future<void> sendCommand(String command) async {
    if (writeCharacteristic == null) {
      Get.log("Lỗi: Không tìm thấy Write Characteristic.");
      Get.snackbar("Lỗi Bluetooth", "Không thể gửi lệnh đến thiết bị (không tìm thấy characteristic).");
      return;
    }
    try {
      List<int> bytes = utf8.encode(command);
      await writeCharacteristic!.write(bytes);
      Get.log("Đã gửi lệnh: $command");
    } catch (e) {
      Get.log("Lỗi khi gửi lệnh: $e");
    }
  }

 void discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          
          // 1. Tìm Characteristic để ĐỌC DỮ LIỆU (Notify)
          if (characteristic.properties.notify) {
            targetCharacteristic = characteristic; // Gán cho biến (đã dọn dẹp)
            await characteristic.setNotifyValue(true);
            
            _dataSubscription?.cancel();
            _dataSubscription = characteristic.lastValueStream.listen((value) { // Gán cho biến (đã dọn dẹp)
              _parseHealthData(value);
            });
            Get.log("ĐÃ TÌM THẤY: Notify Characteristic");
          }

          // 2. Tìm Characteristic để GHI DỮ LIỆU (Write)
          if (characteristic.properties.write) {
            writeCharacteristic = characteristic; // Gán cho biến (đã dọn dẹp)
            Get.log("ĐÃ TÌM THẤY: Write Characteristic");
          }
        }
      }

      if(targetCharacteristic == null || writeCharacteristic == null) {
         Get.log("Lỗi: Không tìm thấy đủ characteristic (Notify/Write).");
         Get.snackbar("Lỗi thiết bị", "Thiết bị này không hỗ trợ đủ các tính năng (Notify/Write).");
      }
      
    } catch (e) {
      Get.log("Lỗi discoverServices: $e");
      Get.snackbar("Lỗi", "Không thể tìm thấy dịch vụ trên thiết bị.");
    }
  }

  void _parseHealthData(List<int> data) {
    if (data.isEmpty) return;

    String dataString = "";
    try {
      dataString = utf8.decode(data);
      _addLogMessage(dataString);

      List<String> values = dataString.split(',');

      if (values.length == 4) {
        spO2.value = values[0];
        heartRate.value = values[1];
        steps.value = values[2];
        calories.value = values[3];

        final dataPoint = HealthDataPoint(
          timestamp: DateTime.now(),
          spO2: int.tryParse(values[0]) ?? 0,
          heartRate: int.tryParse(values[1]) ?? 0,
          steps: int.tryParse(values[2]) ?? 0,
          calories: int.tryParse(values[3]) ?? 0,
        );
        healthDataHistory.add(dataPoint); 
        _saveDataToFirestore(dataPoint); 
      }
    } catch (e) {
      Get.log("Lỗi phân tích dữ liệu: $e");
      _addLogMessage("[LỖI] Không thể đọc: $dataString");
    }
  }

  Future<void> _saveDataToFirestore(HealthDataPoint dataPoint) async {
    User? user = _auth.currentUser;
    if (user == null) return; 

    try {
      _db
          .collection('users')
          .doc(user.uid)
          .collection('health_data') 
          .add({
        'timestamp': dataPoint.timestamp, 
        'spO2': dataPoint.spO2,
        'heartRate': dataPoint.heartRate,
        'steps': dataPoint.steps,
        'calories': dataPoint.calories,
      });
      
      _db.collection('users').doc(user.uid).update({
        'lastHeartRate': dataPoint.heartRate,
        'lastSpO2': dataPoint.spO2,
        'lastUpdate': dataPoint.timestamp,
      });
    } catch (e) {
      Get.log("Lỗi lưu Firestore: $e");
    }
  }

  // ==========================================================
  // SỬA LỖI: Thêm 'async' và trả về 'Future<void>'
  // ==========================================================
  Future<void> disconnectDevice({bool isSigningOut = false}) async {
    _demoTimer?.cancel();
    _dataSubscription?.cancel();
    _connectionStateSubscription?.cancel();

    if (connectedDevice.value != null &&
        connectedDevice.value!.remoteId.str != 'DEMO-ID') {
      try {
        await connectedDevice.value!.disconnect();
      } catch (e) {
        Get.log("Lỗi khi ngắt kết nối: $e");
      }
    }

    connectedDevice.value = null;
    isDemoMode.value = false;

    // Reset giá trị
    spO2.value = "--";
    heartRate.value = "--";
    steps.value = "--";
    calories.value = "--";
    healthDataHistory.clear();
    rawDataLog.clear();

    if (!isSigningOut) {
      if (Get.currentRoute != '/ConnectScreen') {
        Get.offAll(() => ConnectScreen());
      }
    }
  }
}