// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/profile_controller.dart';
import 'connect_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ProfileController profileController = Get.find();
  
  String? _selectedGender = 'male';
  DateTime _selectedBirthday = DateTime.now();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  // ===========================================
  // THAY ĐỔI MỚI: Thêm controller cho SĐT
  // ===========================================
  final TextEditingController _phoneController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  String _translateGender(String genderKey) {
    if (genderKey == 'male') return 'gender_male'.tr;
    if (genderKey == 'female') return 'gender_female'.tr;
    return 'gender_other'.tr;
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedBirthday = pickedDate;
      });
    });
  }

  void _saveAndProceed() {
    if (_formKey.currentState!.validate()) {
      // ===========================================
      // THAY ĐỔI MỚI: Chỉ cần gọi saveProfile
      // ===========================================
      profileController.saveProfile(
        _selectedGender!,
        _selectedBirthday,
        int.parse(_heightController.text),
        int.parse(_weightController.text),
        _phoneController.text, 
      );
      // Get.offAll(() => ConnectScreen()); // <-- XÓA DÒNG NÀY
      // AuthController sẽ tự động điều hướng
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'settings_header'.tr,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Giới tính (giữ nguyên)
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ['male', 'female', 'other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(_translateGender(value)), 
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'gender'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Sinh nhật (giữ nguyên)
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: DateFormat('dd/MM/yyyy').format(_selectedBirthday),
                ),
                decoration: InputDecoration(
                  labelText: 'birthday'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: _presentDatePicker,
              ),
              const SizedBox(height: 16),
              
              // Chiều cao (giữ nguyên)
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: 'height'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cân nặng (giữ nguyên)
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'weight'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                   if (value == null || value.isEmpty || int.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ===========================================
              // THAY ĐỔI MỚI: Thêm trường SĐT
              // ===========================================
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'relative_phone'.tr,
                  hintText: 'phone_hint'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  prefixText: "+84 ", // Mã vùng +84
                  prefixStyle: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color // Tự động đổi màu Sáng/Tối
                  ),
                ),
                keyboardType: TextInputType.phone,
                // Kiểm tra 9 số (ví dụ: 912345678)
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'phone_validation_required'.tr;
                  }
                  final RegExp phoneRegex = RegExp(r'^[3|5|7|8|9]\d{8}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'phone_validation_invalid'.tr;
                  }
                  return null;
                },
              ),
              // ===========================================

              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _saveAndProceed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('save_changes'.tr, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}