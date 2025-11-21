// lib/widgets/meal_item_tile.dart

import '../models/meal.dart'; // 1. Import lớp Model
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. Import thư viện intl

class MealItemTile extends StatelessWidget {
  // 2. Chỉ cần nhận một đối tượng 'Meal'
  final Meal meal;

  const MealItemTile({
    required this.meal, // 3. Yêu cầu truyền vào 'meal'
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Định dạng thời gian để chỉ hiển thị giờ và phút (ví dụ: "07:30")
    final String formattedDate = DateFormat('yyyy-MM-dd  HH:mm').format(meal.date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 4. Sử dụng dữ liệu từ đối tượng 'meal'
          Text(meal.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formattedDate, // Sử dụng thời gian đã được định dạng
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Text(
            '${meal.calories} kcal', // 4. Sử dụng dữ liệu từ đối tượng 'meal'
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
