// lib/models/meal.dart

class Meal {
  final String id;
  final String name;
  final DateTime date; // Ngày tháng đầy đủ (QUAN TRỌNG)
  final int calories;
  final String emoji;
  final int protein; // (Nên giữ là int, vì gram thường là số nguyên)
  final int carbs;
  final int fat;

  Meal({
    required this.id,
    required this.name,
    required this.date, // Thêm tham số này
    required this.calories,
    required this.emoji,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}