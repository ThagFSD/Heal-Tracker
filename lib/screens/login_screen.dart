import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/language_controller.dart'; // Import LanguageController
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController authController = Get.find();
  final LanguageController langController = Get.put(LanguageController()); // Inject LanguageController
  
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController(); 
  
  final _formKey = GlobalKey<FormState>();
  bool isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9800), 
              Color(0xFFFFE0B2), 
            ],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topPadding + 60, 24, 24),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),

                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                isRegistering ? 'create_account'.tr : 'welcome_back'.tr,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isRegistering ? 'signup_subtitle'.tr : 'login_subtitle'.tr,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),

                              if (isRegistering) ...[
                                CustomTextField(
                                  controller: nameCtrl,
                                  labelText: 'full_name'.tr,
                                  icon: Icons.person,
                                  validator: (val) => val!.isEmpty ? 'name_required'.tr : null,
                                ),
                                const SizedBox(height: 16),
                              ],

                              CustomTextField(
                                controller: emailCtrl,
                                labelText: 'email_address'.tr,
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) => !GetUtils.isEmail(val!) ? 'invalid_email'.tr : null,
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: passCtrl,
                                labelText: 'password'.tr,
                                icon: Icons.lock,
                                obscureText: true,
                                validator: (val) => val!.length < 6 ? 'password_min_length'.tr : null,
                              ),
                              
                              if (!isRegistering) 
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Get.snackbar("Info", 'forgot_password_feature'.tr);
                                    },
                                    child: Text('forgot_password'.tr, style: const TextStyle(color: Colors.orange)),
                                  ),
                                )
                              else
                                const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                                child: Text(
                                  isRegistering ? 'btn_signup'.tr : 'btn_login'.tr,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    Row(children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.8), thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or_continue_with'.tr, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.8), thickness: 1)),
                    ]),
                    const SizedBox(height: 24),

                    _buildSocialButton(
                      label: "Google",
                      icon: Icons.g_mobiledata, 
                      color: Colors.white,
                      textColor: Colors.black87,
                      onTap: () => authController.signInWithGoogle(),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isRegistering ? 'already_have_account'.tr : 'dont_have_account'.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isRegistering = !isRegistering;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            isRegistering ? 'login_action'.tr : 'signup_action'.tr,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            // Language Switcher Positioned Top Right
            Positioned(
              top: topPadding + 10,
              right: 20,
              child: _buildLanguageSwitcher(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: langController.currentLanguage.value,
          icon: const Icon(Icons.language, color: Colors.white),
          dropdownColor: Colors.orange[400],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          onChanged: (String? newValue) {
            if (newValue != null) {
              langController.switchLanguage(newValue);
            }
          },
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
          ],
        ),
      ),
    ));
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
        const SizedBox(height: 10),
        Text(
          'app_title'.tr,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)]
          ),
        ),
        Text(
          'app_subtitle'.tr,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label, 
    required IconData icon, 
    required Color color, 
    required Color textColor,
    required VoidCallback onTap
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.red, size: 32),
        label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (isRegistering) {
        authController.registerWithEmail(emailCtrl.text.trim(), passCtrl.text.trim(), nameCtrl.text.trim());
      } else {
        authController.loginWithEmail(emailCtrl.text.trim(), passCtrl.text.trim());
      }
    }
  }
}