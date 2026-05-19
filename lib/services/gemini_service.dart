import 'dart:async';
import 'dart:convert';
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
    const prompt =
        'Role: Nutritionist AI. Analyze this image. '
        'STEP 1: VALIDATION. Is this an image of EDIBLE FOOD? '
        'If the image contains people, animals, cars, documents, or non-food objects, return EXACTLY: '
        '{ "is_food": false } '
        'STEP 2: IF IT IS FOOD, analyze it following these rules: '
        '1. Identify Dish Name in VIETNAMESE. '
        '2. Identify ingredients in ENGLISH using standard nutrition terms. '
        '3. Format ingredients with a space between number and unit, e.g. "100 g". '
        '4. Remove adjectives like raw, fresh, cooked, mix. '
        'OUTPUT JSON ONLY: '
        '{ "is_food": true, "dish_name": "Ten mon tieng Viet", "ingredients": ["150 g rice noodle", "100 g beef"] }';

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
        return _errorResult('AI khong tra ve du lieu.');
      }

      var jsonString = responseText;
      if (jsonString.contains('{') && jsonString.contains('}')) {
        jsonString = jsonString.substring(
          jsonString.indexOf('{'),
          jsonString.lastIndexOf('}') + 1,
        );
      }

      final jsonResult = jsonDecode(jsonString) as Map<String, dynamic>;

      if (jsonResult['is_food'] == false) {
        return _errorResult('Khong phai do an', notFood: true);
      }

      final dishName = (jsonResult['dish_name'] ?? 'Mon an').toString();
      final ingredients = jsonResult['ingredients'] is List
          ? List<String>.from(
              (jsonResult['ingredients'] as List).map((x) => x.toString()),
            )
          : <String>[];

      return {'is_food': true, 'name': dishName, 'ingredients': ingredients};
    } catch (e) {
      if (e is GeminiApiException) {
        return _errorResult(e.userMessage);
      }
      if (e is TimeoutException) {
        return _errorResult('Mang yeu, qua thoi gian cho.');
      }

      return _errorResult('Loi ket noi');
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
