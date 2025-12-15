import '../screens/error_screen.dart';
import 'package:flutter/material.dart';
import 'app_routes.dart';

import '../screens/splash_screen.dart';
import '../screens/main_navigator_screen.dart';
import '../screens/combined_report_history_screen.dart'; 
import '../screens/food_camera_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/account_setup_screen.dart';
import '../screens/login_screen.dart'; 

/// Lớp quản lý việc tạo và điều hướng giữa các màn hình.
class RouteGenerator {
  /// Hàm tĩnh này nhận vào [RouteSettings] và trả về một [Route] tương ứng.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Bạn có thể lấy arguments được truyền vào (nếu có) bằng cách:
    // final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case AppRoutes.main:
        return MaterialPageRoute(builder: (_) => const MainNavigatorScreen());

      case AppRoutes.camera:
        return MaterialPageRoute(builder: (_) => const FoodCameraScreen());

      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());

      case AppRoutes.reports: // This route now points to the combined screen
        return MaterialPageRoute(builder: (_) => const CombinedReportHistoryScreen());

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.accountSetup:
        return MaterialPageRoute(builder: (_) => const AccountSetupScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      default:
        // Nếu route không tồn tại, điều hướng đến màn hình lỗi.
        return _errorRoute(settings.name);
    }
  }

  /// Hàm helper để tạo route cho màn hình lỗi.
  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => ErrorScreen(routeName: routeName),
    );
  }
}