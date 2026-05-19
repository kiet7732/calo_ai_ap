import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/chat/chat_memory_service.dart';
import '../services/chat/chat_session_service.dart';
import '../services/gemini/gemini_api_manager.dart';
import '../services/gemini/gemini_response_parser.dart';
import 'today_stats_provider.dart';
import '../services/gemini/gemini_api_manager.dart';
import '../services/gemini/gemini_response_parser.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.id,
    this.isStreaming = false,
  });

  String text;
  final bool isUser;
  String? id;
  bool isStreaming;
}

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    ChatSessionService? sessionService,
    ChatMemoryService? memoryService,
  }) : _sessionService = sessionService ?? ChatSessionService(),
       _memoryService = memoryService ?? ChatMemoryService();

  static const List<String> _chatModels = <String>[
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];
  static const int _recentContextLimit = 18;

  final ChatSessionService _sessionService;
  final ChatMemoryService _memoryService;
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _apiHistory = [];

  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isLoadingProfile = true;
  bool _isSending = false;
  String? _uid;
  String _sessionId = '';
  String _sessionTitle = 'Trợ lý dinh dưỡng';
  String _conversationSummary = '';
  String _profileContext = '';
  List<String> _memoryFacts = [];
  List<String> _recentSuggestions = [];
  List<String> _followUpSuggestions = [];

  List<ChatMessage> get messages => _messages;
  bool get isInitialized => _isInitialized;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isSending => _isSending;
  String get sessionTitle => _sessionTitle;
  List<String> get rememberedFacts => List.unmodifiable(_memoryFacts);
  List<String> get recentSuggestions => List.unmodifiable(_recentSuggestions);
  List<String> get followUpSuggestions =>
      List.unmodifiable(_followUpSuggestions);
  bool get canRegenerate {
    if (_isSending || _messages.length < 2) return false;
    if (_messages.last.isUser) return false;
    return _lastUserMessage() != null;
  }

  List<String> get quickActions => const <String>[
    'Gợi ý bữa sáng',
    'Món dưới 300 kcal',
    'Nhiều protein',
    'Đổi món khác',
  ];

  Future<void> initializeChat(TodayStatsProvider stats) async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    _isLoadingProfile = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _finishLocalInit('Vui lòng đăng nhập để dùng trợ lý dinh dưỡng.');
      return;
    }

    _uid = user.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      _profileContext = _buildProfileContext(userDoc.data() ?? {}, stats);

      _sessionId = await _sessionService.createSession(user.uid);
      _sessionTitle = 'Trợ lý dinh dưỡng';
      _conversationSummary = '';

      final memory = await _memoryService.loadMemory(user.uid);
      _memoryFacts = memory.facts;
      _recentSuggestions = memory.recentSuggestions;

      final welcome = _buildWelcomeMessage(stats);
      final id = await _sessionService.saveMessage(
        uid: user.uid,
        sessionId: _sessionId,
        text: welcome,
        isUser: false,
      );
      _messages.add(ChatMessage(id: id, text: welcome, isUser: false));

      _rebuildApiHistory();
      _isInitialized = true;
      _isLoadingProfile = false;
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _isInitializing = false;
      _finishLocalInit('Lỗi tải dữ liệu chat. Vui lòng thử lại.');
    }
  }

  Future<void> sendMessage(String text) async {
    final cleanedText = text.trim();
    if (cleanedText.isEmpty || _isSending) return;

    final uid = _uid;
    if (uid == null) {
      _handleError('Vui lòng đăng nhập để tiếp tục.');
      return;
    }

    _followUpSuggestions = [];

    final userMessage = ChatMessage(text: cleanedText, isUser: true);
    _messages.add(userMessage);
    _apiHistory.add(_toGeminiContent(cleanedText, isUser: true));
    notifyListeners();

    try {
      _debugLog(
        'sendMessage text="$cleanedText" history=${_apiHistory.length} session=$_sessionId',
      );
      userMessage.id = await _sessionService.saveMessage(
        uid: uid,
        sessionId: _sessionId,
        text: cleanedText,
        isUser: true,
      );
      await _rememberFromUserText(cleanedText);
      await _generateAssistantReply();
    } catch (e) {
      _removeMessage(userMessage);
      _handleError('Lỗi gửi tin nhắn. Vui lòng thử lại.');
    }
  }

  Future<void> sendQuickAction(String text) {
    return sendMessage(text);
  }

  Future<void> regenerateLastReply() async {
    if (!canRegenerate) return;

    final lastAssistant = _messages.last;
    if (lastAssistant.id != null && _uid != null) {
      unawaited(
        _sessionService.deleteMessage(
          uid: _uid!,
          sessionId: _sessionId,
          messageId: lastAssistant.id!,
        ),
      );
    }

    _messages.removeLast();
    if (_apiHistory.isNotEmpty && _apiHistory.last['role'] == 'model') {
      _apiHistory.removeLast();
    }
    _followUpSuggestions = [];
    notifyListeners();

    await _generateAssistantReply();
  }

  Future<void> clearMemory() async {
    final uid = _uid;
    if (uid == null) return;

    _memoryFacts = [];
    _recentSuggestions = [];
    await _memoryService.clearMemory(uid);
    notifyListeners();
  }

  Future<void> _generateAssistantReply() async {
    final uid = _uid;
    if (uid == null) return;

    _isSending = true;
    notifyListeners();

    try {
      _debugLog(
        'generateAssistantReply models=${_chatModels.join(",")} recentContext=${_buildRequestContents().length}',
      );
      final response = await _requestChatResponse();

      final reply =
          GeminiResponseParser.extractText(response) ??
          'Hệ thống không phản hồi.';
      _debugLog('assistant reply length=${reply.length}');
      final assistantMessage = await _streamAssistantReply(reply);
      assistantMessage.id = await _sessionService.saveMessage(
        uid: uid,
        sessionId: _sessionId,
        text: reply,
        isUser: false,
      );

      _apiHistory.add(_toGeminiContent(reply, isUser: false));
      await _rememberFromAssistantText(reply);
      _followUpSuggestions = _buildFollowUpSuggestions();
      _isSending = false;
      notifyListeners();

      if (_messages.length >= 14 && _messages.length % 6 == 0) {
        unawaited(_refreshConversationSummary());
      }
    } catch (e) {
      _isSending = false;
      _debugLog('assistant error=$e');
      if (e is GeminiApiException) {
        _handleError(e.userMessage);
      } else {
        _handleError('Lỗi ứng dụng: $e');
      }
    }
  }

  Future<ChatMessage> _streamAssistantReply(String reply) async {
    final assistantMessage = ChatMessage(
      text: '',
      isUser: false,
      isStreaming: true,
    );
    _messages.add(assistantMessage);
    notifyListeners();

    const chunkSize = 18;
    for (var i = 0; i < reply.length; i += chunkSize) {
      final end = (i + chunkSize) > reply.length ? reply.length : i + chunkSize;
      assistantMessage.text = reply.substring(0, end);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }

    assistantMessage.isStreaming = false;
    notifyListeners();
    return assistantMessage;
  }

  Future<void> _rememberFromUserText(String text) async {
    final uid = _uid;
    if (uid == null) return;

    final newFacts = _memoryService.extractFacts(text);
    if (newFacts.isEmpty) return;

    _memoryFacts = await _memoryService.addFacts(
      uid: uid,
      currentFacts: _memoryFacts,
      newFacts: newFacts,
    );
    notifyListeners();
  }

  Future<void> _rememberFromAssistantText(String text) async {
    final uid = _uid;
    if (uid == null) return;

    final newSuggestions = _memoryService.extractSuggestions(text);
    if (newSuggestions.isEmpty) return;

    _recentSuggestions = await _memoryService.updateRecentSuggestions(
      uid: uid,
      currentSuggestions: _recentSuggestions,
      newSuggestions: newSuggestions,
    );
  }

  Future<void> _refreshConversationSummary() async {
    final uid = _uid;
    if (uid == null) return;

    final transcript = _messages
        .take(_messages.length - 8)
        .map((message) => '${message.isUser ? "User" : "AI"}: ${message.text}')
        .join('\n');
    if (transcript.trim().isEmpty) return;

    try {
      final response = await GeminiApiManager.instance.generateContent(
        modelName: _chatModels.first,
        body: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Tom tat hoi thoai sau bang tieng Viet, toi da 6 gach dau dong ngan gon. Chi giu so thich, muc tieu, rang buoc an uong va cac quyet dinh quan trong.\n$transcript',
                },
              ],
            },
          ],
          'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 350},
        },
      );
      final summary = GeminiResponseParser.extractText(response);
      if (summary == null || summary.trim().isEmpty) return;

      _conversationSummary = summary.trim();
      await _sessionService.updateSummary(
        uid: uid,
        sessionId: _sessionId,
        summary: _conversationSummary,
      );
    } catch (_) {
      // Summary is helpful, but it should never interrupt the chat flow.
    }
  }

  List<Map<String, dynamic>> _buildRequestContents() {
    final recent = _apiHistory.length > _recentContextLimit
        ? _apiHistory.sublist(_apiHistory.length - _recentContextLimit)
        : List<Map<String, dynamic>>.from(_apiHistory);

    return recent;
  }

  String _buildSystemInstruction() {
    final memoryText = _memoryFacts.isEmpty
        ? 'Chua co memory dai han.'
        : _memoryFacts.map((fact) => '- $fact').join('\n');
    final recentSuggestionText = _recentSuggestions.isEmpty
        ? 'Chua co mon da goi y gan day.'
        : _recentSuggestions.map((item) => '- $item').join('\n');
    final summaryText = _conversationSummary.trim().isEmpty
        ? 'Chua co tom tat hoi thoai.'
        : _conversationSummary.trim();

    return '''
Vai tro: Tro ly dinh duong cua ung dung Calo AI.
Ngu canh nguoi dung hien tai:
$_profileContext

Memory dai han can ton trong:
$memoryText

Tom tat hoi thoai cu:
$summaryText

Mon da goi y gan day, han che lap lai:
$recentSuggestionText

Quy tac tra loi:
- Tra loi bang tieng Viet tu nhien, ngan gon, than thien.
- Uu tien mon an pho bien tai Viet Nam va phu hop muc tieu calo.
- Neu nguoi dung hoi "an gi", "goi y", hoac cau ngan mo ho, tu suy luan bua tiep theo va dua 3 goi y.
- Bat buoc moi mon an duoc goi y phai kem uoc luong calo, viet theo dang "~220 kcal" hoac "khoang 220-260 kcal".
- Neu goi y tu 2 mon tro len, moi dong moi mon phai co ten mon va calo rieng, khong duoc bo sot.
- Khong lap lai mon da goi y gan day tru khi nguoi dung yeu cau.
- Neu nguoi dung noi so thich, di ung, an chay, khong an duoc mon nao, hay ap dung nhat quan.
- Khong dung Markdown dam/nghieng. Co the xuong dong de de doc.
- Khong tu van y te chan doan; chi noi ve thuc don, calo va thoi quen an uong co ban.

Dinh dang uu tien khi dang goi y mon:
1. Ten mon (~so kcal): mo ta rat ngan
2. Ten mon (~so kcal): mo ta rat ngan
3. Ten mon (~so kcal): mo ta rat ngan
''';
  }

  String _buildProfileContext(
    Map<String, dynamic> data,
    TodayStatsProvider stats,
  ) {
    final goal = data['goal'] ?? data['goalType'] ?? 'Duy tri';
    final consumed = stats.consumedCalories.toInt();
    final target = stats.calorieGoal;
    final remaining = target - consumed;

    return [
      'Muc tieu: $goal',
      'Da an: $consumed kcal',
      'Muc tieu ngay: $target kcal',
      'Con lai: $remaining kcal',
    ].join('\n');
  }

  String _buildWelcomeMessage(TodayStatsProvider stats) {
    final remaining = stats.calorieGoal - stats.consumedCalories.toInt();
    if (remaining < 0) {
      return 'Hôm nay bạn đã vượt ${remaining.abs()} kcal rồi. Mình có thể gợi ý bữa nhẹ hoặc cách cân bằng phần còn lại.';
    }
    return 'Chào bạn. Hôm nay bạn còn $remaining kcal. Mình có thể gợi ý bữa ăn, tính calo gần đúng, hoặc lập thực đơn nhé.';
  }

  List<String> _buildFollowUpSuggestions() {
    return const <String>['Đổi món khác', 'Ít calo hơn', 'Nhiều protein hơn'];
  }

  Map<String, dynamic> _toGeminiContent(String text, {required bool isUser}) {
    return {
      'role': isUser ? 'user' : 'model',
      'parts': [
        {'text': text},
      ],
    };
  }

  void _rebuildApiHistory() {
    _apiHistory
      ..clear()
      ..addAll(
        _messages.map(
          (message) => _toGeminiContent(message.text, isUser: message.isUser),
        ),
      );
  }

  ChatMessage? _lastUserMessage() {
    for (final message in _messages.reversed) {
      if (message.isUser) return message;
    }
    return null;
  }

  void _removeMessage(ChatMessage message) {
    _messages.remove(message);
    if (_apiHistory.isNotEmpty) {
      _apiHistory.removeLast();
    }
    notifyListeners();
  }

  void _finishLocalInit(String msg) {
    _isInitialized = true;
    _isInitializing = false;
    _isLoadingProfile = false;
    _messages.add(ChatMessage(text: msg, isUser: false));
    notifyListeners();
  }

  void _handleError(String error) {
    _isSending = false;
    _debugLog('ui error="$error"');
    _messages.add(ChatMessage(text: error, isUser: false));
    if (_apiHistory.isNotEmpty && _apiHistory.last['role'] == 'user') {
      _apiHistory.removeLast();
    }
    notifyListeners();
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[ChatProvider] $message');
    }
  }

  Future<Map<String, dynamic>> _requestChatResponse() async {
    GeminiApiException? lastError;

    for (final model in _chatModels) {
      try {
        return await GeminiApiManager.instance.generateContent(
          modelName: model,
          body: {
            'systemInstruction': {
              'parts': [
                {'text': _buildSystemInstruction()},
              ],
            },
            'contents': _buildRequestContents(),
            'generationConfig': {'temperature': 0.85, 'maxOutputTokens': 1200},
            'safetySettings': [
              {
                'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
                'threshold': 'BLOCK_NONE',
              },
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
            ],
          },
        );
      } catch (e) {
        if (e is GeminiApiException) {
          lastError = e;
          _debugLog('model fallback from $model reason=${e.userMessage}');
          continue;
        }
        rethrow;
      }
    }

    throw lastError ??
        GeminiApiException(
          userMessage:
              'Dich vu AI tam thoi khong kha dung. Vui long thu lai sau.',
        );
  }
}
