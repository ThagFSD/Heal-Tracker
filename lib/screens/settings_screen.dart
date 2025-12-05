import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/profile_controller.dart';
import '../controllers/language_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileController profileController = Get.find();
  final LanguageController langController = Get.find();
  
  late String? _selectedGender;
  late DateTime _selectedBirthday;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _phoneController;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedGender = profileController.gender.value ?? 'male'; 
    _selectedBirthday = profileController.birthday.value ?? DateTime.now();
    _heightController = TextEditingController(text: profileController.height.value.toString());
    _weightController = TextEditingController(text: profileController.weight.value.toString());
    _phoneController = TextEditingController(text: profileController.relativePhone.value);
  }

  String _translateGender(String genderKey) {
    if (genderKey == 'male') return 'gender_male'.tr;
    if (genderKey == 'female') return 'gender_female'.tr;
    return 'gender_other'.tr;
  }

  void _presentDatePicker() {
     showDatePicker(
      context: context,
      initialDate: _selectedBirthday,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedBirthday = pickedDate;
      });
    });
  }

void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      profileController.saveProfile(
        _selectedGender ?? 'other',
        _selectedBirthday,
        int.parse(_heightController.text),
        int.parse(_weightController.text),
        _phoneController.text, 
      );
      Get.back(); 
      Get.snackbar(
        "Đã lưu",
        "Thông tin cá nhân của bạn đã được cập nhật.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'change_language'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() => DropdownButtonFormField<String>(
                      value: langController.currentLanguage.value,
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('lang_en'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'vi',
                          child: Text('lang_vi'.tr),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          langController.switchLanguage(newValue);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'settings_header'.tr,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
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

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'relative_phone'.tr,
                          hintText: 'phone_hint'.tr,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                          prefixText: "+84 ", 
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color 
                          ),
                        ),
                        keyboardType: TextInputType.phone,
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

                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('save_changes'.tr, style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}