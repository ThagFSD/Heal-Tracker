// lib/controllers/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';

  // ==========================================================
  // THAY ĐỔI MỚI: Thêm một biến RxBool để Obx có thể theo dõi
  // ==========================================================
  final isDarkMode = false.obs;

  // Lấy ThemeMode từ bộ nhớ
  ThemeMode get theme {
    isDarkMode.value = _loadTheme(); // Cập nhật biến Rx khi tải
    return isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  // Hàm private để đọc từ GetStorage
  bool _loadTheme() => _box.read(_key) ?? false;

  // Lưu theme
  void _saveTheme(bool isDarkMode) {
    _box.write(_key, isDarkMode);
    this.isDarkMode.value = isDarkMode; // Cập nhật biến Rx khi lưu
  }

  // Hàm chuyển đổi theme
  void switchTheme() {
    bool newThemeState = !_loadTheme();
    Get.changeThemeMode(newThemeState ? ThemeMode.dark : ThemeMode.light);
    _saveTheme(newThemeState); // Lưu trạng thái mới
  }
}