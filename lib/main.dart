import '../utils/app_routes.dart';
import '../utils/route_generator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import '../providers/today_stats_provider.dart';
import '../providers/history_provider.dart';
import '../providers/auth/auth_provider.dart';
import '../providers/report/report_provider.dart';
import '../providers/account_setup_provider.dart';
import 'firebase_options.dart';
import '../services/notification_service.dart'; 
import '../providers/notification_settings_provider.dart'; 

void main() async { 
  
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // TẠO INSTANCE DUY NHẤT: Sử dụng factory constructor của Singleton
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  
  runApp(
    // 1. Dùng MultiProvider để bọc ứng dụng
    MultiProvider(
      // 2. Cung cấp một DANH SÁCH các provider
      providers: [
        // Cung cấp các service và provider không phụ thuộc
        ChangeNotifierProvider(create: (context) => TodayStatsProvider()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),
        ChangeNotifierProvider(create: (context) => AccountSetupProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        // SỬA LỖI: Cung cấp chính instance đã được khởi tạo ở trên,
        // không tạo một instance mới.
        Provider<NotificationService>.value(value: notificationService),

        // ProxyProvider để ReportProvider có thể "đọc" dữ liệu từ HistoryProvider
        ChangeNotifierProxyProvider<HistoryProvider, ReportProvider>(
          create: (_) => ReportProvider(),
          update: (_, history, previousReport) =>
              previousReport!..updateDailyStats(history.dailyStats),
        ),

        // Thêm NotificationSettingsProvider
        ChangeNotifierProxyProvider<NotificationService, NotificationSettingsProvider>(
          create: (context) => NotificationSettingsProvider(context.read<NotificationService>()),
          update: (_, notificationService, previous) => NotificationSettingsProvider(notificationService),
        ),
      ],

      // 3. Child là ứng dụng MyApp
      child: const MyApp(),
    ),
  );
}

/// Widget gốc của ứng dụng.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Tắt banner "Debug" ở góc trên bên phải
      debugShowCheckedModeBanner: false,

      // Tiêu đề của ứng dụng
      title: 'Calo AI App',

      // Cấu hình giao diện chung cho ứng dụng
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Đặt route ban đầu là Splash Screen để kiểm tra trạng thái đăng nhập
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
