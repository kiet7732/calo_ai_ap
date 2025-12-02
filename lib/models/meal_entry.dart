// lib/models/meal_entry.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

/// Đại diện cho một document trong sub-collection `current_meals`.
class MealEntry {
  final String id;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final DateTime createdAt;
  final List<FoodItem> items;

  MealEntry({
    required this.id,
    required this.mealType,
    required this.createdAt,
    required this.items,
  });

  /// Getter để tính tổng lượng calo của tất cả các món trong bữa ăn này.
  /// Nó nhân calo của mỗi món với số lượng (quantity).
  double get totalCalories => items.fold(
      0.0, (sum, currentItem) => sum + (currentItem.calories * currentItem.quantity));

  /// Chuyển đổi một DocumentSnapshot từ Firestore thành một đối tượng MealEntry.
  factory MealEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Dữ liệu từ Firestore bị thiếu cho MealEntry!");
    }

    // Chuyển đổi mảng các Map 'items' thành List<FoodItem>
    final itemsList = (data['items'] as List<dynamic>?)
            ?.map((itemMap) => FoodItem.fromMap(itemMap as Map<String, dynamic>))
            .toList() ??
        [];

    return MealEntry(
      id: doc.id,
      mealType: data['mealType'] ?? 'snack',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      items: itemsList,
    );
  }

  /// Chuyển đổi một đối tượng MealEntry thành một Map để lưu trữ trên Firestore.
  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'createdAt': Timestamp.fromDate(createdAt),
      // Chuyển đổi List<FoodItem> thành một mảng các Map
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}