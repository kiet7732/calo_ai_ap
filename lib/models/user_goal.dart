// lib/models/user_goal.dart

import 'package:cloud_firestore/cloud_firestore.dart';
/// Đại diện cho document `current` trong sub-collection `goals`.
class UserGoal {
  final int calorieGoal;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;

  UserGoal({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });

  /// Factory constructor để tạo một đối tượng UserGoal từ một DocumentSnapshot của Firestore.
  factory UserGoal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError("Dữ liệu từ Firestore bị thiếu cho UserGoal!");
    }

    return UserGoal(
      calorieGoal: data['calorieGoal'] as int? ?? 2000,
      proteinGoal: data['proteinGoal'] as int? ?? 120,
      carbGoal: data['carbGoal'] as int? ?? 250,
      fatGoal: data['fatGoal'] as int? ?? 70,
    );
  }

  /// Chuyển đổi một đối tượng UserGoal thành một Map để lưu trữ trên Firestore.
  Map<String, dynamic> toJson() {
    return {
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbGoal': carbGoal,
      'fatGoal': fatGoal,
    };
  }
}