// lib/models/meal_analysis_result.dart

/// Lưu trữ thông tin dinh dưỡng cho một thành phần đơn lẻ.
class NutritionInfo {
  final String? foodName; 
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionInfo({
    this.foodName,
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
  });

  // Hàm tạo một instance rỗng/mặc định
  factory NutritionInfo.empty() => NutritionInfo();

  // Cộng hai đối tượng NutritionInfo
  NutritionInfo operator +(NutritionInfo other) {
    return NutritionInfo(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
    );
  }
}

/// Kết hợp truy vấn gốc và thông tin dinh dưỡng đã phân tích của nó.
class AnalyzedIngredient {
  final String query; 
  final NutritionInfo nutrition;

  AnalyzedIngredient({
    required this.query,
    required this.nutrition,
  });
}

/// Đối tượng kết quả cuối cùng chứa tất cả thông tin phân tích.
class MealAnalysisResult {
  final String? foodName; 
  final List<AnalyzedIngredient> ingredients;
  final NutritionInfo totalNutrition;

  MealAnalysisResult({
    this.foodName, 
    required this.ingredients,
    required this.totalNutrition,
  });

  // Hàm tạo một kết quả rỗng
  factory MealAnalysisResult.empty() => MealAnalysisResult(
        foodName: "Unknown Food", 
        ingredients: [],
        totalNutrition: NutritionInfo.empty(),
      );
}