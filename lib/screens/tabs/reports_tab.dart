// lib/screens/tabs/reports_tab.dart

import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../../controllers/ble_controller.dart';
import '../../models/health_data.dart';

// (Lớp DailySummary giữ nguyên)
class DailySummary {
  final DateTime date;
  final double avgHeartRate;
  final double avgSpO2;
  final int maxSteps;
  final int maxCalories;
  DailySummary({
    required this.date,
    required this.avgHeartRate,
    required this.avgSpO2,
    required this.maxSteps,
    required this.maxCalories,
  });
}

// ===========================================
// SỬA LỖI 1: Đổi tên class
// ===========================================
class ReportsTab extends StatefulWidget {
  ReportsTab({super.key});
  
  @override
  // ===========================================
  // SỬA LỖI 2: Đổi tên State
  // ===========================================
  State<ReportsTab> createState() => _ReportsTabState();

  List<DailySummary> generateDailyReports(List<HealthDataPoint> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6)); 
    final recentData =
        history.where((d) => !d.timestamp.isBefore(sevenDaysAgo)).toList();
    if (recentData.isEmpty) return [];
    Map<DateTime, List<HealthDataPoint>> groupedData = {};
    for (var data in recentData) {
      final dayKey =
          DateTime(data.timestamp.year, data.timestamp.month, data.timestamp.day);
      if (!groupedData.containsKey(dayKey)) {
        groupedData[dayKey] = [];
      }
      groupedData[dayKey]!.add(data);
    }
    List<DailySummary> summaries = [];
    groupedData.forEach((day, dataList) {
      if (dataList.isEmpty) return;
      double totalHeartRate = dataList.map((d) => d.heartRate).reduce((a, b) => a + b).toDouble();
      double totalSpO2 = dataList.map((d) => d.spO2).reduce((a, b) => a + b).toDouble();
      int maxSteps = dataList.map((d) => d.steps).reduce(max);
      int maxCalories = dataList.map((d) => d.calories).reduce(max);
      summaries.add(DailySummary(
        date: day,
        avgHeartRate: totalHeartRate / dataList.length,
        avgSpO2: totalSpO2 / dataList.length,
        maxSteps: maxSteps,
        maxCalories: maxCalories,
      ));
    });
    summaries.sort((a, b) => a.date.compareTo(b.date)); 
    return summaries;
  }
  Map<String, double> calculateOverallAverage(List<DailySummary> summaries) {
    if (summaries.isEmpty) {
      return {"avgHeart": 0.0, "avgSpO2": 0.0, "avgSteps": 0.0, "avgCalories": 0.0};
    }
    double totalHeart = 0;
    double totalSpO2 = 0;
    double totalSteps = 0;
    double totalCalories = 0;
    for (var summary in summaries) {
      totalHeart += summary.avgHeartRate;
      totalSpO2 += summary.avgSpO2;
      totalSteps += summary.maxSteps;
      totalCalories += summary.maxCalories;
    }
    return {
      "avgHeart": totalHeart / summaries.length,
      "avgSpO2": totalSpO2 / summaries.length,
      "avgSteps": totalSteps / summaries.length,
      "avgCalories": totalCalories / summaries.length,
    };
  }
}

// ===========================================
// SỬA LỖI 3: Đổi tên class State
// ===========================================
class _ReportsTabState extends State<ReportsTab> {
  final BLEController bleController = Get.find();
  int _selectedView = 0; 

