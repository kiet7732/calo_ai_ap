import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/daily_stat.dart'; // Import model DailyStat

// Enum để xác định khoảng thời gian báo cáo
enum TimeRange { week, month }

class ReportProvider extends ChangeNotifier {
  //lưu trữ danh sách DailyStat thay vì Meal
  List<DailyStat> _dailyStats = [];

  /// Cập nhật danh sách thống kê ngày từ HistoryProvider.
  /// Hàm này được gọi bởi ChangeNotifierProxyProvider trong main.dart.
  void updateDailyStats(List<DailyStat> newStats) {
    _dailyStats = newStats;
    notifyListeners();
  }

  /// TÍNH TOÁN DỮ LIỆU BÁO CÁO ĐỘNG (TỪ DAILY STATS)
  Map<String, dynamic> getReportData(TimeRange timeRange) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Tạo map để tra cứu nhanh: Map<DateTime, DailyStat>
    final Map<DateTime, DailyStat> statsMap = {
      for (var stat in _dailyStats) DateTime(stat.date.year, stat.date.month, stat.date.day): stat
    };

    // 1. Tạo danh sách dữ liệu cho biểu đồ
    final List<double> dailyCalories = [];
    final List<String> labels = [];

    // Biến tổng để tính trung bình
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int dataPointsCount = 0;

    if (timeRange == TimeRange.week) {
      // Tuần hiện tại: từ Monday -> Sunday (không trộn sang tuần khác)
      // DateTime.weekday: Monday=1 .. Sunday=7
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
     
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final stat = statsMap[date];
        final cal = stat?.totalCalories ?? 0.0;
        dailyCalories.add(cal);
        labels.add(DateFormat('EEE').format(date)); // Mon, Tue, ...

        if (stat != null) {
          totalCalories += stat.totalCalories;
          totalProtein += stat.totalProtein;
          totalCarbs += stat.totalCarbs;
          totalFat += stat.totalFat;
          dataPointsCount++;
        }
      }
    } else {
      // Tháng hiện tại: hiển thị 1..31 (không lẫn dữ liệu tháng khác)
      final year = today.year;
      final month = today.month;
 
      for (int day = 1; day <= 31; day++) {
        final date = DateTime(year, month, day);
        // Nếu DateTime rolled over to next month, treat as missing (0)
        if (date.month != month) {
          dailyCalories.add(0.0);
          labels.add(day.toString());
          continue;
        }

        final stat = statsMap[date];
        final cal = stat?.totalCalories ?? 0.0;
        dailyCalories.add(cal);
        labels.add(day.toString());

        if (stat != null) {
          totalCalories += stat.totalCalories;
          totalProtein += stat.totalProtein;
          totalCarbs += stat.totalCarbs;
          totalFat += stat.totalFat;
          dataPointsCount++;
        }
      }
    }
    
    // Tránh chia cho 0
    final divider = dataPointsCount == 0 ? 1 : dataPointsCount;

    // 2. Tính tỉ lệ phần trăm cho PieChart (Dựa trên tổng lượng macro trong quãng thời gian)
    final macroTotal = totalProtein + totalCarbs + totalFat;
    
    // Trả về dữ liệu đã xử lý
    return {
      'dailyCalories': dailyCalories,
      'labels': labels,
      
      // Số liệu trung bình
      'avgCalories': (totalCalories / divider).round(),
      'avgProtein': (totalProtein / divider).round(),
      'avgCarbs': (totalCarbs / divider).round(),
      'avgFat': (totalFat / divider).round(),
      
      // Tổng lượng Macros (để vẽ PieChart)
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }
}