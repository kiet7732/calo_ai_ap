//lib/providers/history_provider.dart
import '../models/meal.dart';
import 'package:flutter/material.dart';

import '../models/sample_meals.dart'; 

// Lớp quản lý dữ liệu lịch sử ăn uống
class HistoryProvider extends ChangeNotifier {

  /// Cung cấp quyền truy cập vào toàn bộ danh sách bữa ăn.
  List<Meal> get allMeals => sampleMeals;

}