  @override
  Widget build(BuildContext context) {
    return Container( 
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'reports_7_day'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                CupertinoSegmentedControl<int>(
                  children: const {
                    0: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.list_alt, size: 20)),
                    1: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.bar_chart, size: 20)),
                  },
                  onValueChanged: (int value) {
                    setState(() {
                      _selectedView = value;
                    });
                  },
                  groupValue: _selectedView,
                  selectedColor: Theme.of(context).primaryColor,
                  borderColor: Theme.of(context).primaryColor,
                  pressedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final summaries = widget.generateDailyReports(bleController.healthDataHistory);
                final overallAverage = widget.calculateOverallAverage(summaries);
    
                if (summaries.isEmpty) {
                  return Center(
                    child: Text(
                      'no_report_data'.tr,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Theme.of(context).textTheme.bodySmall?.color
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
    
                return Column(
                  children: [
                    _buildOverallSummaryCard(context, overallAverage),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _selectedView == 1
                          ? _buildChartView(context, summaries) 
                          : _buildSummaryListView(context, summaries.reversed.toList()), 
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Thẻ tóm tắt trung bình 7 ngày
  Widget _buildOverallSummaryCard(BuildContext context, Map<String, double> averages) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'avg_7_day'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor, 
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context, 
                  icon: Icons.favorite,
                  color: Colors.red,
                  label: 'avg_heart_rate'.tr,
                  value: "${averages['avgHeart']!.toStringAsFixed(1)} BPM",
                ),
                _buildSummaryItem(
                  context, 
                  icon: Icons.bloodtype,
                  color: Colors.blue,
                  label: 'avg_spo2'.tr,
                  value: "${averages['avgSpO2']!.toStringAsFixed(1)} %",
                ),
              ],
            ),
             const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context, 
                  icon: Icons.directions_walk,
                  color: Colors.green,
                  label: 'avg_steps'.tr,
                  value: averages['avgSteps']!.toStringAsFixed(0),
                ),
                _buildSummaryItem(
                  context, 
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  label: 'avg_calories'.tr,
                  value: "${averages['avgCalories']!.toStringAsFixed(0)} kcal",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// View 1: Danh sách tóm tắt (List View)
  Widget _buildSummaryListView(BuildContext context, List<DailySummary> summaries) {
    return ListView.builder(
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        return _buildReportListItem(context, summaries[index]);
      },
    );
  }

  /// View 2: Biểu đồ (Chart View)
  Widget _buildChartView(BuildContext context, List<DailySummary> summaries) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBarChartCard(
            context,
            title: 'heart_rate_bpm'.tr,
            summaries: summaries,
            getValue: (s) => s.avgHeartRate,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildBarChartCard(
            context,
            title: 'spo2_percent'.tr,
            summaries: summaries,
            getValue: (s) => s.avgSpO2,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildBarChartCard(
            context,
            title: 'steps_chart'.tr,
            summaries: summaries,
            getValue: (s) => s.maxSteps.toDouble(),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  /// Widget Card cho Báo cáo (Dạng List Item)
  Widget _buildReportListItem(BuildContext context, DailySummary summary) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(summary.date);

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor, 
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context, 
                  icon: Icons.favorite,
                  color: Colors.red,
                  label: 'avg_heart_rate'.tr,
                  value: "${summary.avgHeartRate.toStringAsFixed(1)} BPM",
                ),
                _buildSummaryItem(
                  context, 
                  icon: Icons.bloodtype,
                  color: Colors.blue,
                  label: 'avg_spo2'.tr,
                  value: "${summary.avgSpO2.toStringAsFixed(1)} %",
                ),
                _buildSummaryItem(
                  context, 
                  icon: Icons.directions_walk,
                  color: Colors.green,
                  label: 'total_steps'.tr,
                  value: summary.maxSteps.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget Item con trong Card Báo cáo
  Widget _buildSummaryItem(
    BuildContext context, { 
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final Color labelColor = Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey;

    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: labelColor), 
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Widget Card chứa Biểu đồ thanh (Bar Chart)
  Widget _buildBarChartCard(
    BuildContext context, {
    required String title,
    required List<DailySummary> summaries,
    required double Function(DailySummary) getValue,
    required Color color,
  }) {
    final Color textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: summaries.asMap().entries.map((entry) {
                    int index = entry.key;
                    DailySummary summary = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: getValue(summary),
                          color: color,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: textColor, fontSize: 12), 
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= summaries.length) {
                            return const SizedBox();
                          }
                          final day = summaries[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              DateFormat('dd/MM').format(day), 
                              style: TextStyle(color: textColor, fontSize: 10), 
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}