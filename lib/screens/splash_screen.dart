// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart'; // <-- IMPORT MỚI

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // ===========================================
    // SỬA LỖI "STUCK": Để SplashScreen gọi hàm kiểm tra
    // ===========================================
    _triggerAuthCheck();
  }

  void _triggerAuthCheck() {
    // Thêm 1 frame delay (rất nhỏ) để đảm bảo GetX đã sẵn sàng
    // và màn hình Splash đã được "vẽ"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AuthController>().checkAuthenticationState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        // Hiển thị logo/vòng xoay của bạn ở đây
        child: CircularProgressIndicator(), 
      ),
    );
  }
}