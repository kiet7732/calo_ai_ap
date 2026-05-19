import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'gemini/gemini_api_manager.dart';
import 'gemini/gemini_response_parser.dart';

class GeminiService {
  static const String _visionModel = 'gemini-2.5-flash';

  static void initialize() {
    GeminiApiManager.instance.initialize();
  }

  Future<Map<String, dynamic>> analyzeImage(XFile image) async {
    print("🤖 [Gemini] Bắt đầu phân tích (One-Shot)...");

    final String prompt =
        "Role: Nutritionist AI. Analyze this image. "
        "STEP 1: VALIDATION. Is this an image of EDIBLE FOOD? "
        "If the image contains people, animals (pets), cars, documents, or non-food objects, return EXACTLY: "
        "{ \"is_food\": false } "
        "STEP 2: IF IT IS FOOD, analyze it following these rules: "
        " 1. Identify **Dish Name** in **VIETNAMESE**. "
        " 2. Identify ingredients in **ENGLISH** (Standard USDA terms). "
        " 3. **FORMAT:** Space between number and unit (e.g., '100 g'). "
        " 4. **NO ADJECTIVES:** Remove 'raw', 'fresh', 'cooked', 'mix'. Just root nouns. "
        "OUTPUT FORMAT (JSON ONLY): "
        "{ "
        "  \"is_food\": true, "
        "  \"dish_name\": \"Tên Món Tiếng Việt\", "
        "  \"ingredients\": [\"150 g rice noodle\", \"100 g beef\"] "
        "} "
        "No Markdown.";

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      final response = await GeminiApiManager.instance
          .generateContent(
            modelName: _visionModel,
            body: {
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inline_data': {
                        'mime_type': _detectMimeType(image.path),
                        'data': base64Encode(imageBytes),
                      },
                    },
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.1},
              'safetySettings': [
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'threshold': 'BLOCK_NONE',
                },
                {
                  'category': 'HARM_CATEGORY_HATE_SPEECH',
                  'threshold': 'BLOCK_NONE',
                },
                {
                  'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
                  'threshold': 'BLOCK_NONE',
                },
                {
                  'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  'threshold': 'BLOCK_NONE',
                },
              ],
            },
          )
          .timeout(const Duration(seconds: 50));

      final responseText = GeminiResponseParser.extractText(response);

      if (responseText == null || responseText.isEmpty) {
        return _errorResult("AI không trả về dữ liệu.");
      }

      print("📥 [Gemini] Raw: $responseText");

      // XỬ LÝ JSON
      String jsonString = responseText;
      if (jsonString.contains('{') && jsonString.contains('}')) {
        jsonString = jsonString.substring(
          jsonString.indexOf('{'),
          jsonString.lastIndexOf('}') + 1,
        );
      }

      final Map<String, dynamic> jsonResult = jsonDecode(jsonString);

      if (jsonResult['is_food'] == false) {
        return _errorResult("Không phải đồ ăn", notFood: true);
      }

      String dishName = jsonResult['dish_name'] ?? "Món ăn";
      List<String> ingredients = [];
      if (jsonResult['ingredients'] is List) {
        ingredients = List<String>.from(
          jsonResult['ingredients'].map((x) => x.toString()),
        );
      }

      print("✅ [Gemini] Thành công: $dishName");

      return {'is_food': true, 'name': dishName, 'ingredients': ingredients};
    } catch (e) {
      print("❌ [Gemini] Lỗi: $e");

      String errorMsg = "Lỗi kết nối";

      // BẮT LỖI 429 CỤ THỂ
      if (e is GeminiApiException) {
        return _errorResult(e.userMessage);
      }

      if (e.toString().contains("429")) {
        print("🛑 QUOTA LIMIT: Bạn đã bấm quá nhanh!");
        // Trả về thông báo này để UI hiện lên cho người dùng biết
        return _errorResult("Server đang bận (429). Vui lòng đợi 1 phút!");
      }

      if (e is TimeoutException) errorMsg = "Mạng yếu, quá thời gian chờ.";

      return _errorResult(errorMsg);
    }
  }

  String _detectMimeType(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Map<String, dynamic> _errorResult(String msg, {bool notFood = false}) {
    return {'is_food': !notFood, 'name': msg, 'ingredients': <String>[]};
  }
}
