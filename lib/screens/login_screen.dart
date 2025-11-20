// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool isRegistering = false; // Chế độ Đăng nhập hay Đăng ký

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Heal Tracker", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 40),
            
            // Form Email/Pass
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Mật khẩu", prefixIcon: Icon(Icons.lock)), obscureText: true),
            const SizedBox(height: 20),

            // Nút Đăng nhập/Đăng ký
            ElevatedButton(
              onPressed: () {
                if (isRegistering) {
                  authController.registerWithEmail(emailCtrl.text, passCtrl.text, "User");
                } else {
                  authController.loginWithEmail(emailCtrl.text, passCtrl.text);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.orange
              ),
              child: Text(isRegistering ? "Đăng Ký" : "Đăng Nhập"),
            ),
            
            TextButton(
              onPressed: () => setState(() => isRegistering = !isRegistering),
              child: Text(isRegistering ? "Đã có tài khoản? Đăng nhập" : "Chưa có tài khoản? Đăng ký"),
            ),

            const Divider(height: 40, thickness: 1),
            
            // Nút Google
            OutlinedButton.icon(
              onPressed: () => authController.signInWithGoogle(),
              icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
              label: const Text("Tiếp tục với Google"),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}