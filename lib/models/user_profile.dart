// lib/models/user_profile.dart

// 1. Định nghĩa các Enum (Kiểu dữ liệu)
enum Gender { male, female, other }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  
  // Dữ liệu sinh trắc học
  final int height; // (cm)
  final double currentWeight; // (kg)
  final double goalWeight; // (kg)
  final DateTime dateOfBirth;
  final Gender gender;
  final ActivityLevel activityLevel;

  // Mục tiêu (Kết quả tính toán)
  final int calorieGoal;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.height,
    required this.currentWeight,
    required this.goalWeight,
    required this.dateOfBirth,
    required this.gender,
    required this.activityLevel,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });

  // 2. HÀM COPYWITH (BẮT BUỘC)
  // Hàm này cho phép bạn tạo một bản sao của UserProfile
  // nhưng thay đổi một vài giá trị (giúp code trong Provider sạch sẽ)
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? height,
    double? currentWeight,
    double? goalWeight,
    DateTime? dateOfBirth,
    Gender? gender,
    ActivityLevel? activityLevel,
    int? calorieGoal,
    int? proteinGoal,
    int? carbGoal,
    int? fatGoal,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      goalWeight: goalWeight ?? this.goalWeight,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
    );
  }
}