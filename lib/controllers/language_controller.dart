import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final _box = GetStorage();
  final _key = 'languageCode'; // 'en' or 'vi'
  
  // Observable variable to track current language
  final currentLanguage = 'vi'.obs; 

  @override
  void onInit() {
    super.onInit();
    currentLanguage.value = _loadLanguage();
    // Ensure GetX knows the initial locale
    Get.updateLocale(getInitialLocale());
  }

  String _loadLanguage() => _box.read(_key) ?? 'vi';

  Locale getInitialLocale() {
    String langCode = _loadLanguage();
    return langCode == 'vi' 
        ? const Locale('vi', 'VN') 
        : const Locale('en', 'US');
  }

  void switchLanguage(String languageCode) {
    if (languageCode == currentLanguage.value) return;

    // 1. Update Storage & Observable
    _box.write(_key, languageCode);
    currentLanguage.value = languageCode;

    // 2. Update App Locale
    var locale = languageCode == 'vi'
        ? const Locale('vi', 'VN')
        : const Locale('en', 'US');
    
    Get.updateLocale(locale); // This triggers a full app rebuild
  }
}