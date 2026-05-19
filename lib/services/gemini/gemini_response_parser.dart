class GeminiResponseParser {
  static String? extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) return null;

    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) return null;

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'];
        if (text is String && text.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.write('\n');
          }
          buffer.write(text);
        }
      }
    }

    final merged = buffer.toString().trim();
    return merged.isEmpty ? null : merged;
  }
}
