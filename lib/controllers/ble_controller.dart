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
  // BLE
  var scannedDevices = <BluetoothDevice>[].obs;
  var connectedDevice = Rxn<BluetoothDevice>();
  BluetoothCharacteristic? targetCharacteristic; 
  BluetoothCharacteristic? writeCharacteristic;  
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionStateSubscription;

  // UI STATE 
  var spO2 = "--".obs;
  var heartRate = "--".obs;
  var steps = "--".obs;
  var calories = "--".obs;
  var activityLevel = "Nghỉ ngơi".obs; 
  var isScanning = false.obs;

  // FIRESTORE BUFFER 
  DateTime? _lastSaveTime; 
  String _currentDayId = ""; 
  
  // Today's Raw Accumulators (Hidden)
  int _dailyCount = 0;
  double _dailyHrSum = 0;
  double _dailySpO2Sum = 0;
  int _dailyMaxSteps = 0;
  int _dailyMaxCalories = 0;

  // Cached "Past 7 Days Avg"
  double _cachedPastAvgHR = 0;
  double _cachedPastAvgSpO2 = 0;
  int _cachedPastAvgSteps = 0;
  int _cachedPastAvgCal = 0;
  bool _isPastAvgCalculated = false;
  
  // HISTORY & DEMO 
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

  @override
  void onInit() {
    super.onInit();
    requestPermissions();

    _currentDayId = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final authController = Get.find<AuthController>();
      ever(authController.firebaseUser, (User? user) {
        if (user != null) {
          _initializeDailyData();
        }
      });
      if (authController.firebaseUser.value != null) {
        _initializeDailyData();
      }
    } catch (e) {
      Get.log("Warning: AuthController not ready: $e");
    }
  }

  Future<void> _initializeDailyData() async {
    await fetch7DayHistory();           
    await _loadTodayStatsFromFirestore(); 
    await _calculatePast7DayAverage();    
  }

  @override
  void onClose() {
    _forceSave(); 
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
  // BLE LOGIC
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
          _forceSave();
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
    await _forceSave(); 
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
  // DATA PARSING
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

        // UI Updates
        spO2.value = values[0];
        heartRate.value = values[1];
        steps.value = values[2];
        calories.value = values[3];

        _analyzeHealthData(valHR, valSpO2);
        _bufferAndThrottledSave(valHR, valSpO2, valSteps, valCal);
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

    String message = "";

    if (hrDanger && spo2Danger) {
      message = 'warning_high_hr_low_spo2'.trParams({
        'hr': hr.toString(),
        'spo2': spo2.toString()
      });
    } else if (hrDanger) {
      message = 'warning_high_hr'.trParams({
        'hr': hr.toString()
      });
    } else if (spo2Danger) {
      message = 'warning_low_spo2'.trParams({
        'spo2': spo2.toString()
      });
    }

    Get.snackbar(
      'warning_title'.tr, 
      message,
      backgroundColor: Colors.red, 
      colorText: Colors.white,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 35),
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      isDismissible: false,
    );
  }

  // ====================================================
  // FIRESTORE LOGIC
  // ====================================================

  // Calculate Avg of Strict Previous 7 Days (Excluding Today)
  Future<void> _calculatePast7DayAverage() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    final now = DateTime.now();
    // Normalize to get the start of TODAY (00:00:00)
    final DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    // Define Range
    // End: The very beginning of today (exclusive),stop at yesterday 23:59:59
    final DateTime endRange = todayMidnight; 
    
    // Start: 7 days before today (inclusive)
    final DateTime startRange = todayMidnight.subtract(const Duration(days: 7));

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('health_data')
          // Query: date >= startRange AND date < endRange
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startRange))
          .where('date', isLessThan: Timestamp.fromDate(endRange))
          .get();

      double sumHR = 0; double sumSpO2 = 0;
      int sumSteps = 0; int sumCal = 0;
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Prefer internal raw data for accuracy
        int dSteps = (data['_internal_today_max_steps'] ?? data['steps'] ?? 0);
        int dCal = (data['_internal_today_max_cal'] ?? data['calories'] ?? 0);
        double dHR = (data['avgHeartRate'] as num?)?.toDouble() ?? 0;
        double dSpO2 = (data['avgSpO2'] as num?)?.toDouble() ?? 0;

        if (dHR > 0) {
          sumHR += dHR;
          sumSpO2 += dSpO2;
          sumSteps += dSteps;
          sumCal += dCal;
          count++;
        }
      }

      if (count > 0) {
        _cachedPastAvgHR = sumHR / count;
        _cachedPastAvgSpO2 = sumSpO2 / count;
        _cachedPastAvgSteps = (sumSteps / count).round();
        _cachedPastAvgCal = (sumCal / count).round();
      } else {
        _cachedPastAvgHR = 0; _cachedPastAvgSpO2 = 0; 
        _cachedPastAvgSteps = 0; _cachedPastAvgCal = 0;
      }
      
      _isPastAvgCalculated = true;
      Get.log("Calculated Past 7 Days Avg (Excluding Today) - Range: ${DateFormat('MM/dd').format(startRange)} to ${DateFormat('MM/dd').format(endRange.subtract(const Duration(seconds: 1)))}");

    } catch (e) {
      Get.log("Error calculating past avg: $e");
    }
  }

  void _bufferAndThrottledSave(int hr, int spo2, int steps, int cal) {
    final now = DateTime.now();
    final String todayString = DateFormat('yyyy-MM-dd').format(now);

    // Day Change?
    if (todayString != _currentDayId) {
      // Force Save Yesterday
      _saveToFirestore(dateId: _currentDayId, customDate: DateTime.parse(_currentDayId));
      
      // Reset for New Day
      _dailyCount = 0; _dailyHrSum = 0; _dailySpO2Sum = 0; _dailyMaxSteps = 0; _dailyMaxCalories = 0;
      _currentDayId = todayString;
      
      // Recalculate Average since the "Past 7 Days" window shifted
      _calculatePast7DayAverage();
    }

    // Accumulate Today's RAW
    if (hr > 0 && spo2 > 0) {
      _dailyHrSum += hr;
      _dailySpO2Sum += spo2;
      _dailyCount++;
    }
    if (steps > _dailyMaxSteps) _dailyMaxSteps = steps;
    if (cal > _dailyMaxCalories) _dailyMaxCalories = cal;

    // Throttle (1 minute)
    if (_lastSaveTime == null || now.difference(_lastSaveTime!).inSeconds >= 60) {
      _saveToFirestore(dateId: _currentDayId, customDate: now);
    }
  }

  Future<void> _saveToFirestore({String? dateId, DateTime? customDate}) async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    // Force recalculation every time we save  
    // This allows the "Past 7 Days" avg to update dynamically in the background.
    if (!isDemoMode.value) {
      await _calculatePast7DayAverage();
    }

    final DateTime saveDate = customDate ?? DateTime.now();
    final String targetId = dateId ?? DateFormat('yyyy-MM-dd').format(saveDate);
    
    if (customDate == null || customDate.day == DateTime.now().day) {
      _lastSaveTime = DateTime.now();
    }

    try {
      double publicHR = _cachedPastAvgHR;
      double publicSpO2 = _cachedPastAvgSpO2;
      int publicSteps = _cachedPastAvgSteps;
      int publicCal = _cachedPastAvgCal;
      
      // repare Data for Main Collection
      Map<String, dynamic> data = {
        'date': Timestamp.fromDate(saveDate),
        // REPORT VALUES (Avg of Past 7 Days)
        'avgHeartRate': double.parse(publicHR.toStringAsFixed(1)),
        'avgSpO2': double.parse(publicSpO2.toStringAsFixed(1)),
        'steps': publicSteps, 
        'calories': publicCal,
        // RAW DATA STORAGE (Hidden)
        '_internal_today_hr_sum': _dailyHrSum,
        '_internal_today_spo2_sum': _dailySpO2Sum,
        '_internal_today_count': _dailyCount,
        '_internal_today_max_steps': _dailyMaxSteps,
        '_internal_today_max_cal': _dailyMaxCalories
      };

      // Save to EXISTING collection 'health_data'
      await _db.collection('users').doc(user.uid)
          .collection('health_data') 
          .doc(targetId) 
          .set(data, SetOptions(merge: true));

      // Save to NEW collection 'health_data_avg'
      await _db.collection('users').doc(user.uid)
          .collection('health_data_avg') 
          .doc(targetId) 
          .set({
            'date': Timestamp.fromDate(saveDate),
            'avg_7days_heart_rate': double.parse(publicHR.toStringAsFixed(1)),
            'avg_7days_spo2': double.parse(publicSpO2.toStringAsFixed(1)),
            'avg_7days_steps': publicSteps,
            'avg_7days_calories': publicCal,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (targetId == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
        _db.collection('users').doc(user.uid).update({
          'lastHeartRate': publicHR.round(),
          'lastSpO2': publicSpO2.round(),
          'lastUpdate': Timestamp.fromDate(saveDate),
        });
      }
      
      Get.log("Saved Doc $targetId to 'health_data' and 'health_data_avg'");
      
    } catch (e) {
      Get.log("Error saving: $e");
    }
  }

  Future<void> _forceSave() async {
    await _saveToFirestore(dateId: _currentDayId, customDate: DateTime.now());
  }

  Future<void> _loadTodayStatsFromFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    _currentDayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final doc = await _db.collection('users').doc(user.uid)
          .collection('health_data').doc(_currentDayId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _dailyHrSum = (data['_internal_today_hr_sum'] ?? 0).toDouble();
        _dailySpO2Sum = (data['_internal_today_spo2_sum'] ?? 0).toDouble();
        _dailyCount = (data['_internal_today_count'] ?? 0);
        _dailyMaxSteps = (data['_internal_today_max_steps'] ?? 0);
        _dailyMaxCalories = (data['_internal_today_max_cal'] ?? 0);
      }
    } catch (e) {
      Get.log("Error loading stats: $e");
    }
  }

  Future<void> fetch7DayHistory() async {
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
          .orderBy('date', descending: false)
          .get();

      List<HealthDataPoint> loadedData = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        int rawSteps = (data['_internal_today_max_steps'] ?? data['steps'] ?? 0);
        int rawCal = (data['_internal_today_max_cal'] ?? data['calories'] ?? 0);
        int displayHR = (data['avgHeartRate'] as num?)?.toInt() ?? 0;
        int displaySpO2 = (data['avgSpO2'] as num?)?.toInt() ?? 0;

        loadedData.add(HealthDataPoint(
          timestamp: (data['date'] as Timestamp).toDate(),
          spO2: displaySpO2,
          heartRate: displayHR,
          steps: rawSteps, 
          calories: rawCal,
        ));
      }
      healthDataHistory.assignAll(loadedData); 
    } catch (e) {
      Get.log("Error loading history: $e");
    }
  }

  // ====================================================
  // DEMO MODE 
  // ====================================================

  void startDemoMode() {
    connectedDevice.value = BluetoothDevice.fromId('DEMO-ID');
    isDemoMode.value = true;
    rawDataLog.clear();
    Get.offAll(() => const HomeScreen());
    
    _generateFakeStrictHistory(); 

    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _generateFakeData();
    });
  }

  Future<void> _generateFakeStrictHistory() async {
    healthDataHistory.clear();
    final now = DateTime.now();
    List<Map<String, dynamic>> rawDays = [];
    
    // Generate 14 days of random data
    for(int i=14; i>0; i--) {
      int count = 100;
      int steps = 3000 + _random.nextInt(4000); 
      int cal = (steps * 0.04).round();
      double hr = 70 + _random.nextInt(20).toDouble(); 
      
      rawDays.add({
        'date': now.subtract(Duration(days: i)),
        'steps': steps, 
        'cal': cal, 
        'hr': hr, 
        'count': count
      });
    }

    // Process and Save to Firestore
    for (int i = 0; i < 7; i++) {
      int currentIndex = 7 + i; 
      Map<String, dynamic> todayRaw = rawDays[currentIndex];
      DateTime date = todayRaw['date'];
      String dateId = DateFormat('yyyy-MM-dd').format(date);
      
      // Calculate rolling average for that specific day in the past
      double sumHR = 0; int sumSteps = 0;
      for(int k=1; k<=7; k++) {
        var prev = rawDays[currentIndex - k];
        sumHR += prev['hr'];
        sumSteps += (prev['steps'] as int);
      }
      
      double saveAvgHR = sumHR / 7;
      int saveAvgSteps = (sumSteps / 7).round();
      int saveAvgCal = (saveAvgSteps * 0.04).round();

      await _db.collection('users').doc(_auth.currentUser!.uid)
          .collection('health_data') 
          .doc(dateId) 
          .set({
        'date': Timestamp.fromDate(date),
        'avgHeartRate': double.parse(saveAvgHR.toStringAsFixed(1)),
        'avgSpO2': 98.0,
        'steps': saveAvgSteps, 
        'calories': saveAvgCal, 
        '_internal_today_max_steps': todayRaw['steps'],
        '_internal_today_max_cal': todayRaw['cal'],
        '_internal_today_hr_sum': todayRaw['hr'] * 100, 
        '_internal_today_count': 100
      }, SetOptions(merge: true));
      
      healthDataHistory.add(HealthDataPoint(
        timestamp: date,
        spO2: 98,
        heartRate: saveAvgHR.round(),
        steps: saveAvgSteps,
        calories: saveAvgCal
      ));
    }
    
    // =========================================================
    // CALCULATE REAL AVERAGE FOR DASHBOARD 
    // =========================================================
    double totalHR = 0;
    int totalSteps = 0;
    int totalCal = 0;

    for (int i = 7; i < 14; i++) {
      totalHR += rawDays[i]['hr'];
      totalSteps += (rawDays[i]['steps'] as int);
      totalCal += (rawDays[i]['cal'] as int);
    }

    _cachedPastAvgHR = totalHR / 7;
    _cachedPastAvgSteps = (totalSteps / 7).round();
    _cachedPastAvgCal = (totalCal / 7).round();
    _cachedPastAvgSpO2 = 98.0; 

    _isPastAvgCalculated = true; 
    
    _dailyCount = 0; 
    _dailyHrSum = 0; 
    _dailySpO2Sum = 0; 
    _dailyMaxSteps = 0; 
    _dailyMaxCalories = 0;
    
    Get.log("Demo Mode Started: Real Avg HR calculated as $_cachedPastAvgHR");
  }

  void _generateFakeData() {
    bool triggerHigh = _random.nextInt(10) > 8; 
    int currentHR = triggerHigh ? 170 + _random.nextInt(20) : 65 + _random.nextInt(25);
    int currentSpO2 = triggerHigh ? 88 + _random.nextInt(5) : 95 + _random.nextInt(5);
    _demoSteps += 15;
    _demoCalories += 1;

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