import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiApiManager {
  GeminiApiManager._();

  static final GeminiApiManager instance = GeminiApiManager._();
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const Duration _disabledKeyCooldown = Duration(minutes: 10);
  static const List<Duration> _transientRetryDelays = <Duration>[
    Duration(milliseconds: 450),
    Duration(milliseconds: 900),
  ];

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
    if (_allKeys.isEmpty) {
      throw GeminiApiException(
        userMessage: 'Chưa cấu hình GEMINI_API_KEYS hoặc GEMINI_API_KEY.',
      );
    }
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

    for (final keyIndex in _buildKeyOrder(keys.length)) {
      final apiKey = keys[keyIndex];
      if (!_isKeyAvailable(apiKey)) {
        _log(
          'skip key[$keyIndex] model=$modelName reason=disabled cooldown_active=true',
        );
        continue;
      }

      final uri = Uri.parse('$_baseUrl/$modelName:generateContent?key=$apiKey');
      final response = await _postWithRetry(
        uri: uri,
        body: body,
        modelName: modelName,
        keyIndex: keyIndex,
        apiKey: apiKey,
      );
      final responseText = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        _preferredKeyIndex = keyIndex;
        return jsonDecode(responseText) as Map<String, dynamic>;
      }

      final error = GeminiApiException.fromHttpResponse(
        statusCode: response.statusCode,
        responseBody: responseText,
      );

      if (error.shouldDisableKey) {
        _temporarilyDisableKey(apiKey);
        _log(
          'disable key[$keyIndex] model=$modelName status=${response.statusCode} until=${_disabledKeys[apiKey]}',
        );
      }

      if (error.shouldTryNextKey) {
        lastError = error;
        _log(
          'retry next key model=$modelName keyIndex=$keyIndex reason=${error.userMessage}',
        );
        continue;
      }

      throw error;
    }

    if (keys.every((key) => !_isKeyAvailable(key))) {
      throw GeminiApiException(
        userMessage:
            'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.',
      );
    }

    throw lastError ??
        GeminiApiException(
          userMessage: 'Không thể kết nối tới dịch vụ AI lúc này.',
        );
  }

  Future<http.Response> _postWithRetry({
    required Uri uri,
    required Map<String, dynamic> body,
    required String modelName,
    required int keyIndex,
    required String apiKey,
  }) async {
    late http.Response response;

    for (var attempt = 0; attempt <= _transientRetryDelays.length; attempt++) {
      _log(
        'request model=$modelName keyIndex=$keyIndex keySuffix=${_maskKey(apiKey)} preferred=$_preferredKeyIndex attempt=${attempt + 1}',
      );

      response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseText = utf8.decode(response.bodyBytes);
      _log(
        'response model=$modelName keyIndex=$keyIndex status=${response.statusCode} attempt=${attempt + 1} body=${_shorten(responseText)}',
      );

      if (!_shouldRetryTransient(response.statusCode, responseText)) {
        return response;
      }

      if (attempt == _transientRetryDelays.length) {
        return response;
      }

      final delay = _transientRetryDelays[attempt];
      _log(
        'transient retry model=$modelName keyIndex=$keyIndex delayMs=${delay.inMilliseconds}',
      );
      await Future<void>.delayed(delay);
    }

    return response;
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

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[GeminiApiManager] $message');
    }
  }

  String _maskKey(String apiKey) {
    if (apiKey.length <= 6) return apiKey;
    return apiKey.substring(apiKey.length - 6);
  }

  String _shorten(String value) {
    const maxLength = 400;
    final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.length <= maxLength) return singleLine;
    return '${singleLine.substring(0, maxLength)}...';
  }

  bool _shouldRetryTransient(int statusCode, String responseBody) {
    final lowerBody = responseBody.toLowerCase();
    return statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        lowerBody.contains('"status": "unavailable"') ||
        lowerBody.contains('currently experiencing high demand');
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

    if (quotaLike || statusCode == 401 || statusCode == 403) {
      return GeminiApiException(
        userMessage:
            'Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.',
        shouldTryNextKey: true,
        shouldDisableKey: true,
      );
    }

    return GeminiApiException(
      userMessage: 'Gemini lỗi $statusCode. Vui lòng thử lại sau.',
    );
  }

  @override
  String toString() => userMessage;
}
