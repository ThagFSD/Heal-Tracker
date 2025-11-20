import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final _box = GetStorage();
  final _key = 'languageCode'; // 'en' or 'vi'
  
  // Biến .obs để Dropdown có thể theo dõi
  // Mặc định là Tiếng Việt ('vi')
  final currentLanguage = 'vi'.obs; 

  @override
  void onInit() {
    super.onInit();
    currentLanguage.value = _loadLanguage();
  }

  // Hàm private để đọc code ngôn ngữ
  String _loadLanguage() => _box.read(_key) ?? 'vi';

  // Lấy Locale ban đầu cho GetMaterialApp
  Locale getInitialLocale() {
    String langCode = _loadLanguage();
    return langCode == 'vi' 
        ? const Locale('vi', 'VN') 
        : const Locale('en', 'US');
  }

  // Hàm chuyển đổi ngôn ngữ
  void switchLanguage(String languageCode) {
    if (languageCode == currentLanguage.value) return; // Không đổi nếu giống

    // 1. Lưu code mới
    _box.write(_key, languageCode);
    currentLanguage.value = languageCode;

    // 2. Cập nhật GetX Locale
    var locale = languageCode == 'vi'
        ? const Locale('vi', 'VN')
        : const Locale('en', 'US');
    Get.updateLocale(locale);
  }
}