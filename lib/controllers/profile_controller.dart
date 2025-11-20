// lib/controllers/profile_controller.dart

import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart'; // <-- Bỏ GetStorage
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Dùng Firestore
import 'package:firebase_auth/firebase_auth.dart'; // <-- Dùng Firebase Auth
import 'auth_controller.dart'; // Import AuthController

class ProfileController extends GetxController {
  // Bỏ: final box = GetStorage();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // (Các biến .obs giữ nguyên)
  var gender = Rxn<String>('male');
  var birthday = Rxn<DateTime>();
  var height = 0.obs;
  var weight = 0.obs;
  var relativePhone = "".obs; 

  @override
  void onInit() {
    super.onInit();
    // Tự động tải profile khi user thay đổi (lắng nghe AuthController)
    ever(Get.find<AuthController>().firebaseUser, (User? user) {
      if (user != null) {
        loadProfile(user.uid);
      }
    });
  }

  // Tải profile từ Firestore
  Future<void> loadProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      
      gender.value = data['gender'] ?? 'male';
      if (data['birthday'] != null) {
        birthday.value = (data['birthday'] as Timestamp).toDate();
      }
      height.value = data['height'] ?? 0;
      weight.value = data['weight'] ?? 0;
      relativePhone.value = data['relativePhone'] ?? "";
    }
  }

  // Lưu profile vào Firestore
  Future<void> saveProfile(String newGender, DateTime newBirthday, int newHeight, int newWeight, String newPhone) async {
    final user = _auth.currentUser;
    if (user == null) return; // Không thể lưu nếu chưa đăng nhập

    // Dữ liệu cần lưu
    final profileData = {
      'gender': newGender,
      'birthday': Timestamp.fromDate(newBirthday), // Chuyển DateTime thành Timestamp
      'height': newHeight,
      'weight': newWeight,
      'relativePhone': newPhone,
    };

    try {
      // Dùng 'set' với 'merge: true' để cập nhật
      await _db.collection('users').doc(user.uid).set(profileData, SetOptions(merge: true));
      
      // Báo cho AuthController biết là đã hoàn thành
      Get.find<AuthController>().isProfileComplete(true);
      // Điều hướng về Home (vì profile đã xong)
      Get.offAllNamed("/home"); 

    } catch (e) {
      Get.snackbar("Lỗi lưu Profile", e.toString());
    }
  }
}