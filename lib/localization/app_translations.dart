// lib/localization/app_translations.dart

import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        // TIẾNG ANH
        'en_US': {
          // App
          'app_title': 'Heal Tracker',
          // Drawer Menu
          'settings_info': 'Profile Settings',
          'switch_theme_light': 'Switch to Light Mode',
          'switch_theme_dark': 'Switch to Dark Mode',
          'change_language': 'Language',
          // Settings Screen
          'settings_title': 'Profile Info',
          'settings_header': 'Update Your Info',
          'gender': 'Gender',
          'birthday': 'Birthday',
          'height': 'Height (cm)',
          'weight': 'Weight (kg)',
          'save_changes': 'Save Changes',
          // Lựa chọn giới tính
          'gender_male': 'Male',
          'gender_female': 'Female',
          'gender_other': 'Other',
          // Ngôn ngữ
          'lang_en': 'English',
          'lang_vi': 'Vietnamese',
          // Bottom Tab Bar
          'tab_dashboard': 'Dashboard',
          'tab_charts': 'Charts',
          'tab_reports': 'Reports',
          // Connect Screen
          'connect_device': 'Connect Device',
          'run_demo': 'Run with Demo Data',
          'or': 'or',
          'scan_devices': 'Scan for Devices',
          'scanning': 'Scanning...',
          // Dashboard
          'connected_to': 'Connected to',
          'demo_mode': 'Demo Mode',
          'heart_rate': 'Heart Rate',
          'spo2': 'SpO2',
          'steps': 'Foot Steps',
          'calories': 'Calories',
          // Charts
          'real_time_charts': 'Real-time Charts',
          'heart_rate_bpm': 'Heart Rate (BPM)',
          'spo2_percent': 'SpO2 (%)',
          'steps_chart': 'Foot Steps',
          'calories_chart': 'Calories (kcal)',
          'no_chart_data': 'Not enough data to draw chart.',
          // Reports
          'reports_7_day': '7-Day Report',
          'avg_7_day': '7-Day Average',
          'avg_heart_rate': 'Avg. Heart Rate',
          'avg_spo2': 'Avg. SpO2',
          'avg_steps': 'Avg. Steps',
          'avg_calories': 'Avg. Calories',
          'no_report_data': 'Not enough data for a report.',
          'total_steps': 'Total Steps',
          'total_calories': 'Total Calories',
          // log
          'data_log': 'Data Log (Raw)',
          'log_waiting': 'Waiting for data...',
          // phonenumber
          'relative_phone': "Relative's Phone", 
          'phone_hint': 'Example: 912345678',
          'phone_validation_required': 'Phone number is required', // <-- MỚI
          'phone_validation_invalid': 'Invalid 9-digit number', // <-- MỚI
        },
        
        // TIẾNG VIỆT
        'vi_VN': {
          // App
          'app_title': 'Heal Tracker',
          // Drawer Menu
          'settings_info': 'Cài đặt Thông tin',
          'switch_theme_light': 'Chuyển sang Sáng',
          'switch_theme_dark': 'Chuyển sang Tối',
          'change_language': 'Ngôn ngữ',
          // Settings Screen
          'settings_title': 'Thông tin Cá nhân',
          'settings_header': 'Cập nhật thông tin của bạn',
          'gender': 'Giới tính',
          'birthday': 'Sinh nhật',
          'height': 'Chiều cao (cm)',
          'weight': 'Cân nặng (kg)',
          'save_changes': 'Lưu Thay đổi',
          // Lựa chọn giới tính
          'gender_male': 'Nam',
          'gender_female': 'Nữ',
          'gender_other': 'Khác',
          // Ngôn ngữ
          'lang_en': 'Tiếng Anh',
          'lang_vi': 'Tiếng Việt',
          // Bottom Tab Bar
          'tab_dashboard': 'Dashboard',
          'tab_charts': 'Biểu đồ',
          'tab_reports': 'Báo cáo',
          // Connect Screen
          'connect_device': 'Kết nối Thiết bị',
          'run_demo': 'Chạy với Dữ liệu Mẫu',
          'or': 'hoặc',
          'scan_devices': 'Quét Thiết bị',
          'scanning': 'Đang quét...',
          // Dashboard
          'connected_to': 'Đã kết nối',
          'demo_mode': 'Chế độ Demo',
          'heart_rate': 'Nhịp tim',
          'spo2': 'SpO2',
          'steps': 'Bước chân',
          'calories': 'Calories',
          // Charts
          'real_time_charts': 'Biểu đồ thời gian thực',
          'heart_rate_bpm': 'Nhịp tim (BPM)',
          'spo2_percent': 'SpO2 (%)',
          'steps_chart': 'Bước chân',
          'calories_chart': 'Calories (kcal)',
          'no_chart_data': 'Chưa có đủ dữ liệu để vẽ biểu đồ.',
          // Reports
          'reports_7_day': 'Báo cáo 7 ngày',
          'avg_7_day': 'Trung bình 7 ngày',
          'avg_heart_rate': 'TB. Nhịp tim',
          'avg_spo2': 'TB. SpO2',
          'avg_steps': 'TB. Bước',
          'avg_calories': 'TB. Calo',
          'no_report_data': 'Chưa có dữ liệu để tạo báo cáo.',
          'total_steps': 'Tổng bước',
          'total_calories': 'Tổng Calo',
           // log
          'data_log': 'Bảng ghi dữ liệu (Gốc)',
          'log_waiting': 'Đang chờ dữ liệu...',
          // phonenumber
          'relative_phone': 'SĐT Người thân', 
          'phone_hint': 'Ví dụ: 912345678', 
          'phone_validation_required': 'Vui lòng nhập số điện thoại', 
          'phone_validation_invalid': 'Số điện thoại 9 số không hợp lệ', 
        }
      };
}