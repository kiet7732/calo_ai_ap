// lib/screens/login_screen.dart

import '../providers/auth/auth_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_routes.dart';

/// Màn hình đăng nhập, điểm khởi đầu để người dùng xác thực vào ứng dụng.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Màu chủ đạo của ứng dụng
  static const Color primaryColor = Color(0xFFA8D15D);

  /// Xử lý logic đăng nhập Google và điều hướng.
  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signInWithGoogle();

    // Kiểm tra widget còn tồn tại trước khi thực hiện các hành động bất đồng bộ
    if (!mounted) return;

    switch (result) {
      case AuthStatus.successNewUser:
        // Điều hướng đến màn hình thiết lập tài khoản cho người dùng mới
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.accountSetup, (route) => false);
        break;
      case AuthStatus.successOldUser:
        // Điều hướng đến màn hình chính cho người dùng cũ
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        break;
      case AuthStatus.error:
        // Hiển thị SnackBar nếu có lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? "Đã có lỗi xảy ra.")),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // Giữ SafeArea để nội dung không bị che bởi notch/thanh trạng thái
        child: SingleChildScrollView( // Bọc trong SingleChildScrollView để cho phép cuộn
          child: ConstrainedBox(
            // Đảm bảo nội dung chiếm ít nhất toàn bộ chiều cao màn hình
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  _buildHeader(context),
                  const SizedBox(height: 70),
                  Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return auth.isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            )
                          : child!;
                    },
                    child: _buildGoogleSignInButton(),
                  ),
                  const SizedBox(height: 24),
                  _buildTermsText(),
                  //const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget cho phần header bao gồm logo và văn bản chào mừng.
  Widget _buildHeader(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [

        //animation
        Lottie.asset(
          'assets/animations/Intro_app.json',
          height: screenHeight * 0.3,
          repeat: true,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 24),
        const Text(
          "Chào mừng đến với Calo AI",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "Theo dõi dinh dưỡng và đạt mục tiêu sức khỏe của bạn ngay hôm nay.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Widget cho nút "Tiếp tục với Google".
  Widget _buildGoogleSignInButton() {
    return ElevatedButton.icon(
      onPressed: _handleGoogleSignIn,
      //Dùng FaIcon cho logo Google thay vì Image.asset
      icon: const FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 22),
      label: const Text(
        'Tiếp tục với Google',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  /// Widget cho văn bản điều khoản và chính sách.
  Widget _buildTermsText() {
    // Dùng RichText để có thể style hoặc thêm link sau này
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          height: 1.4,
        ),
        children: [
          const TextSpan(text: "Bằng cách tiếp tục, bạn đồng ý với\n"),
          TextSpan(
            text: "Điều khoản sử dụng",
            style: const TextStyle(
              fontWeight: FontWeight.w600, // Làm đậm để nhấn mạnh
              decoration: TextDecoration.underline,
            ),
            // recognizer: TapGestureRecognizer()..onTap = () { /* Mở link điều khoản */ },
          ),
          const TextSpan(text: " & "),
          TextSpan(
            text: "Chính sách bảo mật.",
            style: const TextStyle(
              fontWeight: FontWeight.w600, // Làm đậm để nhấn mạnh
              decoration: TextDecoration.underline,
            ),
            // recognizer: TapGestureRecognizer()..onTap = () { /* Mở link chính sách */ },
          ),
        ],
      ),
    );
  }
}
