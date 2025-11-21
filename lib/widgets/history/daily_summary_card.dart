//lib /widgets/history/daily_summary_card.dart
import '../../models/meal.dart';
import 'package:flutter/material.dart';

import '../macro_history_card.dart'; // do cung thu muc nen khong can widgets

class DailySummaryCard extends StatelessWidget {
  final List<Meal> dailyMeals;
  final DateTime selectedDate;

  const DailySummaryCard({
    super.key,
    required this.dailyMeals,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán tổng số liệu từ danh sách bữa ăn của ngày
    final totalCalories = dailyMeals.fold(0.0, (sum, meal) => sum + meal.calories);
    final totalProtein = dailyMeals.fold(0.0, (sum, meal) => sum + meal.protein);
    final totalCarbs = dailyMeals.fold(0.0, (sum, meal) => sum + meal.carbs);
    final totalFat = dailyMeals.fold(0.0, (sum, meal) => sum + meal.fat);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MacroHistoryItem(
            icon: Icons.local_fire_department_rounded,
            color: Colors.red,
            value: '$totalCalories kcal',
            label: 'Calo',
          ),
          MacroHistoryItem(
            icon: Icons.bolt,
            color: Colors.purple[300]!,
            value: '$totalProtein g',
            label: 'Protein',
          ),
          MacroHistoryItem(
            icon: Icons.bakery_dining_rounded,
            color: Colors.orange[400]!,
            value: '$totalCarbs g',
            label: 'Carb',
          ),
          MacroHistoryItem(
            icon: Icons.opacity_rounded,
            color: Colors.blue[300]!,
            value: '$totalFat g',
            label: 'Fat',
          ),
        ],
      ),
    );
  }
}
