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
import '../providers/chat_provider.dart';
import 'firebase_options.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async { // 1. Chuyển hàm main thành async
  // 2. Đảm bảo các binding của Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();
  // 3. Khởi tạo Firebase và đợi cho đến khi hoàn tất
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Tải các biến môi trường từ file .env.local
  await dotenv.load(fileName: ".env.local");

  Gemini.init(apiKey: dotenv.env['CHAT_API_KEY']!);

  runApp(
    // 1. Dùng MultiProvider để bọc ứng dụng
    MultiProvider(
      // 2. Cung cấp một DANH SÁCH các provider
      providers: [
        ChangeNotifierProvider(create: (context) => TodayStatsProvider()),
        ChangeNotifierProvider(create: (context) => HistoryProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),

        // ProxyProvider để ReportProvider có thể "đọc" dữ liệu từ HistoryProvider
        ChangeNotifierProxyProvider<HistoryProvider, ReportProvider>(
          create: (_) => ReportProvider(),
          update: (_, history, previousReport) =>
              previousReport!..updateDailyStats(history.dailyStats),
        ),
        ChangeNotifierProvider(create: (context) => AccountSetupProvider()),
        // Thêm AuthProvider vào đây để toàn bộ ứng dụng có thể truy cập
        ChangeNotifierProvider(create: (context) => AuthProvider()),
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
