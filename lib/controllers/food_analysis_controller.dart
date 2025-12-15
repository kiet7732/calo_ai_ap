// lib/controllers/food_analysis_controller.dart

import 'package:image_picker/image_picker.dart';
import '../models/meal_analysis_result.dart';
import '../services/edamam_service.dart';
import '../services/gemini_service.dart';
import '../utils/image_utils.dart';

class FoodAnalysisController {
  final GeminiService _geminiService;
  final EdamamService _edamamService;

  FoodAnalysisController({
    GeminiService? geminiService,
    EdamamService? edamamService,
  }) : _geminiService = geminiService ?? GeminiService(),
       _edamamService = edamamService ?? EdamamService();

  /// Hàm chính điều phối toàn bộ quy trình phân tích món ăn.
  // lib/controllers/food_analysis_controller.dart
  // ... (Imports giữ nguyên)

  Future<MealAnalysisResult> processMeal(XFile image) async {
    print("🚀 Starting meal analysis...");

    // Bước 0: Nén ảnh
    final compressedImage = await ImageUtils.compressImage(image);

    // Bước 1: Gemini Vision
    print("   [Step 1/3] 🤖 Gemini analyzing...");
    final Map<String, dynamic> geminiResult = await _geminiService.analyzeImage(
      compressedImage,
    );

    // --- KIỂM TRA: CÓ PHẢI ĐỒ ĂN KHÔNG? ---
    // Nếu Gemini bảo không phải đồ ăn (is_food == false)
    if (geminiResult['is_food'] == false) {
      print("⏹️ Process stopped: Not a food image.");

      // Trả về một kết quả đặc biệt để UI hiển thị thông báo
      return MealAnalysisResult(
        foodName: "Không phải đồ ăn",
        ingredients: [],
        totalNutrition: NutritionInfo.empty(),
      );
    }

    // Nếu là đồ ăn thì lấy dữ liệu bình thường
    final String dishName = geminiResult['name'];
    final List<String> ingredients = List<String>.from(
      geminiResult['ingredients'],
    );

    if (ingredients.isEmpty) return MealAnalysisResult.empty();

    // Bước 2: Edamam API
    print("   [Step 2/3] 🍳 Edamam analyzing ($dishName)...");
    final MealAnalysisResult edamamResult = await _edamamService.analyzeMeal(
      ingredients,
    );

    // Bước 3: Tổng hợp
    final finalResult = MealAnalysisResult(
      foodName: dishName,
      ingredients: edamamResult.ingredients,
      totalNutrition: edamamResult.totalNutrition,
    );
    
    print("✅ Meal analysis complete!");
    print("📊 Dish: ${finalResult.foodName}");
    print(
      "📊 Total Nutrition: ${finalResult.totalNutrition.calories.round()} kcal",
    );
    return finalResult;
  }
}
