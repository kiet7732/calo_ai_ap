import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String? routeName;
  const ErrorScreen({super.key, this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: Center(
        child: Text('Lỗi: Route "${routeName ?? 'không xác định'}" không tồn tại.'),
      ),
    );
  }
}