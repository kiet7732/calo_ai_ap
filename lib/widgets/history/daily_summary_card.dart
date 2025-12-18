//lib /widgets/history/daily_summary_card.dart
import '../../models/daily_stat.dart';
import 'package:flutter/material.dart';

import '../macro_history_card.dart'; // do cung thu muc nen khong can widgets

class DailySummaryCard extends StatelessWidget {
  //Nhận một đối tượng DailyStat thay vì List<Meal>
  final DailyStat dailyStat;

  const DailySummaryCard({
    super.key,
    required this.dailyStat,
  });

  @override
  Widget build(BuildContext context) {
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
            value: '${dailyStat.totalCalories.toStringAsFixed(0)} kcal',
            label: 'Calo',
          ),
          MacroHistoryItem(
            icon: Icons.bolt,
            color: Colors.purple[300]!,
            value: '${dailyStat.totalProtein.toStringAsFixed(0)} g',
            label: 'Protein',
          ),
          MacroHistoryItem(
            icon: Icons.bakery_dining_rounded,
            color: Colors.orange[400]!,
            value: '${dailyStat.totalCarbs.toStringAsFixed(0)} g',
            label: 'Carb',
          ),
          MacroHistoryItem(
            icon: Icons.opacity_rounded,
            color: Colors.blue[300]!,
            value: '${dailyStat.totalFat.toStringAsFixed(0)} g',
            label: 'Fat',
          ),
        ],
      ),
    );
  }
}
