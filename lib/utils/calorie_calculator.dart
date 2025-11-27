// lib/utils/calorie_calculator.dart

import '../models/user_profile.dart';

/// Một lớp chứa kết quả tính toán kế hoạch calo.
class CaloriePlanResult {
  final int totalCalories;
  final int proteinGrams;
  final int carbGrams;
  final int fatGrams;
  final double dailyAdjustment; // Lượng calo tăng/giảm mỗi ngày

  CaloriePlanResult({
    required this.totalCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.dailyAdjustment,
  });
}

/// Một lớp chứa kết quả tính toán dự đoán thời gian đạt mục tiêu.
class PredictionResult {
  final int weeksToGoal;
  final DateTime targetDate;
  final double weightDifference;
  final bool isWeightLoss;

  PredictionResult({
    required this.weeksToGoal,
    required this.targetDate,
    required this.weightDifference,
    required this.isWeightLoss,
  });
}

/// Lớp tiện ích chứa các hàm tĩnh để tính toán chỉ số calo.
class CalorieCalculator {
  // Hằng số khoa học: ~7700 kcal tương đương 1kg mỡ cơ thể
  static const int _caloriesPerKg = 7700;
  
  // Giới hạn an toàn: Không nên ăn dưới 1200 kcal (nữ) hoặc 1500 kcal (nam)
  static const int _minCaloriesMale = 1500;
  static const int _minCaloriesFemale = 1200;

  /// Tính toán kế hoạch calo hàng ngày thông minh.
  static CaloriePlanResult calculatePlan({
    required Gender gender,
    required double currentWeight,
    required int height,
    required DateTime dateOfBirth,
    required ActivityLevel activityLevel,
    required double goalWeight,
  }) {
    // 1. Tính tuổi chính xác
    int age = DateTime.now().year - dateOfBirth.year;
    if (DateTime.now().month < dateOfBirth.month ||
        (DateTime.now().month == dateOfBirth.month &&
            DateTime.now().day < dateOfBirth.day)) {
      age--;
    }

    // 2. Tính BMR (Mifflin-St Jeor)
    double bmr;
    if (gender == Gender.male) {
      bmr = (10 * currentWeight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * currentWeight) + (6.25 * height) - (5 * age) - 161;
    }

    // 3. Tính TDEE (Total Daily Energy Expenditure)
    double activityMultiplier;
    switch (activityLevel) {
      case ActivityLevel.light:     activityMultiplier = 1.375; break;
      case ActivityLevel.moderate:  activityMultiplier = 1.55; break;
      case ActivityLevel.active:    activityMultiplier = 1.725; break; 
      case ActivityLevel.veryActive: activityMultiplier = 1.9; break; 
      default:                      activityMultiplier = 1.2; // Sedentary
    }
    double tdee = bmr * activityMultiplier;

    // 4. Điều chỉnh calo dựa trên mục tiêu
    // Thay đổi 0.5kg / tuần (~550 kcal/ngày)
    double dailyAdjustment = 0;
    
    if (goalWeight > currentWeight) {
      // Tăng cân: Thêm 500 kcal (tăng ~0.5kg/tuần)
      dailyAdjustment = 500;
    } else if (goalWeight < currentWeight) {
      // Giảm cân: Giảm 500 kcal (giảm ~0.5kg/tuần)
      dailyAdjustment = -500;
    }

    double targetCalories = tdee + dailyAdjustment;

    // 5. Kiểm tra AN TOÀN (Safety Floor)
    // Không bao giờ để calo thấp hơn mức tối thiểu an toàn
    int minSafeLimit = (gender == Gender.male) ? _minCaloriesMale : _minCaloriesFemale;
    
    if (targetCalories < minSafeLimit) {
      targetCalories = minSafeLimit.toDouble();
      // Tính lại mức điều chỉnh thực tế nếu bị giới hạn bởi sàn an toàn
      dailyAdjustment = targetCalories - tdee;
    }

    int totalCalories = targetCalories.round();

    // 6. Tính Macros (Tỷ lệ tối ưu: 40% Carbs, 30% Protein, 30% Fat)
    // 1g Carb = 4kcal, 1g Protein = 4kcal, 1g Fat = 9kcal
    int proteinGrams = ((totalCalories * 0.30) / 4).round();
    int carbGrams = ((totalCalories * 0.40) / 4).round();
    int fatGrams = ((totalCalories * 0.30) / 9).round();

    return CaloriePlanResult(
      totalCalories: totalCalories,
      proteinGrams: proteinGrams,
      carbGrams: carbGrams,
      fatGrams: fatGrams,
      dailyAdjustment: dailyAdjustment, // Trả về để dùng cho dự đoán
    );
  }

  /// Tính toán dự đoán thời gian chuẩn xác dựa trên mức calo thực tế.
  static PredictionResult calculatePrediction({
    required double currentWeight,
    required double goalWeight,
    required double dailyAdjustment, // Nhận tham số này từ kết quả Plan
  }) {
    final double weightDiff = (goalWeight - currentWeight).abs();
    final bool isWeightLoss = goalWeight < currentWeight;

    int weeksToGoal = 0;

    // Nếu có sự thay đổi cân nặng và mức điều chỉnh khác 0
    if (weightDiff > 0 && dailyAdjustment.abs() > 0) {
      // Công thức: Tổng calo cần giảm/tăng = Số kg chênh lệch * 7700
      double totalCaloriesNeeded = weightDiff * _caloriesPerKg;
      
      // Số ngày = Tổng calo cần / Calo thay đổi mỗi ngày
      double daysToGoal = totalCaloriesNeeded / dailyAdjustment.abs();
      
      weeksToGoal = (daysToGoal / 7).ceil();
    }

    final DateTime targetDate = DateTime.now().add(Duration(days: weeksToGoal * 7));

    return PredictionResult(
      weeksToGoal: weeksToGoal,
      targetDate: targetDate,
      weightDifference: weightDiff,
      isWeightLoss: isWeightLoss,
    );
  }
}