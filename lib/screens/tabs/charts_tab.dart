// lib/screens/tabs/charts_tab.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/ble_controller.dart';
import '../../models/health_data.dart';

class ChartsTab extends StatelessWidget {
  ChartsTab({super.key});

  final BLEController bleController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container( // Thêm container này để lấy màu nền
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Obx(() {
        final history = bleController.healthDataHistory;
        final dataPoints =
            history.length > 30 ? history.sublist(history.length - 30) : history;
    
        if (dataPoints.isEmpty) {
          return Center(
            child: Text(
              'no_chart_data'.tr,
              // ===========================================
              // SỬA LỖI: Dùng màu chữ phụ của Theme
              // ===========================================
              style: TextStyle(
                fontSize: 16, 
                color: Theme.of(context).textTheme.bodySmall?.color
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
    
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildChartCard(
                context, 
                title: 'heart_rate_bpm'.tr,
                chart: _buildHealthLineChart(
                  context, // <-- Truyền context
                  dataPoints,
                  Colors.red,
                  (data) => data.heartRate.toDouble(),
                ),
              ),
              const SizedBox(height: 20),
              _buildChartCard(
                context, 
                title: 'spo2_percent'.tr,
                chart: _buildHealthLineChart(
                  context, // <-- Truyền context
                  dataPoints,
                  Colors.blue,
                  (data) => data.spO2.toDouble(),
                ),
              ),
              const SizedBox(height: 20),
              _buildChartCard(
                context, 
                title: 'steps_chart'.tr,
                chart: _buildHealthLineChart(
                  context, // <-- Truyền context
                  dataPoints,
                  Colors.green,
                  (data) => data.steps.toDouble(),
                ),
              ),
              const SizedBox(height: 20),
              _buildChartCard(
                context, 
                title: 'calories_chart'.tr,
                chart: _buildHealthLineChart(
                  context, // <-- Truyền context
                  dataPoints,
                  Colors.orange,
                  (data) => data.calories.toDouble(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Widget Card chung cho mỗi biểu đồ
  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart}) {
    return Card(
      // ===========================================
      // THAY ĐỔI MỚI: Lấy màu thẻ từ Theme
      // ===========================================
      color: Theme.of(context).cardColor, 
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  /// Widget LineChart chung
  Widget _buildHealthLineChart(
    BuildContext context, 
    List<HealthDataPoint> dataPoints,
    Color color,
    double? Function(HealthDataPoint) getValue,
  ) {
    final spots = dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), getValue(entry.value) ?? 0.0);
    }).toList();

    // Lấy màu chữ phụ (mờ) từ Theme
    final Color textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) => FlLine(color: textColor.withOpacity(0.1), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: textColor.withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: textColor, // <-- Dùng màu theme
                  fontSize: 12,
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: textColor.withOpacity(0.2))),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: color.withAlpha((255 * 0.3).round())),
          ),
        ],
      ),
    );
  }
}