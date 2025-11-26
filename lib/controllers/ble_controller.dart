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
import 'package:intl/intl.dart'; 

import '../models/health_data.dart';
import '../screens/connect_screen.dart';
import '../screens/home_screen.dart';
import 'profile_controller.dart'; 
import 'auth_controller.dart'; 

class BLEController extends GetxController {
  // ====================================================
  // 1. VARIABLES
  // ====================================================
  
  // --- BLE ---
  var scannedDevices = <BluetoothDevice>[].obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  BluetoothCharacteristic? targetCharacteristic; 
  BluetoothCharacteristic? writeCharacteristic;  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionStateSubscription;

  // --- UI STATE (Real-time updates) ---
  var spO2 = "--".obs;
  var heartRate = "--".obs;
  var steps = "--".obs;
  var calories = "--".obs;
  var activityLevel = "Nghỉ ngơi".obs; 
  var isScanning = false.obs;

  // --- FIRESTORE BUFFER (Throttled) ---
  DateTime? _lastSaveTime; 
  String _currentDayId = ""; 
  
  // Today's Raw Accumulators (For 'health_data')
  int _dailyCount = 0;
  double _dailyHrSum = 0;
  double _dailySpO2Sum = 0;
  int _dailyMaxSteps = 0;
  int _dailyMaxCalories = 0;

  // Cached History for Calculation
  List<HealthDataPoint> _cachedHistoryForAvg = [];
  
  // --- HISTORY & DEMO ---
  var healthDataHistory = <HealthDataPoint>[].obs; 
  Timer? _demoTimer;
  final Random _random = Random();
  int _demoSteps = 1234;
  int _demoCalories = 321;
  var isDemoMode = false.obs;
  var rawDataLog = <String>[].obs;
  final int maxLogSize = 50;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? _lastWarningTime; 

  // ====================================================
  // 2. INIT
  // ====================================================

