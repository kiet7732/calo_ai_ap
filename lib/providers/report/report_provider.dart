// lib/providers/report_provider.dart
import '../../models/meal.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum để xác định khoảng thời gian báo cáo
enum TimeRange { week, month }

class ReportProvider extends ChangeNotifier {
  List<Meal> _allMeals = [];

  /// Cập nhật danh sách bữa ăn từ HistoryProvider.
  /// Hàm này được gọi bởi ChangeNotifierProxyProvider.
  void updateMeals(List<Meal> newMeals) {
    _allMeals = newMeals;
  }

  /// TÍNH TOÁN DỮ LIỆU BÁO CÁO ĐỘNG
  Map<String, dynamic> getReportData(TimeRange timeRange) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final int daysToCalculate = timeRange == TimeRange.week ? 7 : 30;

    // 1. Lọc các bữa ăn trong khoảng thời gian đã chọn
    final recentMeals = _allMeals.where((meal) {
      final mealDate = DateTime(meal.date.year, meal.date.month, meal.date.day);
      return mealDate.isAfter(
            today.subtract(Duration(days: daysToCalculate)),
          ) &&
          !mealDate.isAfter(today);
    }).toList();

    if (recentMeals.isEmpty) {
      return {
        'dailyCalories': List<double>.filled(daysToCalculate, 0),
        'labels': List<String>.generate(daysToCalculate, (i) {
          final date = today.subtract(Duration(days: daysToCalculate - 1 - i));
          return DateFormat('d/M').format(date);
        }),
        'avgCalories': 0,
        'avgProtein': 0,
        'avgCarbs': 0,
        'avgFat': 0,
        'totalProtein': 0.0,
        'totalCarbs': 0.0,
        'totalFat': 0.0,
      };
    }

    // 2. Tính toán tổng calo cho mỗi ngày
    final Map<DateTime, double> caloriesPerDay = {};
    for (var meal in recentMeals) {
      final day = DateTime(meal.date.year, meal.date.month, meal.date.day);
      caloriesPerDay.update(
        day,
        (value) => value + meal.calories,
        ifAbsent: () => meal.calories.toDouble(),
      );
    }

    // 3. Tạo danh sách calo và nhãn cho biểu đồ
    final List<double> dailyCalories = [];
    final List<String> labels = [];
    for (int i = 0; i < daysToCalculate; i++) {
      final date = today.subtract(Duration(days: daysToCalculate - 1 - i));
      dailyCalories.add(caloriesPerDay[date] ?? 0);
      labels.add(DateFormat('d/M').format(date));
    }

    // 4. Tính toán tổng và trung bình các chỉ số
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;
    recentMeals.forEach((meal) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
    });

    final numberOfDaysWithData = caloriesPerDay.keys.isNotEmpty
        ? caloriesPerDay.keys.length
        : 1;

    return {
      'dailyCalories': dailyCalories,
      'labels': labels,
      'avgCalories': (totalCalories / numberOfDaysWithData).round(),
      'avgProtein': (totalProtein / numberOfDaysWithData).round(),
      'avgCarbs': (totalCarbs / numberOfDaysWithData).round(),
      'avgFat': (totalFat / numberOfDaysWithData).round(),
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }
}
