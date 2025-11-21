//lib/widgets/meal_history_list_view.dart
import '../../models/meal.dart';
import '../../widgets/meal_item_tile.dart';
import 'package:flutter/material.dart';


// phan chia 3 cu an trong ngay: sang, trua, toi
class MealListView extends StatelessWidget {
  final List<Meal> dailyMeals;

  const MealListView({super.key, required this.dailyMeals});

  @override
  Widget build(BuildContext context) {
    if (dailyMeals.isEmpty) {
      return _buildEmptyState();
    }

    // Phân loại bữa ăn theo thời gian
    final breakfast = dailyMeals.where((m) => m.date.hour < 11).toList(); // Trước 11h
    final lunch = dailyMeals.where((m) => m.date.hour >= 11 && m.date.hour < 16).toList(); // 11h - 16h
    final dinner = dailyMeals.where((m) => m.date.hour >= 16).toList(); // Sau 16h

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (breakfast.isNotEmpty) ..._buildMealGroup('Bữa sáng', breakfast),
        if (lunch.isNotEmpty) ..._buildMealGroup('Bữa trưa', lunch),
        if (dinner.isNotEmpty) ..._buildMealGroup('Bữa tối', dinner),
      ],
    );
  }

  /// Helper để tạo một nhóm bữa ăn (ví dụ: Bữa sáng và danh sách món)
  List<Widget> _buildMealGroup(String title, List<Meal> meals) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      ...meals.map((meal) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: MealItemTile(meal: meal),
          )),
    ];
  }

  /// Widget hiển thị khi không có dữ liệu cho ngày đã chọn
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Không có dữ liệu bữa ăn',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}