import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'today_stats_provider.dart';
import '../services/gemini/gemini_api_manager.dart';
import '../services/gemini/gemini_response_parser.dart';

class ChatMessage {
  String text;
  final bool isUser;
  bool isStreaming;
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoadingProfile = true;
  bool _isSending = false;

  // Lưu lịch sử chat
  final List<Map<String, dynamic>> _apiHistory = [];
  String? _systemInstruction;

  List<ChatMessage> get messages => _messages;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isSending => _isSending;

  // --- 1. KHỞI TẠO ---
  Future<void> initializeChat(TodayStatsProvider stats) async {
    if (!_isLoadingProfile) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _finishInit("Vui lòng đăng nhập.");
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data() ?? {};

      final goal = data['goal'] ?? 'Duy trì';
      final consumed = stats.consumedCalories.toInt();
      final target = stats.calorieGoal;
      final remaining = target - consumed;

      // 🔥 SYSTEM PROMPT – KỶ LUẬT TUYỆT ĐỐI
      _systemInstruction =
          """
VAI TRÒ: Hệ thống gợi ý món ăn tự động Calo AI.
DỮ LIỆU ĐẦU VÀO: Mục tiêu: $goal | Calo còn lại: $remaining kcal.

LUẬT BẤT KHẢ KHÁNG (SYSTEM RULES):
1. 🚫 KHÔNG MARKDOWN: Tuyệt đối không dùng dấu * (in nghiêng), ** (in đậm). Chỉ dùng văn bản thường và Emoji.
2. 🚫 KHÔNG HỎI LẠI: Nếu câu hỏi ngắn (vd: "ăn gì"), TỰ ĐỘNG GIẢ ĐỊNH là bữa ăn chính tiếp theo và gợi ý ngay.
3. 🚫 KHÔNG TƯ VẤN Y TẾ: Chỉ tập trung vào calo và tên món ăn.
4. ✅ SỐ LƯỢNG CỐ ĐỊNH: Bắt buộc đưa ra 3 gợi ý.

LOGIC SUY LUẬN:
- Nếu $remaining > 500: Gợi ý các món chính (Cơm, Phở, Bún...).
- Nếu $remaining < 300: Gợi ý món ăn nhẹ, ít calo (Salad, Đồ khô, Trái cây).
- Luôn ưu tiên món ăn phổ biến tại Việt Nam.

ĐỊNH DẠNG TRẢ LỜI (BẮT BUỘC):
🥗 GỢI Ý 1: [TÊN MÓN VIẾT HOA] (~[Số] kcal)
=> [Lý do ngắn gọn dưới 10 từ]

🍜 GỢI Ý 2: [TÊN MÓN VIẾT HOA] (~[Số] kcal)
=> [Lý do ngắn gọn dưới 10 từ]

🥪 GỢI Ý 3: [TÊN MÓN VIẾT HOA] (~[Số] kcal)
=> [Lý do ngắn gọn dưới 10 từ]
""";

      String welcomeMsg =
          "Chào bạn! 👋 Còn $remaining kcal. Đói bụng chưa? Để mình gợi ý vài món nhé?";
      if (remaining < 0) {
        welcomeMsg =
            "Hôm nay lố $remaining kcal rồi 😅. Mai làm lại! Giờ cần tâm sự gì không?";
      }

      _finishInit(welcomeMsg);
    } catch (e) {
      print("🔥 Lỗi Init: $e");
      _finishInit("Lỗi tải dữ liệu.");
    }
  }

  void _finishInit(String msg) {
    _isLoadingProfile = false;
    _messages.add(ChatMessage(text: msg, isUser: false));
    _apiHistory.add({
      "role": "model",
      "parts": [
        {"text": msg},
      ],
    });
    notifyListeners();
  }

  // --- 2. GỬI TIN NHẮN ---
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Hiện tin nhắn User lên UI
    _messages.add(ChatMessage(text: text, isUser: true));
    _isSending = true;
    notifyListeners();

    final hasKeys = GeminiApiManager.instance.availableKeyCount > 0;
    if (!hasKeys) {
      _handleError("Chưa cấu hình API Key");
      return;
    }

    // 2. Cập nhật lịch sử (CHỈ LƯU TIN NHẮN THUẦN, KHÔNG GHÉP PROMPT NỮA)
    // Việc tách Prompt ra giúp lịch sử sạch đẹp và AI không bị loạn.
    _apiHistory.add({
      "role": "user",
      "parts": [
        {"text": text},
      ],
    });

    // Tạo payload gửi đi
    List<Map<String, dynamic>> requestPayload = List.from(_apiHistory);

    try {
      final response = await GeminiApiManager.instance.generateContent(
        modelName: 'gemini-2.5-flash',
        body: {
          "systemInstruction": {
            "parts": [
              {"text": _systemInstruction ?? "Bạn là trợ lý ảo."},
            ],
          },
          "contents": requestPayload,
          "generationConfig": {"temperature": 1.0, "maxOutputTokens": 2000},
          "safetySettings": [
            {
              "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
              "threshold": "BLOCK_NONE",
            },
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
            {
              "category": "HARM_CATEGORY_HATE_SPEECH",
              "threshold": "BLOCK_NONE",
            },
            {
              "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
              "threshold": "BLOCK_NONE",
            },
          ],
        },
      );

      _isSending = false;

      final botReply = GeminiResponseParser.extractText(response);

      if (botReply != null) {
        print("🤖 [ChatProvider] Bot Reply: $botReply");
        _messages.add(ChatMessage(text: botReply, isUser: false));
        _apiHistory.add({
          "role": "model",
          "parts": [
            {"text": botReply},
          ],
        });
      } else {
        _messages.add(
          ChatMessage(text: "Hệ thống không phản hồi.", isUser: false),
        );
      }
      notifyListeners();
    } catch (e) {
      if (e is GeminiApiException) {
        _handleError(e.userMessage);
        return;
      }
      _handleError("Lỗi ứng dụng: $e");
    }
  }

  void _handleError(String error) {
    _isSending = false;
    _messages.add(ChatMessage(text: error, isUser: false));
    if (_apiHistory.isNotEmpty && _apiHistory.last['role'] == 'user') {
      _apiHistory.removeLast();
    }
    notifyListeners();
  }
}
