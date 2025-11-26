// lib/controllers/profile_controller.dart

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var gender = Rxn<String>('male');
  var birthday = Rxn<DateTime>();
  var height = 0.obs;
  var weight = 0.obs;
  var relativePhone = "".obs;

  // [NEW] Tính tuổi tự động
  int get age {
    if (birthday.value == null) return 25; // Mặc định nếu chưa có sinh nhật
    final now = DateTime.now();
    int age = now.year - birthday.value!.year;
    if (now.month < birthday.value!.month || 
        (now.month == birthday.value!.month && now.day < birthday.value!.day)) {
      age--;
    }
    return age;
  }

  @override
  void onInit() {
    super.onInit();
    ever(Get.find<AuthController>().firebaseUser, (User? user) {
      if (user != null) {
        loadProfile(user.uid);
      }
    });
  }

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

  Future<void> saveProfile(String newGender, DateTime newBirthday, int newHeight, int newWeight, String newPhone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final profileData = {
      'gender': newGender,
      'birthday': Timestamp.fromDate(newBirthday),
      'height': newHeight,
      'weight': newWeight,
      'relativePhone': newPhone,
    };

    try {
      await _db.collection('users').doc(user.uid).set(profileData, SetOptions(merge: true));
      
      // Cập nhật giá trị local ngay lập tức để UI phản hồi
      gender.value = newGender;
      birthday.value = newBirthday;
      height.value = newHeight;
      weight.value = newWeight;
      relativePhone.value = newPhone;

      Get.find<AuthController>().isProfileComplete(true);
      Get.offAllNamed("/home"); 

    } catch (e) {
      Get.snackbar("Lỗi lưu Profile", e.toString());
    }
  }
}