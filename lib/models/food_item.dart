// lib/models/food_item.dart

/// Đại diện cho một món ăn riêng lẻ với các chỉ số dinh dưỡng.
class FoodItem {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int quantity;
  final String unit;
  final String? barcode;
  final String idIcon; // Emoji hoặc tên icon

  FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.quantity = 1,
    required this.unit,
    this.barcode,
    this.idIcon = '🍲',
  });

  /// Chuyển đổi một Map (từ Firestore) thành một đối tượng FoodItem.
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] as String? ?? 'Không tên',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      unit: map['unit'] as String? ?? 'phần',
      barcode: map['barcode'] as String?,
      idIcon: map['idIcon'] as String? ?? '🍲',
    );
  }

  /// Chuyển đổi một đối tượng FoodItem thành một Map để lưu trữ trên Firestore.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'quantity': quantity,
      'unit': unit,
      'barcode': barcode,
      'idIcon': idIcon,
    };
  }
}