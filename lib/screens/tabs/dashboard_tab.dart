import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../controllers/ble_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/ai_controller.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late final AIController aiController;
  
  final BLEController bleController = Get.find();
  final ProfileController profileController = Get.find();

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AIController>()) {
      aiController = Get.find<AIController>();
    } else {
      aiController = Get.put(AIController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildQuickStatsGrid(),
          const SizedBox(height: 24),
          _buildAIAnalysisSection(context),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? "User";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hello, $name 👋",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildQuickStatsGrid() {
    return Obx(() => GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3, 
          children: [
            _buildStatCard("Heart Rate", bleController.heartRate.value, "BPM", Icons.favorite, Colors.red),
            _buildStatCard("SpO2", bleController.spO2.value, "%", Icons.water_drop, Colors.blue),
            _buildStatCard("Steps", bleController.steps.value, "steps", Icons.directions_walk, Colors.orange),
            _buildStatCard("Calories", bleController.calories.value, "kcal", Icons.local_fire_department, Colors.deepOrange),
          ],
        ));
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text("$title ($unit)", 
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("AI Health Coach ✨",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Obx(() => aiController.isLoading.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () => aiController.analyzeHealthData(),
                  ))
          ],
        ),
        const SizedBox(height: 12),
        
        Obx(() {
          if (!aiController.hasResult.value && !aiController.isLoading.value) {
            return _buildAIPlaceholder();
          }
          if (aiController.isLoading.value && !aiController.hasResult.value) {
             return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Analyzing your health data...")));
          }
          return _buildAIResultCard();
        }),
      ],
    );
  }

  Widget _buildAIPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.smart_toy_outlined, size: 40, color: Colors.blue),
          const SizedBox(height: 10),
          const Text("Get personalized health insights based on your 7-day history.", textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => aiController.analyzeHealthData(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text("Ask AI Coach"),
          )
        ],
      ),
    );
  }

  Widget _buildAIResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BMI Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text("BMI: ${aiController.bmiValue.value.toStringAsFixed(1)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(aiController.bmiCategory.value, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Divider(height: 24),

          // NEW: Weekly Report Section
          Text(aiController.weeklyReportTitle.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 8),
          _buildReportRow(Icons.favorite, "Heart Rate", aiController.heartRateAssessment.value, Colors.red),
          _buildReportRow(Icons.water_drop, "SpO2", aiController.spO2Assessment.value, Colors.blue),
          _buildReportRow(Icons.directions_walk, "Steps", aiController.stepsAssessment.value, Colors.orange),
          _buildReportRow(Icons.local_fire_department, "Calories", aiController.caloriesAssessment.value, Colors.deepOrange),
          const Divider(height: 24),

          if (aiController.warnings.isNotEmpty) ...[
            const Text("⚠️ Warnings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            ...aiController.warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(w, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          const Text("💡 Suggestions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 8),
          ...aiController.suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
          const SizedBox(height: 16),

          const Text("✅ Solutions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          ...aiController.solutions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_services_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
          
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text("Powered by Gemini AI", style: TextStyle(fontSize: 10, color: Colors.grey[400], fontStyle: FontStyle.italic)),
          )
        ],
      ),
    );
  }

  Widget _buildReportRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}