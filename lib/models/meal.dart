// lib/models/meal.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Factory constructor để tạo một đối tượng Meal từ một DocumentSnapshot của Firestore.
  factory Meal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Dữ liệu từ Firestore bị thiếu!");
    }

    return Meal(
      id: doc.id, // Lấy ID của document
      name: data['name'] ?? 'Không tên',
      // Chuyển đổi Timestamp của Firestore về lại DateTime của Dart
      date: (data['date'] as Timestamp).toDate(),
      calories: data['calories'] ?? 0,
      emoji: data['emoji'] ?? '❓',
      protein: data['protein'] ?? 0,
      carbs: data['carbs'] ?? 0,
      fat: data['fat'] ?? 0,
    );
  }

  /// Chuyển đổi một đối tượng Meal thành một Map để lưu trữ trên Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      // Chuyển đổi DateTime của Dart thành Timestamp của Firestore
      'date': Timestamp.fromDate(date),
      'calories': calories,
      'emoji': emoji,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}