import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode';
  final isDarkMode = false.obs;

  ThemeMode get theme {
    isDarkMode.value = _loadTheme();
    return isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }

  bool _loadTheme() => _box.read(_key) ?? false;

  void _saveTheme(bool isDarkMode) {
    _box.write(_key, isDarkMode);
    this.isDarkMode.value = isDarkMode; 
  }

  void switchTheme() {
    bool newThemeState = !_loadTheme();
    Get.changeThemeMode(newThemeState ? ThemeMode.dark : ThemeMode.light);
    _saveTheme(newThemeState); 
  }
}