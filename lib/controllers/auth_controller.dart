// lib/controllers/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import các tệp cần thiết
import 'profile_controller.dart'; 
import 'ble_controller.dart'; 
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';


class AuthController extends GetxController {
  static AuthController instance = Get.find();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late Rx<User?> firebaseUser;
  var isProfileComplete = false.obs;

  @override
  void onInit() { // Dùng onInit
    super.onInit();
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    
    // ===========================================
    // SỬA LỖI "STUCK": Xóa HẾT logic điều hướng
    //
    // 'ever(firebaseUser, _setInitialScreen);' <-- ĐÃ XÓA
    //
    // Chúng ta sẽ để SplashScreen tự quyết định
    // Chúng ta chỉ giữ 'ever' để xử lý ĐĂNG XUẤT
    // ===========================================
    ever(firebaseUser, (User? user) {
      if (user == null) {
        // Nếu người dùng đăng xuất, đưa về màn hình Login
        Get.offAllNamed("/login");
      }
    });
  }

  // ===========================================
  // HÀM MỚI: Chỉ kiểm tra và điều hướng (dùng 1 lần)
  // (Hàm này sẽ được SplashScreen gọi)
  // ===========================================
  Future<void> checkAuthenticationState() async {
    // Thêm 1 giây delay để logo kịp hiển thị (trải nghiệm người dùng)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (firebaseUser.value == null) {
      // Nếu chưa đăng nhập
      Get.offAllNamed("/login");
    } else {
      // Nếu đã đăng nhập, kiểm tra profile
      await _checkUserProfile(firebaseUser.value!);
      if (isProfileComplete.value) {
        // Profile đầy đủ -> Vào app
        Get.offAllNamed("/home");
      } else {
        // Profile thiếu -> Tới màn hình Onboarding
        Get.offAllNamed("/onboarding");
      }
      // Tải dữ liệu Profile Controller
      Get.find<ProfileController>().loadProfile(firebaseUser.value!.uid);
    }
  }
  
  // (Hàm _setInitialScreen cũ đã bị xóa)

  Future<void> _checkUserProfile(User user) async {
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && (doc.data()!['height'] ?? 0) > 0) {
        isProfileComplete(true);
      } else {
        isProfileComplete(false);
      }
    } catch (e) {
      isProfileComplete(false);
    }
  }

  // ===========================================
  // HÀM MỚI: Xử lý logic sau khi Đăng nhập/Đăng ký
  // ===========================================
  Future<void> handleLoginOrRegister(User user) async {
     await _saveUserToFirestore(user); // Đảm bảo tài liệu user tồn tại
     await _checkUserProfile(user); // Kiểm tra profile
     if (isProfileComplete.value) {
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed("/onboarding");
      }
     Get.find<ProfileController>().loadProfile(user.uid);
  }

  // 1. Đăng nhập bằng Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await handleLoginOrRegister(userCredential.user!); // <-- Dùng handler mới

    } catch (e) {
      Get.snackbar("Lỗi Đăng nhập Google", e.toString());
    }
  }

  // 2. Đăng ký bằng Email/Password
  Future<void> registerWithEmail(String email, String password, String name) async {
    if(name.isEmpty) {
      Get.snackbar("Lỗi Đăng ký", "Vui lòng nhập tên của bạn");
      return;
    }
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      await userCredential.user!.updateDisplayName(name);
      await handleLoginOrRegister(userCredential.user!); // <-- Dùng handler mới
    } catch (e) {
      Get.snackbar("Lỗi Đăng ký", "Email đã được sử dụng hoặc mật khẩu quá yếu.");
    }
  }

  // 3. Đăng nhập bằng Email/Password
  Future<void> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await handleLoginOrRegister(userCredential.user!); // <-- Dùng handler mới
    } catch (e) {
      Get.snackbar("Lỗi Đăng nhập", "Email hoặc mật khẩu không đúng.");
    }
  }

  // 4. Đăng xuất
  Future<void> signOut() async {
    await Get.find<BLEController>().disconnectDevice(isSigningOut: true); 
    await _googleSignIn.signOut();
    await _auth.signOut();
    // 'ever' listener (trong onInit) sẽ tự động xử lý và điều hướng về /login
  }

  // HÀM QUAN TRỌNG: Lưu/Cập nhật thông tin user vào Firestore
  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    
    final doc = await userRef.get();
    if (!doc.exists) {
      // Nếu là user mới, tạo bản ghi mặc định
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        // Các chỉ số mặc định
        'height': 0,
        'weight': 0,
        'gender': 'male',
        'birthday': null,
        'relativePhone': '',
      });
      isProfileComplete(false);
    }
  }
}