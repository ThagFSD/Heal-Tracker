import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        // TIẾNG ANH
        'en_US': {
          // App
          'app_title': 'Heal Tracker',
          'app_subtitle': 'Monitor your health smartly',
          // Login / Sign Up
          'create_account': 'Create Account',
          'welcome_back': 'Welcome Back',
          'signup_subtitle': 'Sign up to start your journey',
          'login_subtitle': 'Login to continue tracking',
          'full_name': 'Full Name',
          'name_required': 'Name is required',
          'email_address': 'Email Address',
          'invalid_email': 'Invalid Email',
          'password': 'Password',
          'password_min_length': 'Min 6 chars required',
          'forgot_password_feature': 'Forgot Password feature coming soon!',
          'forgot_password': 'Forgot Password?',
          'btn_signup': 'SIGN UP',
          'btn_login': 'LOGIN',
          'or_continue_with': 'OR CONTINUE WITH',
          'already_have_account': 'Already have an account?',
          'dont_have_account': "Don't have an account?",
          'login_action': 'Login',
          'signup_action': 'Sign Up',
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
          'phone_validation_required': 'Phone number is required',
          'phone_validation_invalid': 'Invalid 9-digit number',
          // AI Coach
          'ai_coach_title': 'AI Health Coach ✨',
          'ask_ai': 'Ask AI Coach',
          'analyzing': 'Analyzing your health data...',
          'ai_intro': 'Get personalized health insights based on your 7-day history.',
          'warnings': '⚠️ Warnings',
          'suggestions': '💡 Suggestions',
          'solutions': '✅ Solutions',
          'powered_by': 'Powered by Gemini AI',
          // Warning System
          'warning_title': '⚠️ HEALTH WARNING!',
          'warning_high_hr_low_spo2': 'Heart rate TOO HIGH (@hr BPM) and SpO2 LOW (@spo2%)! Stop activity immediately.',
          'warning_high_hr': 'Heart rate exceeds safe limit (@hr BPM). Please rest.',
          'warning_low_spo2': 'Blood oxygen level is low (@spo2%). Focus on breathing.',
        },
        
        // TIẾNG VIỆT
        'vi_VN': {
          // App
          'app_title': 'Heal Tracker',
          'app_subtitle': 'Theo dõi sức khỏe thông minh',
          // Login / Sign Up
          'create_account': 'Tạo Tài Khoản',
          'welcome_back': 'Chào Mừng Trở Lại',
          'signup_subtitle': 'Đăng ký để bắt đầu hành trình của bạn',
          'login_subtitle': 'Đăng nhập để tiếp tục theo dõi',
          'full_name': 'Họ và Tên',
          'name_required': 'Vui lòng nhập tên',
          'email_address': 'Địa chỉ Email',
          'invalid_email': 'Email không hợp lệ',
          'password': 'Mật khẩu',
          'password_min_length': 'Tối thiểu 6 ký tự',
          'forgot_password_feature': 'Tính năng Quên mật khẩu sắp ra mắt!',
          'forgot_password': 'Quên mật khẩu?',
          'btn_signup': 'ĐĂNG KÝ',
          'btn_login': 'ĐĂNG NHẬP',
          'or_continue_with': 'HOẶC TIẾP TỤC VỚI',
          'already_have_account': 'Đã có tài khoản?',
          'dont_have_account': 'Chưa có tài khoản?',
          'login_action': 'Đăng nhập',
          'signup_action': 'Đăng ký',
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
          'tab_dashboard': 'Trang chủ',
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
          // AI Coach
          'ai_coach_title': 'Trợ lý Sức khỏe AI ✨',
          'ask_ai': 'Hỏi Trợ lý AI',
          'analyzing': 'Đang phân tích dữ liệu sức khỏe...',
          'ai_intro': 'Nhận thông tin chi tiết về sức khỏe dựa trên lịch sử 7 ngày của bạn.',
          'warnings': '⚠️ Cảnh báo',
          'suggestions': '💡 Gợi ý',
          'solutions': '✅ Giải pháp',
          'powered_by': 'Cung cấp bởi Gemini AI',
          // Warning System
          'warning_title': '⚠️ CẢNH BÁO SỨC KHỎE!',
          'warning_high_hr_low_spo2': 'Nhịp tim QUÁ CAO (@hr BPM) và SpO2 THẤP (@spo2%)! Hãy dừng hoạt động ngay.',
          'warning_high_hr': 'Nhịp tim vượt ngưỡng an toàn (@hr BPM). Vui lòng nghỉ ngơi.',
          'warning_low_spo2': 'Nồng độ oxy trong máu thấp (@spo2%). Cần chú ý hít thở.',
        }
      };
}