// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enum để biểu diễn các trạng thái kết quả sau khi đăng nhập.
enum AuthStatus {
  notLoggedIn,    // Chưa đăng nhập
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
  User? get currentUser => _auth.currentUser;

  /// Hàm kiểm tra trạng thái đăng nhập hiện tại (dùng cho Splash Screen).
  Future<AuthStatus> checkLoginStatus() async {
    // Không cần set isLoading ở đây để splash screen không bị nhấp nháy
    final user = _auth.currentUser;

    if (user == null) {
      if (kDebugMode) {
        print("[AuthCheck] No user logged in.");
      }
      return AuthStatus.notLoggedIn;
    }

    try {
      //Buộc làm mới token của người dùng.
      // Nếu người dùng đã bị xóa khỏi Firebase Auth, lệnh này sẽ ném ra một exception.
      await user.reload();
      // Sau khi reload, lấy lại thông tin user mới nhất vì có thể đã bị thay đổi (thành null).
      final freshUser = _auth.currentUser;
      if (freshUser == null) {
        if (kDebugMode) {
          print("[AuthCheck] User was deleted from Firebase Auth. Navigating to login.");
        }
        // Dọn dẹp phiên đăng nhập Google cũ nếu có
        await _googleSignIn.signOut();
        return AuthStatus.notLoggedIn;
      }

      if (kDebugMode) {
        print("[AuthCheck] User ${user.uid} is logged in. Checking Firestore...");
      }
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (docSnap.exists && docSnap.data()?['setupComplete'] == true) {
        if (kDebugMode) {
          print("[AuthCheck] User is an OLD user.");
        }
        return AuthStatus.successOldUser;
      } else {
        if (kDebugMode) {
          print("[AuthCheck] User is a NEW user (or setup incomplete).");
        }
        return AuthStatus.successNewUser;
      }
    } catch (e) {
      // Bắt lỗi cụ thể khi người dùng không còn tồn tại hoặc đã bị vô hiệu hóa.
      if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'user-disabled')) {
        if (kDebugMode) {
          print("[AuthCheck] User does not exist anymore or is disabled. Error: ${e.code}");
        }
        // Dọn dẹp và đăng xuất cục bộ để đảm bảo an toàn.
        await _googleSignIn.signOut();
        await _auth.signOut();
        return AuthStatus.notLoggedIn;
      }
      _errorMessage = "Lỗi kiểm tra trạng thái: ${e.toString()}";
      if (kDebugMode) print("[AuthCheck] Error: $_errorMessage");
      return AuthStatus.error;
    }
  }

  /// Xử lý logic đăng nhập bằng Google, xác thực với Firebase và kiểm tra dữ liệu người dùng.
  Future<AuthStatus> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Đăng xuất khỏi các phiên trước đó để đảm bảo hộp thoại chọn tài khoản luôn hiển thị.
      if (kDebugMode) {
        // Chỉ thực hiện khi debug để dễ dàng chuyển đổi tài khoản
        await _googleSignIn.signOut();
        await _auth.signOut();
      }

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

      // 4. QUAN TRỌNG: Kiểm tra và tạo/cập nhật document trên Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        // TRƯỜNG HỢP 1: USER MỚI, TẠO DOCUMENT
        if (kDebugMode) {
          print("[SignIn] New user. Creating document in Firestore...");
        }
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'setupComplete': false, // Quan trọng!
        });
        return AuthStatus.successNewUser;
      }

      // TRƯỜNG HỢP 2: USER CŨ, KIỂM TRA `setupComplete`
      final data = docSnap.data();
      if (data != null && data['setupComplete'] == true) {
        if (kDebugMode) print("[SignIn] Old user with setup complete.");
        return AuthStatus.successOldUser;
      }

      // TRƯỜNG HỢP 3: USER CŨ NHƯNG CHƯA HOÀN TẤT SETUP (ví dụ: thoát app giữa chừng)
      if (kDebugMode) print("[SignIn] Old user but setup is incomplete.");
      return AuthStatus.successNewUser;
    } catch (e) {
      _errorMessage = "Đã xảy ra lỗi đăng nhập: ${e.toString()}";
      return AuthStatus.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng xuất người dùng khỏi Firebase và Google.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Đăng xuất khỏi cả Google Sign-In và Firebase Auth
      // để đảm bảo phiên đăng nhập được xóa hoàn toàn.
      await _googleSignIn.signOut();
      await _auth.signOut();
      if (kDebugMode) {
        print("[Auth] User signed out successfully.");
      }
    } catch (e) {
      _errorMessage = "Lỗi khi đăng xuất: ${e.toString()}";
      if (kDebugMode) print("[Auth] Error signing out: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Hàm trợ giúp để điều hướng dựa trên AuthStatus.
  /// Giúp tránh lặp lại code ở LoginScreen và SplashScreen.
  void navigateOnAuthStatus(BuildContext context, AuthStatus status) {
    // Dùng if (!context.mounted) return; để an toàn hơn
    if (!context.mounted) return;

    switch (status) {
      case AuthStatus.successOldUser:
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/main', (route) => false);

        final user = _auth.currentUser;
        print("Main. User ID: ${user?.uid}");
        break;
      case AuthStatus.successNewUser:
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/account-setup', (route) => false);

        final user = _auth.currentUser;
        print("Account Setup. User ID: ${user?.uid}");
        break;
      case AuthStatus.error:
        // Ở đây, có thể chọn hiển thị SnackBar hoặc điều hướng đến login
        // Điều hướng đến login là một lựa chọn an toàn mặc định.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? "Đã xảy ra lỗi. Vui lòng đăng nhập lại."),
            backgroundColor: Colors.red,
          ),
        );
        
        // SỬA: Thêm điều hướng về màn hình login khi có lỗi
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        break;
      case AuthStatus.notLoggedIn:
      default:
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}