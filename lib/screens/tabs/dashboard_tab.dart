// lib/screens/tabs/dashboard_tab.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ble_controller.dart';
// import '../../controllers/ai_engine_controller.dart'; // Đã gỡ bỏ

class DashboardTab extends StatelessWidget {
  DashboardTab({super.key});

  final BLEController bleController = Get.find();
  // final AIEngineController aiController = Get.find(); // Đã gỡ bỏ

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            
            Obx(() => GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDataTile(
                      context,
                      title: 'heart_rate'.tr,
                      value: "${bleController.heartRate.value} BPM",
                      icon: Icons.favorite,
                      accentColor: Colors.red.shade400,
                    ),
                    _buildDataTile(
                      context,
                      title: 'spo2'.tr,
                      value: "${bleController.spO2.value} %",
                      icon: Icons.bloodtype,
                      accentColor: Colors.blue.shade400,
                    ),
                    _buildDataTile(
                      context,
                      title: 'steps'.tr,
                      value: bleController.steps.value,
                      icon: Icons.directions_walk,
                      accentColor: Colors.green.shade400,
                    ),
                    _buildDataTile(
                      context,
                      title: 'calories'.tr,
                      value: "${bleController.calories.value} kcal",
                      icon: Icons.local_fire_department,
                      accentColor: Colors.orange.shade400,
                    ),
                  ],
                )),
            
            // ===========================================
            // THAY ĐỔI MỚI: Thêm Bảng Log
            // ===========================================
            const SizedBox(height: 20),
            _buildDataLogCard(context),

          ],
        ),
      ),
    );
  }

  /// Widget Header (Thẻ trạng thái)
  Widget _buildHeader(BuildContext context) {
    bool isDark = Get.isDarkMode;
    Color cardColor = Theme.of(context).cardColor;
    Color iconColor = isDark ? Colors.orange.shade300 : Theme.of(context).primaryColor;
    Color titleColor = isDark ? Colors.orange.shade300 : Theme.of(context).primaryColorDark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);


    String deviceName = bleController.isDemoMode.value
        ? 'demo_mode'.tr
        : bleController.connectedDevice.value?.platformName ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth_connected, color: iconColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'connected_to'.tr,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  deviceName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget ô dữ liệu (Grid Tile) - Phong cách "Tech"
  Widget _buildDataTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (Get.isDarkMode ? Colors.white : Colors.black87);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: accentColor,
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 32, color: accentColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WIDGET MỚI: Bảng Ghi Dữ liệu (Log)
  // ==========================================================
  Widget _buildDataLogCard(BuildContext context) {
    Color cardColor = Theme.of(context).cardColor;
    Color textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    Color titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      width: double.infinity,
      height: 200, // Giới hạn chiều cao của bảng log
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'data_log'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              if (bleController.rawDataLog.isEmpty) {
                return Center(
                  child: Text(
                    'log_waiting'.tr,
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                );
              }
              // ListView tự động hiển thị
              return ListView.builder(
                itemCount: bleController.rawDataLog.length,
                reverse: true, // Hiển thị log mới nhất ở dưới cùng (hoặc bỏ dòng này)
                itemBuilder: (context, index) {
                  return Text(
                    bleController.rawDataLog[index],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontFamily: 'monospace', // Dùng font monospace cho dễ đọc log
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}