// core/auth/auth_controller.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends ChangeNotifier {
  User? user;
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  void listenAuth() {
    _auth.authStateChanges().listen((u) {
      user = u;
      notifyListeners();

      // Print token khi user đăng nhập thành công
      if (u != null) {
        _printToken();
      }
    });
  }

  // Print Firebase token tự động sau khi đăng nhập
  Future<void> _printToken() async {
    try {
      final token = await user?.getIdToken();
      print('=== FIREBASE TOKEN ===');
      print('Token: $token');
      print('Length: ${token?.length}');
      print('===================================');
    } catch (e) {
      print('Error getting token: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    final gUser = await _google.signIn();
    if (gUser == null) return;
    final gAuth = await gUser.authentication;
    final cred = GoogleAuthProvider.credential(
        idToken: gAuth.idToken, accessToken: gAuth.accessToken);
    await _auth.signInWithCredential(cred);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }

  bool get isLoggedIn => user != null;
  String get displayName => user?.displayName ?? 'Guest';
  String? get photoURL => user?.photoURL;

  // Lấy Firebase ID Token (nếu cần dùng ở nơi khác)
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (user == null) return null;
    try {
      return await user!.getIdToken(forceRefresh);
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  // Lấy thông tin user hiện tại
  String? get uid => user?.uid;
  String? get email => user?.email;
}
