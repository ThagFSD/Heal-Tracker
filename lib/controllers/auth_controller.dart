import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_controller.dart'; 
import 'ble_controller.dart'; 

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late Rx<User?> firebaseUser;
  var isProfileComplete = false.obs;

  @override
  void onInit() { 
    super.onInit();
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    
    ever(firebaseUser, (User? user) {
      if (user == null) {
        // Nếu người dùng đăng xuất, đưa về màn hình Login
        Get.offAllNamed("/login");
      }
    });
  }

  Future<void> checkAuthenticationState() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (firebaseUser.value == null) {
      Get.offAllNamed("/login");
    } else {
      await _checkUserProfile(firebaseUser.value!);
      if (isProfileComplete.value) {
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed("/onboarding");
      }
      Get.find<ProfileController>().loadProfile(firebaseUser.value!.uid);
    }
  }
  
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

  Future<void> handleLoginOrRegister(User user) async {
     await _saveUserToFirestore(user); 
     await _checkUserProfile(user); 
     if (isProfileComplete.value) {
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed("/onboarding");
      }
     Get.find<ProfileController>().loadProfile(user.uid);
  }

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
      await handleLoginOrRegister(userCredential.user!); 

    } catch (e) {
      Get.snackbar("Lỗi Đăng nhập Google", e.toString());
    }
  }

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

  Future<void> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await handleLoginOrRegister(userCredential.user!); // <-- Dùng handler mới
    } catch (e) {
      Get.snackbar("Lỗi Đăng nhập", "Email hoặc mật khẩu không đúng.");
    }
  }

  Future<void> signOut() async {
    await Get.find<BLEController>().disconnectDevice(isSigningOut: true); 
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // update info to firestore
  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    
    final doc = await userRef.get();
    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
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