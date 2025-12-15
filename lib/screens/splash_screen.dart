// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../utils/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dùng addPostFrameCallback để đảm bảo context đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatusAndNavigate();
    });
  }

  Future<void> _checkAuthStatusAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    final status = await authProvider.checkLoginStatus();

    if (!mounted) return;

    // Gọi hàm điều hướng chung từ AuthProvider
    authProvider.navigateOnAuthStatus(context, status);
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị một màn hình chờ đơn giản trong khi kiểm tra
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFA8D15D),
        ),
      ),
    );
  }
}
