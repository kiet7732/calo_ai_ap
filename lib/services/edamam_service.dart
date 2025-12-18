import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/meal_analysis_result.dart';

class EdamamService {
  static final String _appId = dotenv.env['EDAMAM_APP_ID']!;
  static final String _appKey = dotenv.env['EDAMAM_APP_KEY']!;

  /// Hàm chính: Phân tích dinh dưỡng.
  Future<MealAnalysisResult> analyzeMeal(List<String> rawIngredients) async {
    // BƯỚC 1: LÀM SẠCH DANH SÁCH NGAY TỪ ĐẦU
    // Biến đổi "300g" -> "300 grams", "100ml" -> "100 milliliters"
    List<String> cleanIngredients = rawIngredients.map((item) => _cleanIngredient(item)).toList();
    
    print("         [EdamamService] 🍳 Analyzing meal (Batch Mode)...");
    print("         [EdamamService] 🧹 Cleaned Input: $cleanIngredients"); // Debug xem đã sạch chưa

    // --- CÁCH 1: Gửi cả danh sách (POST) ---
    final url = Uri.https('api.edamam.com', '/api/nutrition-details', {
      'app_id': _appId,
      'app_key': _appKey,
    });

    final body = jsonEncode({
      'title': 'User Meal', 
      'ingr': cleanIngredients, // Gửi danh sách ĐÃ LÀM SẠCH
      'yield': 1
    });

    final headers = {'Content-Type': 'application/json'};

    try {
      // Thêm timeout 10 giây cho request tổng
      final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseSuccessResponse(response.body);
      } 
      // NẾU GẶP LỖI 555 HOẶC 422
      else if (response.statusCode == 555 || response.statusCode == 422) {
        print("         [EdamamService] ⚠️ Batch failed (${response.statusCode}). Switching to Individual Mode...");
        // Gửi danh sách đã làm sạch vào hàm fallback
        return await _analyzeIngredientsIndividually(cleanIngredients);
      } 
      else {
        print("         [EdamamService] ❌ API error: ${response.statusCode} - ${response.body}");
        return MealAnalysisResult.empty();
      }
    } catch (e) {
      // Nếu lỗi là Timeout hoặc SocketException, thử chuyển sang chế độ gửi lẻ
      if (e is TimeoutException || e.toString().contains("SocketException")) {
        print("         [EdamamService] ⏰ Batch timed out. Switching to Individual Mode...");
        return await _analyzeIngredientsIndividually(cleanIngredients);
      }
      print("         [EdamamService] ❌ Exception: $e");
      return MealAnalysisResult.empty();
    }
  }

  /// Hàm chuẩn hóa chuỗi: Tự động tách số, đổi đơn vị
  String _cleanIngredient(String raw) {
    // 1. Tách số và chữ dính liền (300g -> 300 g)
    String processed = raw.replaceAllMapped(
      RegExp(r'(\d+)([a-zA-Z]+)'), 
      (Match m) => "${m[1]} ${m[2]}"
    );

    // 2. Thay thế đơn vị viết tắt thành đầy đủ 
    processed = processed
        .replaceAll(RegExp(r'\b g\b'), ' grams') // chữ "g" đứng riêng -> "grams"
        .replaceAll(RegExp(r'\bg\b'), ' grams')  // chữ "g" ở cuối
        .replaceAll(RegExp(r'\bml\b'), ' milliliters')
        .replaceAll(RegExp(r'\btbsp\b'), ' tablespoon')
        .replaceAll(RegExp(r'\btsp\b'), ' teaspoon');

    return processed;
  }

  // Hàm phụ: Xử lý khi gửi thành công
  MealAnalysisResult _parseSuccessResponse(String responseBody) {
    final data = jsonDecode(responseBody);
    
    // Parse chi tiết
    List<AnalyzedIngredient> analyzedIngredients = [];
    if (data['ingredients'] != null) {
      analyzedIngredients = (data['ingredients'] as List<dynamic>).map((item) {
        final parsedList = item['parsed'];
        if (parsedList != null && (parsedList as List).isNotEmpty) {
           final parsedItem = parsedList[0];
           final nutrients = parsedItem['nutrients'];
           return AnalyzedIngredient(
             query: item['text'] ?? "Unknown",
             nutrition: _extractNutrition(nutrients),
           );
        } else {
           return AnalyzedIngredient(query: item['text'], nutrition: NutritionInfo());
        }
      }).toList();
    }

    // Parse tổng
    NutritionInfo totalNutritionInfo;
    if (data['totalNutrients'] != null) {
      final totalNutrients = data['totalNutrients'];
      totalNutritionInfo = _extractNutrition(totalNutrients);
    } else {
      totalNutritionInfo = _sumManually(analyzedIngredients);
    }

    return MealAnalysisResult(
      ingredients: analyzedIngredients,
      totalNutrition: totalNutritionInfo,
    );
  }

  // Hàm phụ: Cứu hộ gửi lẻ (Có Delay để tránh bị khóa)
  Future<MealAnalysisResult> _analyzeIngredientsIndividually(List<String> ingredients) async {
    List<AnalyzedIngredient> results = [];
    
    for (String ingredient in ingredients) {
      print("         [EdamamService] 🔍 Fallback: Analyzing '$ingredient'...");
      
      // Thêm delay nhẹ 0.5 giây để không bị API chặn vì spam quá nhanh
      await Future.delayed(const Duration(milliseconds: 500));

      final url = Uri.https('api.edamam.com', '/api/nutrition-data', {
        'app_id': _appId,
        'app_key': _appKey,
        'ingr': ingredient,
      });

      try {
        // Timeout 5 giây cho mỗi request lẻ
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['calories'] != null && (data['totalWeight'] ?? 0) > 0) {
            final nutrients = data['totalNutrients'];
            results.add(AnalyzedIngredient(query: ingredient, nutrition: _extractNutrition(nutrients)));
          } else {
            print("         [EdamamService] ⚠️ Still could not analyze: $ingredient");
            results.add(AnalyzedIngredient(query: ingredient, nutrition: NutritionInfo()));
          }
        }
      } catch (e) {
        print("         [EdamamService] ❌ Fallback error: $e");
      }
    }

    return MealAnalysisResult(
      ingredients: results,
      totalNutrition: _sumManually(results),
    );
  }

  NutritionInfo _extractNutrition(Map<String, dynamic>? nutrients) {
    if (nutrients == null) return NutritionInfo();
    return NutritionInfo(
      calories: (nutrients['ENERC_KCAL']?['quantity'] ?? 0.0).toDouble(),
      protein: (nutrients['PROCNT']?['quantity'] ?? 0.0).toDouble(),
      carbs: (nutrients['CHOCDF']?['quantity'] ?? 0.0).toDouble(),
      fat: (nutrients['FAT']?['quantity'] ?? 0.0).toDouble(),
    );
  }

  NutritionInfo _sumManually(List<AnalyzedIngredient> list) {
    double cal = 0, pro = 0, carb = 0, fat = 0;
    for (var item in list) {
      cal += item.nutrition.calories;
      pro += item.nutrition.protein;
      carb += item.nutrition.carbs;
      fat += item.nutrition.fat;
    }
    return NutritionInfo(calories: cal, protein: pro, carbs: carb, fat: fat);
  }
}