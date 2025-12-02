// lib/models/daily_stat.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Đại diện cho một document trong sub-collection `daily_stats_meals`.
class DailyStat {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  DailyStat({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  /// Tạo một đối tượng DailyStat từ một DocumentSnapshot của Firestore.
  /// ID của document (ví dụ: "2024-07-30") sẽ được dùng để parse thành `date`.
  factory DailyStat.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Dữ liệu từ Firestore bị thiếu cho DailyStat!");
    }

    return DailyStat(
      // Chuyển đổi ID của document có định dạng "yyyy-MM-dd" thành DateTime
      date: DateFormat('yyyy-MM-dd').parse(doc.id),
      totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0.0,
      totalProtein: (data['totalProtein'] as num?)?.toDouble() ?? 0.0,
      totalCarbs: (data['totalCarbs'] as num?)?.toDouble() ?? 0.0,
      totalFat: (data['totalFat'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Chuyển đổi một đối tượng DailyStat thành một Map để lưu trữ trên Firestore.
  Map<String, dynamic> toJson() {
    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }
}