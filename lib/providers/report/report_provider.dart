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

    final int daysToCalculate = timeRange == TimeRange.week ? 7 : 30;
    
    // Tạo map để tra cứu nhanh: Map<DateTime, DailyStat>
    final Map<DateTime, DailyStat> statsMap = {
      for (var stat in _dailyStats) 
        DateTime(stat.date.year, stat.date.month, stat.date.day): stat
    };

    // 1. Tạo danh sách dữ liệu cho biểu đồ
    final List<double> dailyCalories = [];
    final List<String> labels = [];
    
    // Biến tính trung bình
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int dataPointsCount = 0;

    for (int i = 0; i < daysToCalculate; i++) {
      // Tính ngược từ hôm nay về quá khứ (để hiển thị đúng thứ tự trên biểu đồ thì cần reverse sau)
      // Tuy nhiên fl_chart thường vẽ từ trái qua phải (0 -> max), nên ta cần loop từ quá khứ -> hiện tại
      
      final date = today.subtract(Duration(days: daysToCalculate - 1 - i));
      final stat = statsMap[date];
      
      // Lấy dữ liệu (nếu không có thì là 0)
      final cal = stat?.totalCalories ?? 0.0;
      
      dailyCalories.add(cal);
      labels.add(DateFormat('d/M').format(date));

      // Cộng dồn để tính trung bình (chỉ tính những ngày có dữ liệu > 0 để trung bình chính xác hơn, hoặc tính cả tùy logic)
      if (stat != null) {
        totalCalories += stat.totalCalories;
        totalProtein += stat.totalProtein;
        totalCarbs += stat.totalCarbs;
        totalFat += stat.totalFat;
        dataPointsCount++;
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