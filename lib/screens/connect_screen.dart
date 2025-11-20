// lib/screens/connect_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../controllers/ble_controller.dart';

class ConnectScreen extends StatelessWidget {
  ConnectScreen({super.key});

  final BLEController bleController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('connect_device'.tr)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              bleController.startDemoMode();
            },
            icon: const Icon(Icons.play_circle_fill),
            label: Text('run_demo'.tr),
            // ===========================================
            // SỬA LỖI Ở ĐÂY: Xóa 'style' gán cứng màu xám
            // ===========================================
            style: ElevatedButton.styleFrom(
              // backgroundColor: Colors.blueGrey[700], // <-- XÓA DÒNG NÀY
              // foregroundColor: Colors.white, // <-- XÓA DÒNG NÀY
              // Nút này bây giờ sẽ tự động lấy style màu cam từ Theme
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 10),
          Text('or'.tr, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          
          Obx(() => ElevatedButton.icon(
                onPressed: bleController.isScanning.value
                    ? null
                    : () => bleController.startScan(),
                icon: bleController.isScanning.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          // ===========================================
                          // THAY ĐỔI NHỎ: Đảm bảo vòng xoay màu trắng
                          // ===========================================
                          color: Colors.white,
                        ))
                    : const Icon(Icons.search),
                label: Text(bleController.isScanning.value ? 'scanning'.tr : 'scan_devices'.tr),
                // (Nút này không có style màu nên nó đã tự động dùng màu cam)
              )),
          const SizedBox(height: 10),
          const Divider(indent: 20, endIndent: 20), 

          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: bleController.scannedDevices.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device =
                        bleController.scannedDevices[index];
                    return ListTile(
                      title: Text(device.platformName),
                      subtitle: Text(device.remoteId.toString()),
                      leading: const Icon(Icons.bluetooth),
                      onTap: () => bleController.connectToDevice(device),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}