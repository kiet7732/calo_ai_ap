// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum để biểu diễn các trạng thái kết quả sau khi đăng nhập.
enum AuthStatus {
  successNewUser, // Đăng nhập thành công, là người dùng mới (chưa setup)
  successOldUser, // Đăng nhập thành công, là người dùng cũ (đã setup)
  error,          // Có lỗi xảy ra
}

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Xử lý logic đăng nhập bằng Google, xác thực với Firebase và kiểm tra dữ liệu người dùng.
  Future<AuthStatus> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Đăng xuất khỏi các phiên trước đó để đảm bảo hộp thoại chọn tài khoản luôn hiển thị.
      // Điều này cho phép người dùng chuyển đổi giữa các tài khoản Google.
      await _googleSignIn.signOut();
      await _auth.signOut();

      // 1. Bắt đầu quy trình đăng nhập Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Nếu người dùng hủy bỏ, trả về lỗi
      if (googleUser == null) {
        _errorMessage = "Đăng nhập Google đã bị hủy.";
        _isLoading = false;
        notifyListeners();
        return AuthStatus.error;
      }

      // 2. Lấy thông tin xác thực từ tài khoản Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Dùng thông tin xác thực để đăng nhập vào Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception("Không lấy được thông tin người dùng từ Firebase.");
      }

      // 4. QUAN TRỌNG: Kiểm tra xem người dùng đã tồn tại trong Firestore chưa
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data()?['setupComplete'] == true) {
        // Người dùng cũ, đã hoàn tất thiết lập
        return AuthStatus.successOldUser;
      } else {
        // Người dùng mới hoặc chưa hoàn tất thiết lập
        return AuthStatus.successNewUser;
      }
    } catch (e) {
      _errorMessage = "Đã xảy ra lỗi: ${e.toString()}";
      return AuthStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}