// lib/providers/today_stats_provider.dart

import 'package:flutter/material.dart';
import '../models/meal.dart'; 
import '../utils/app_helpers.dart'; 

import '../models/sample_meals.dart'; 

class TodayStatsProvider extends ChangeNotifier {
  
  // Mục tiêu (Goals)
  double _proteinGoal = 120.0;
  double _carbGoal = 250.0;
  double _fatGoal = 70.0;
  final double _calorieGoal = 2000.0;

  // Hiện tại (Current)
  double _consumed = 0.0;
  double _proteinCurrent = 0.0;
  double _carbCurrent = 0.0;
  double _fatCurrent = 0.0;

  // --- 2. Danh sách mẫu (Đã thêm DateTime) ---

  // --- 3. Getters (Sửa kiểu trả về thành double) ---
  double get proteinGoal => _proteinGoal;
  double get carbGoal => _carbGoal;
  double get fatGoal => _fatGoal;
  double get calorieGoal => _calorieGoal;

  double get consumed => _consumed;
  double get proteinCurrent => _proteinCurrent;
  double get carbCurrent => _carbCurrent;
  double get fatCurrent => _fatCurrent;

  // Getter cho danh sách (Lấy tất cả, UI sẽ tự lọc nếu cần)
  List<Meal> get recentMeals => sampleMeals;

  // --- 4. Logic (Constructor và Tính toán) ---
  TodayStatsProvider() {
    // Tính toán tổng số liệu CHỈ TRONG HÔM NAY
    _calculateTotalsForToday();
  }

  // Hàm helper để kiểm tra xem có cùng ngày không
  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
           dateA.month == dateB.month &&
           dateA.day == dateB.day;
  }

  // SỬA: Hàm này bây giờ chỉ tính tổng cho ngày hiện tại
  void _calculateTotalsForToday() {
    // Đặt lại về 0
    _consumed = 0.0;
    _proteinCurrent = 0.0;
    _carbCurrent = 0.0;
    _fatCurrent = 0.0;

    final DateTime now = DateTime.now();

    // Lọc danh sách và chỉ cộng nếu là hôm nay
    for (var meal in sampleMeals) {
      if (_isSameDay(meal.date, now)) { // CHỈ CỘNG NẾU LÀ HÔM NAY
        _consumed += meal.calories;
        _proteinCurrent += meal.protein;
        _carbCurrent += meal.carbs;
        _fatCurrent += meal.fat;
      }
    }
  }

  // Hàm để thêm món ăn mới
  void addMeal(Meal newMeal) {
    // Giả định món ăn mới luôn là "hôm nay"
    _consumed += newMeal.calories;
    _proteinCurrent += newMeal.protein;
    _carbCurrent += newMeal.carbs;
    _fatCurrent += newMeal.fat;
    
    sampleMeals.insert(0, newMeal);
    
    notifyListeners(); 
  }
}