import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiApiManager {
  GeminiApiManager._();

  static final GeminiApiManager instance = GeminiApiManager._();
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const Duration _disabledKeyCooldown = Duration(minutes: 10);

  final http.Client _client = http.Client();
  final Map<String, DateTime> _disabledKeys = <String, DateTime>{};
  int _preferredKeyIndex = 0;

  List<String> get _allKeys {
    final keys = <String>[];

    void addKey(String? raw) {
      if (raw == null) return;
      final trimmed = raw.trim();
      if (trimmed.isEmpty || keys.contains(trimmed)) return;
      keys.add(trimmed);
    }

    final rawList = dotenv.env['GEMINI_API_KEYS'];
    if (rawList != null && rawList.trim().isNotEmpty) {
      for (final key in rawList.split(RegExp(r'[\n,;]+'))) {
        addKey(key);
      }
    }

    addKey(dotenv.env['GEMINI_API_KEY']);
    addKey(dotenv.env['CHAT_API_KEY']);

    return keys;
  }

  int get availableKeyCount => _allKeys.length;

  void initialize() {
    final totalKeys = _allKeys.length;
    if (totalKeys == 0) {
      throw GeminiApiException(
        userMessage: 'Chưa cấu hình GEMINI_API_KEYS hoặc GEMINI_API_KEY.',
      );
    }
  }

  bool _isKeyAvailable(String apiKey) {
    final blockedUntil = _disabledKeys[apiKey];
    if (blockedUntil == null) return true;

    if (DateTime.now().isAfter(blockedUntil)) {
      _disabledKeys.remove(apiKey);
      return true;
    }

    return false;
  }

  void _temporarilyDisableKey(String apiKey) {
    _disabledKeys[apiKey] = DateTime.now().add(_disabledKeyCooldown);
  }

  List<int> _buildKeyOrder(int totalKeys) {
    if (totalKeys == 0) return const <int>[];

    final normalizedStart = _preferredKeyIndex % totalKeys;
    return List<int>.generate(
      totalKeys,
      (offset) => (normalizedStart + offset) % totalKeys,
    );
  }

  Future<Map<String, dynamic>> generateContent({
    required String modelName,
    required Map<String, dynamic> body,
  }) async {
    final keys = _allKeys;
    if (keys.isEmpty) {
      throw GeminiApiException(
        userMessage: 'Chưa cấu hình GEMINI_API_KEYS hoặc GEMINI_API_KEY.',
      );
    }

    GeminiApiException? lastError;
    final keyOrder = _buildKeyOrder(keys.length);

    for (final keyIndex in keyOrder) {
      final apiKey = keys[keyIndex];
      if (!_isKeyAvailable(apiKey)) continue;

      final uri = Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey');
      final response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _preferredKeyIndex = keyIndex;
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      final error = GeminiApiException.fromHttpResponse(
        statusCode: response.statusCode,
        responseBody: utf8.decode(response.bodyBytes),
      );

      if (error.shouldDisableKey) {
        _temporarilyDisableKey(apiKey);
      }

      if (error.shouldTryNextKey) {
        lastError = error;
        continue;
      }

      throw error;
    }

    if (keys.every((key) => !_isKeyAvailable(key))) {
      throw GeminiApiException(
        userMessage:
            'Dich vu AI tam thoi khong kha dung. Vui long thu lai sau.',
      );
    }

    throw lastError ??
        GeminiApiException(
          userMessage: 'Khong the ket noi toi dich vu AI luc nay.',
        );
  }
}

class GeminiApiException implements Exception {
  GeminiApiException({
    required this.userMessage,
    this.shouldTryNextKey = false,
    this.shouldDisableKey = false,
  });

  final String userMessage;
  final bool shouldTryNextKey;
  final bool shouldDisableKey;

  factory GeminiApiException.fromHttpResponse({
    required int statusCode,
    required String responseBody,
  }) {
    final lowerBody = responseBody.toLowerCase();
    final quotaLike =
        statusCode == 429 ||
        lowerBody.contains('resource_exhausted') ||
        lowerBody.contains('quota') ||
        lowerBody.contains('rate limit') ||
        lowerBody.contains('too many requests');

    if (quotaLike) {
      return GeminiApiException(
        userMessage:
            'Dich vu AI tam thoi khong kha dung. Vui long thu lai sau.',
        shouldTryNextKey: true,
        shouldDisableKey: true,
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return GeminiApiException(
        userMessage:
            'Dich vu AI tam thoi khong kha dung. Vui long thu lai sau.',
        shouldTryNextKey: true,
        shouldDisableKey: true,
      );
    }

    return GeminiApiException(
      userMessage: 'Gemini loi $statusCode. Vui long thu lai sau.',
    );
  }

  @override
  String toString() => userMessage;
}
