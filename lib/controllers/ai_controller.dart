import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'language_controller.dart'; 

class AIController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- UI STATE ---
  var isLoading = false.obs;
  var hasResult = false.obs;
  var lastAnalysisTime = Rxn<DateTime>();

  // --- AI RESULTS ---
  var bmiValue = 0.0.obs;
  var bmiCategory = "".obs;
  var weeklyReportTitle = "".obs; 
  var heartRateAssessment = "".obs; 
  var spO2Assessment = "".obs; 
  var stepsAssessment = "".obs;
  var caloriesAssessment = "".obs;
  var suggestions = <String>[].obs;
  var warnings = <String>[].obs;
  var solutions = <String>[].obs;

  // --- API CONFIG ---
  final String apiKey = ""; 

  // ==========================================================
  // MAIN FUNCTION: ANALYZE HEALTH
  // ==========================================================
  Future<void> analyzeHealthData() async {
    User? user = _auth.currentUser;
    if (user == null) return;
    
    if (apiKey.isEmpty) {
      Get.snackbar("AI Error", "API Key is missing. Please configure it.");
      return;
    }

    isLoading.value = true;
    hasResult.value = false;

    try {
      // Fetch User Profile
      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw "User profile not found";
      final userData = userDoc.data()!;

      // Calculate Age
      int age = 25; // default 
      if (userData['birthday'] != null) {
        DateTime birth = (userData['birthday'] as Timestamp).toDate();
        age = DateTime.now().year - birth.year;
      }
      
      // Get physical stats
      int height = userData['height'] ?? 170;
      int weight = userData['weight'] ?? 65;
      String gender = userData['gender'] ?? 'unknown';

      // Fetch Latest 7-Day Avg Health Data
      final healthSnapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('health_data_avg')
          .orderBy('date', descending: true) 
          .limit(1)
          .get();

      double avgHR = 0;
      double avgSpO2 = 0;
      int avgSteps = 0;
      int avgCal = 0;

      if (healthSnapshot.docs.isNotEmpty) {
        final hData = healthSnapshot.docs.first.data();
        avgHR = (hData['avg_7days_heart_rate'] as num?)?.toDouble() ?? 0;
        avgSpO2 = (hData['avg_7days_spo2'] as num?)?.toDouble() ?? 0;
        avgSteps = (hData['avg_7days_steps'] as num?)?.toInt() ?? 0;
        avgCal = (hData['avg_7days_calories'] as num?)?.toInt() ?? 0;
      } else {
        Get.log("AI Warning: No health_data_avg found for user.");
      }

      // Get Current Language
      final LanguageController langController = Get.find();
      String languageCode = langController.currentLanguage.value;
      String languageName = languageCode == 'vi' ? 'Vietnamese' : 'English';

      // Prepare Prompt
      final prompt = """
      Act as a professional health coach. Analyze the following user data based on their 7-day average:
      - Age: $age
      - Gender: $gender
      - Height: $height cm
      - Weight: $weight kg
      - Past 7 Days Avg Heart Rate: $avgHR bpm
      - Past 7 Days Avg SpO2: $avgSpO2 %
      - Past 7 Days Avg Steps: $avgSteps steps/day
      - Past 7 Days Avg Calories Burned: $avgCal kcal/day

      Please provide the response in **$languageName**.

      Provide a response in strict JSON format (no markdown code blocks) with the following keys:
      {
        "bmi": <calculated_bmi_number>,
        "bmi_category": "<Underweight/Normal/Overweight/Obese (translated)>",
        "weekly_report_title": "<Title like 'Weekly Health Report' translated>",
        "heart_rate_assessment": "<Value> (Assessment e.g. High/Normal/Low translated)",
        "spo2_assessment": "<Value>% (Assessment translated)",
        "steps_assessment": "<Value> (Assessment translated)",
        "calories_assessment": "<Value> kcal (Assessment translated)",
        "suggestions": ["<short_suggestion_1>", "<short_suggestion_2>", ...],
        "warnings": ["<warning_if_any_otherwise_empty>", ...],
        "solutions": ["<solution_1>", "<solution_2>", ...]
      }
      If stats are 0, assume insufficient data but give general advice based on BMI/Age.
      """;

      // Call Gemini API
      final responseJson = await _callGeminiWithRetry(prompt);
      
      // Parse Results
      bmiValue.value = (responseJson['bmi'] as num).toDouble();
      bmiCategory.value = responseJson['bmi_category'] ?? "Unknown";
      weeklyReportTitle.value = responseJson['weekly_report_title'] ?? "Weekly Report";
      heartRateAssessment.value = responseJson['heart_rate_assessment'] ?? "$avgHR bpm";
      spO2Assessment.value = responseJson['spo2_assessment'] ?? "$avgSpO2 %";
      stepsAssessment.value = responseJson['steps_assessment'] ?? "$avgSteps";
      caloriesAssessment.value = responseJson['calories_assessment'] ?? "$avgCal kcal";
      
      suggestions.assignAll(List<String>.from(responseJson['suggestions'] ?? []));
      warnings.assignAll(List<String>.from(responseJson['warnings'] ?? []));
      solutions.assignAll(List<String>.from(responseJson['solutions'] ?? []));

      hasResult.value = true;
      lastAnalysisTime.value = DateTime.now();

    } catch (e) {
      Get.snackbar("AI Error", "Could not analyze data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================================
  // HELPER: API CALL WITH BACKOFF
  // ==========================================================
  Future<Map<String, dynamic>> _callGeminiWithRetry(String prompt) async {
    int retries = 0;
    const maxRetries = 5;
    const backoffDelays = [1, 2, 4, 8, 16];
    
    while (retries < maxRetries) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
        
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [{"text": prompt}]
            }],
            "generationConfig": {"responseMimeType": "application/json"}
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]['content']?['parts']?[0]['text'];
          if (text != null) {
            return jsonDecode(text);
          }
        }
        
        if (response.statusCode == 403) {
           throw "API Key Invalid or Quota Exceeded (403)";
        }
        
        throw "API Error: ${response.statusCode}";

      } catch (e) {
        if (e.toString().contains("403")) rethrow;

        retries++;
        if (retries == maxRetries) rethrow;
        
        int delaySeconds = backoffDelays[retries - 1];
        await Future.delayed(Duration(seconds: delaySeconds)); 
      }
    }
    throw "Failed to connect to AI Service";
  }
}