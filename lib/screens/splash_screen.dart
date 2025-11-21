import 'dart:async';
import 'package:flutter/material.dart';
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
    // Tự động chuyển đến màn hình chính sau 2 giây
    // Timer(const Duration(seconds: 1), () {
    //   if (mounted) {
    //     Navigator.of(context).pushReplacementNamed(AppRoutes.main);
    //   }
    // });
  } 

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Calo AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}