  @override
  void onInit() {
    super.onInit();
    requestPermissions();

    _currentDayId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final authController = Get.find<AuthController>();
      ever(authController.firebaseUser, (User? user) {
        if (user != null) {
          _initializeData();
        }
      });
      if (authController.firebaseUser.value != null) {
        _initializeData();
      }
    } catch (e) {
      Get.log("Warning: AuthController not ready: $e");
    }
  }

  Future<void> _initializeData() async {
    // 1. Load Today's Raw Progress (to continue counting)
    await _loadTodayStatsFromFirestore(); 
    // 2. Fetch History (so we can calculate the 7-day avg)
    await _fetchRawHistoryForCalculation();
    // 3. Calculate & Save the Average immediately on startup
    await _calculateAndSavePast7DayAvg();
  }

  @override
  void onClose() {
    _forceUpdate(); 
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

  // ====================================================
  // 3. BLE LOGIC
  // ====================================================
  
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
          _forceUpdate();
          disconnectDevice();
        }
      });
      Get.offAll(() => const HomeScreen());
      discoverServices(device);
    } catch (e) {
      Get.snackbar("Lỗi", "Không thể kết nối: $e");
    }
  }

  Future<void> disconnectDevice({bool isSigningOut = false}) async {
    await _forceUpdate(); 
    _demoTimer?.cancel();
    _dataSubscription?.cancel();
    _connectionStateSubscription?.cancel();

    if (connectedDevice.value != null && connectedDevice.value!.remoteId.str != 'DEMO-ID') {
      try {
        await connectedDevice.value!.disconnect();
      } catch (e) {
        Get.log("Disconnect error: $e");
      }
    }
    connectedDevice.value = null;
    isDemoMode.value = false;
    
    spO2.value = "--";
    heartRate.value = "--";
    steps.value = "--";
    calories.value = "--";
    activityLevel.value = "Nghỉ ngơi"; 

    if (!isSigningOut && Get.currentRoute != '/ConnectScreen') {
      Get.offAll(() => ConnectScreen());
    }
  }

  void discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            targetCharacteristic = characteristic;
            await characteristic.setNotifyValue(true);
            _dataSubscription?.cancel();
            _dataSubscription = characteristic.lastValueStream.listen((value) {
              _parseHealthData(value);
            });
          }
          if (characteristic.properties.write) {
            writeCharacteristic = characteristic;
          }
        }
      }
    } catch (e) {
      Get.log("Error discoverServices: $e");
    }
  }
  
  Future<void> sendCommand(String command) async {
    if (writeCharacteristic == null) return;
    try {
      List<int> bytes = utf8.encode(command);
      await writeCharacteristic!.write(bytes);
    } catch (e) {
      Get.log("Error sending command: $e");
    }
  }

  // ====================================================
  // 4. DATA PARSING & THROTTLING
  // ====================================================

  void _parseHealthData(List<int> data) {
    if (data.isEmpty) return;
    String dataString = "";
    try {
      dataString = utf8.decode(data);
      _addLogMessage(dataString);
      List<String> values = dataString.split(',');

      if (values.length == 4) {
        int valSpO2 = int.tryParse(values[0]) ?? 0;
        int valHR = int.tryParse(values[1]) ?? 0;
        int valSteps = int.tryParse(values[2]) ?? 0;
        int valCal = int.tryParse(values[3]) ?? 0;

        // UI Updates (Immediate)
        spO2.value = values[0];
        heartRate.value = values[1];
        steps.value = values[2];
        calories.value = values[3];

        _analyzeHealthData(valHR, valSpO2);
        
        // Accumulate and Trigger Logic
        _bufferAndThrottledUpdate(valHR, valSpO2, valSteps, valCal);
      }
    } catch (e) {
      Get.log("Parse Error: $e");
    }
  }

  void _analyzeHealthData(int hr, int spo2) {
    if (hr <= 0 || spo2 <= 0) return;
    int age = 25; 
    try {
      if (Get.isRegistered<ProfileController>()) {
         age = Get.find<ProfileController>().age;
      }
    } catch (e) { /* ignore */ }
    
    int maxHeartRate = 200 - age;
    double hrPercentage = hr / maxHeartRate;
    String status = "Nghỉ ngơi";
    bool isDangerHR = false;

    if (hrPercentage >= 0.85) {
      status = "CẢNH BÁO NGUY HIỂM";
      isDangerHR = true;
    } else if (hrPercentage >= 0.70) {
      status = "Hoạt động Nặng";
    } else if (hrPercentage >= 0.50) {
      status = "Hoạt động Thường";
    }
    
    activityLevel.value = status; 
    bool isDangerSpO2 = spo2 < 95; 

    if (isDangerHR || isDangerSpO2) {
      _triggerWarning(isDangerHR, isDangerSpO2, hr, spo2);
    }
  }

  void _triggerWarning(bool hrDanger, bool spo2Danger, int hr, int spo2) {
    if (_lastWarningTime != null && 
        DateTime.now().difference(_lastWarningTime!).inSeconds < 10) return;
    _lastWarningTime = DateTime.now();

    String message = hrDanger && spo2Danger
        ? "Nhịp tim QUÁ CAO ($hr BPM) và SpO2 THẤP ($spo2%)!"
        : hrDanger ? "Nhịp tim vượt ngưỡng an toàn ($hr BPM)."
        : "Nồng độ oxy thấp ($spo2%).";

    Get.snackbar("⚠️ CẢNH BÁO SỨC KHỎE!", message,
      backgroundColor: Colors.red, colorText: Colors.white,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 35),
      duration: const Duration(seconds: 5),
    );
  }

  // ====================================================
  // 5. FIRESTORE LOGIC: 
  //    - health_data: Stores Today's Raw Data
  //    - health_data_avg: Stores Average of Past 7 Days
  // ====================================================

  void _bufferAndThrottledUpdate(int hr, int spo2, int steps, int cal) {
    final now = DateTime.now();
    final String todayString = DateFormat('yyyy-MM-dd').format(now);

    // Day Change Detection
    if (todayString != _currentDayId) {
      // Force Save Yesterday before switching
      _saveDailyRawData(dateId: _currentDayId, customDate: DateTime.parse(_currentDayId));
      
      // Reset for New Day
      _dailyCount = 0; _dailyHrSum = 0; _dailySpO2Sum = 0; 
      _dailyMaxSteps = 0; _dailyMaxCalories = 0;
      _currentDayId = todayString;
      
      // Recalculate Average (Window shifted)
      _fetchRawHistoryForCalculation().then((_) => _calculateAndSavePast7DayAvg());
    }

    // Accumulate TODAY'S raw data
    if (hr > 0 && spo2 > 0) {
      _dailyHrSum += hr;
      _dailySpO2Sum += spo2;
      _dailyCount++;
    }
    if (steps > _dailyMaxSteps) _dailyMaxSteps = steps;
    if (cal > _dailyMaxCalories) _dailyMaxCalories = cal;

    // Throttle: Every 1 Minute
    if (_lastSaveTime == null || now.difference(_lastSaveTime!).inSeconds >= 60) {
      _lastSaveTime = now;
      
      // 1. Save Today's Raw Data (to health_data)
      _saveDailyRawData(dateId: _currentDayId, customDate: now);
      
      // 2. Update/Verify the Past 7 Day Average (to health_data_avg)
      // (Even though "Past" doesn't change during the day, we update timestamp 
      //  or ensure it's synced as requested "update after 1 minute")
      _calculateAndSavePast7DayAvg(customDate: now);
    }
  }

  // --- A. Save Daily Raw Data (To 'health_data') ---
  Future<void> _saveDailyRawData({String? dateId, DateTime? customDate}) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    final DateTime saveDate = customDate ?? DateTime.now();
    final String targetId = dateId ?? DateFormat('yyyy-MM-dd').format(saveDate);

    // Calculate Today's Average for the "Raw" record
    double avgHr = _dailyCount > 0 ? _dailyHrSum / _dailyCount : 0;
    double avgSpO2 = _dailyCount > 0 ? _dailySpO2Sum / _dailyCount : 0;

    await _db.collection('users').doc(user.uid)
        .collection('health_data') // OLD Collection (Day 1 - 7 raw)
        .doc(targetId) 
        .set({
      'date': Timestamp.fromDate(saveDate),
      'heartRate': avgHr,   // Daily Average
      'spO2': avgSpO2,      // Daily Average
      'steps': _dailyMaxSteps,
      'calories': _dailyMaxCalories,
      // Internal fields to resume counting if app restarts
      '_internal_count': _dailyCount,
      '_internal_hr_sum': _dailyHrSum,
      '_internal_spo2_sum': _dailySpO2Sum,
    }, SetOptions(merge: true));
    
    Get.log("Saved Raw Data to health_data/$targetId");
  }

  // --- B. Calculate & Save Past 7-Day Avg (To 'health_data_avg') ---
  Future<void> _calculateAndSavePast7DayAvg({DateTime? customDate}) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final DateTime now = customDate ?? DateTime.now();
    final String todayId = DateFormat('yyyy-MM-dd').format(now);
    
    // 1. Filter History: Past 7 Days (Excluding Today)
    List<HealthDataPoint> pastDays = _cachedHistoryForAvg.where((d) {
      String dStr = DateFormat('yyyy-MM-dd').format(d.timestamp);
      return dStr != todayId; // Strict Exclusion
    }).toList();

    // Sort descending and take top 7
    pastDays.sort((a,b) => b.timestamp.compareTo(a.timestamp));
    if (pastDays.length > 7) {
      pastDays = pastDays.sublist(0, 7);
    }

    double sumHR = 0; double sumSpO2 = 0;
    int sumSteps = 0; int sumCal = 0;
    int count = 0;

    for (var day in pastDays) {
      sumHR += day.heartRate;
      sumSpO2 += day.spO2;
      sumSteps += day.steps;
      sumCal += day.calories;
      count++;
    }

    // Default if no history
    double avgHr = 0; double avgSpO2 = 0;
    int avgSteps = 0; int avgCal = 0;

    if (count > 0) {
      avgHr = sumHR / count;
      avgSpO2 = sumSpO2 / count;
      avgSteps = (sumSteps / count).round();
      avgCal = (sumCal / count).round();
    } 

    // 2. Save to NEW Collection: health_data_avg
    await _db.collection('users').doc(user.uid)
        .collection('health_data_avg') // NEW COLLECTION
        .doc(todayId) // Doc ID is Today (representing Avg of Past)
        .set({
      'calculatedAt': Timestamp.fromDate(now),
      'avgHeartRate': double.parse(avgHr.toStringAsFixed(1)),
      'avgSpO2': double.parse(avgSpO2.toStringAsFixed(1)),
      'avgSteps': avgSteps,
      'avgCalories': avgCal,
      'daysIncluded': count,
      'note': "Average of past 7 days (excluding today)"
    }, SetOptions(merge: true));

    Get.log("Saved Avg to health_data_avg/$todayId (Days: $count)");
  }

  Future<void> _forceUpdate() async {
    if (_currentDayId.isNotEmpty) {
      final now = DateTime.now();
      await _saveDailyRawData(dateId: _currentDayId, customDate: now);
      await _calculateAndSavePast7DayAvg(customDate: now);
    }
  }

  // --- Helpers ---

  Future<void> _loadTodayStatsFromFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    _currentDayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final doc = await _db.collection('users').doc(user.uid)
          .collection('health_data').doc(_currentDayId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _dailyHrSum = (data['_internal_hr_sum'] ?? 0).toDouble();
        _dailySpO2Sum = (data['_internal_spo2_sum'] ?? 0).toDouble();
        _dailyCount = (data['_internal_count'] ?? 0);
        _dailyMaxSteps = (data['steps'] ?? 0);
        _dailyMaxCalories = (data['calories'] ?? 0);
      }
    } catch (e) {
      Get.log("Error loading stats: $e");
    }
  }

  // Fetches raw daily data from 'health_data' to calculate avg
  Future<void> _fetchRawHistoryForCalculation() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final pastLimit = now.subtract(const Duration(days: 14)); 

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('health_data')
          .where('date', isGreaterThan: Timestamp.fromDate(pastLimit))
          .orderBy('date', descending: true)
          .get();

      List<HealthDataPoint> loaded = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        loaded.add(HealthDataPoint(
          timestamp: (data['date'] as Timestamp).toDate(),
          spO2: (data['spO2'] as num?)?.toInt() ?? 0,
          heartRate: (data['heartRate'] as num?)?.toInt() ?? 0,
          steps: data['steps'] ?? 0,
          calories: data['calories'] ?? 0,
        ));
      }
      _cachedHistoryForAvg = loaded;
      // Also update UI list (for other tabs)
      healthDataHistory.assignAll(loaded);
    } catch (e) {
      Get.log("Error fetching raw history: $e");
    }
  }

  // ====================================================
  // 6. DEMO MODE
  // ====================================================

  void startDemoMode() {
    connectedDevice.value = BluetoothDevice.fromId('DEMO-ID');
    isDemoMode.value = true;
    rawDataLog.clear();
    Get.offAll(() => const HomeScreen());
    
    _generateFakeDataForCollections(); 

    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _generateFakeBLEData();
    });
  }

  // Populates 'health_data' with past days so we can calc avg
  Future<void> _generateFakeDataForCollections() async {
    healthDataHistory.clear();
    final now = DateTime.now();
    
    // 1. Fill 'health_data' (Past 14 Days)
    for(int i=14; i>=0; i--) {
      DateTime d = now.subtract(Duration(days: i));
      String id = DateFormat('yyyy-MM-dd').format(d);
      
      int steps = 3000 + _random.nextInt(4000);
      int cal = (steps * 0.04).round();
      double hr = 70 + _random.nextInt(20).toDouble();
      
      await _db.collection('users').doc(_auth.currentUser!.uid)
          .collection('health_data')
          .doc(id).set({
        'date': Timestamp.fromDate(d),
        'heartRate': hr,
        'spO2': 98.0,
        'steps': steps,
        'calories': cal,
        '_internal_count': 100
      }, SetOptions(merge: true));
    }
    
    // 2. Refresh cache
    await _fetchRawHistoryForCalculation();
    // 3. Trigger Avg Calculation
    await _calculateAndSavePast7DayAvg();
  }

  void _generateFakeBLEData() {
    // Generate values
    bool triggerHigh = _random.nextInt(10) > 8; 
    int currentHR = triggerHigh ? 170 + _random.nextInt(20) : 65 + _random.nextInt(25);
    int currentSpO2 = triggerHigh ? 88 + _random.nextInt(5) : 95 + _random.nextInt(5);
    _demoSteps += 15;
    _demoCalories += 1;

    // Simulate Parsing
    String fakeRawString = "$currentSpO2,$currentHR,$_demoSteps,$_demoCalories";
    List<int> fakeBytes = utf8.encode(fakeRawString);
    _parseHealthData(fakeBytes); 
  }

  void _addLogMessage(String message) {
    rawDataLog.insert(0, message);
    if (rawDataLog.length > maxLogSize) {
      rawDataLog.removeRange(maxLogSize, rawDataLog.length);
    }
  }
}