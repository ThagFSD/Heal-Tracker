// lib/main.dart
import 'package:firebase_core/firebase_core.dart'; // <-- SỬA: Dùng package: (dấu hai chấm)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Import TẤT CẢ các Controllers
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/ble_controller.dart';
import 'controllers/theme_controller.dart'; 
import 'controllers/language_controller.dart'; 
import 'localization/app_translations.dart'; 
import 'firebase_options.dart'; 
import 'controllers/workout_controller.dart'; 


// Import TẤT CẢ các Màn hình
import 'screens/splash_screen.dart'; // <-- IMPORT MỚI
import 'screens/onboarding_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tabs/workout_tab.dart'; 


void main() async {
  // ===========================================
  // KHỞI TẠO ĐÚNG THỨ TỰ
  // ===========================================
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  
  // 1. Khởi tạo Firebase TRƯỚC
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Khởi tạo các Controllers SAU
  // (Thứ tự này quan trọng)
  Get.put(LanguageController()); 
  Get.put(ThemeController()); 
  Get.put(AuthController()); // <-- AuthController phải được 'put'
  Get.put(BLEController());
  Get.put(ProfileController()); 
  Get.put(WorkoutController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeController themeController = Get.find();
  final LanguageController langController = Get.find();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heal Tracker',
      
      translations: AppTranslations(),
      locale: langController.getInitialLocale(), 
      fallbackLocale: const Locale('en', 'US'), 
      
      // (Theme Sáng: Giữ nguyên)
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white, 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
          brightness: Brightness.light,
        ).copyWith(
          primary: Colors.orange, 
          secondary: Colors.orangeAccent,
        ),
        buttonTheme: const ButtonThemeData(
          textTheme: ButtonTextTheme.primary
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed, // Giữ màu cam
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey, 
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
          headlineSmall: TextStyle(color: Colors.black), 
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Colors.orange,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      
      // (Theme Tối: Giữ nguyên)
      darkTheme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0f172a), 
        cardColor: const Color(0xFF1e293b), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed, // Giữ màu cam
          selectedItemColor: Colors.orange, 
          unselectedItemColor: Colors.grey, 
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
          brightness: Brightness.dark, 
        ).copyWith(
          primary: Colors.orange, 
          secondary: Colors.orangeAccent,
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
          headlineSmall: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange, 
            foregroundColor: Colors.white, 
          ),
        ),
      ),
      themeMode: themeController.theme,
      initialRoute: '/splash', 
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/connect', page: () => ConnectScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(name: '/workout', page: () => const WorkoutTab()),
      ],
    );
  }
}