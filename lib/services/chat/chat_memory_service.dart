import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMemoryState {
  ChatMemoryState({required this.facts, required this.recentSuggestions});

  final List<String> facts;
  final List<String> recentSuggestions;
}

class ChatMemoryService {
  ChatMemoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _memoryRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chat_memory')
        .doc('profile');
  }

  Future<ChatMemoryState> loadMemory(String uid) async {
    final snap = await _memoryRef(uid).get();
    final data = snap.data() ?? {};

    return ChatMemoryState(
      facts: _stringList(data['facts']),
      recentSuggestions: _stringList(data['recentSuggestions']),
    );
  }

  Future<List<String>> addFacts({
    required String uid,
    required List<String> currentFacts,
    required List<String> newFacts,
  }) async {
    final merged = _mergeLimited(currentFacts, newFacts, 24);
    await _memoryRef(uid).set({
      'facts': merged,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return merged;
  }

  Future<List<String>> updateRecentSuggestions({
    required String uid,
    required List<String> currentSuggestions,
    required List<String> newSuggestions,
  }) async {
    final merged = _mergeLimited(newSuggestions, currentSuggestions, 12);
    await _memoryRef(uid).set({
      'recentSuggestions': merged,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return merged;
  }

  Future<void> clearMemory(String uid) async {
    await _memoryRef(uid).set({
      'facts': <String>[],
      'recentSuggestions': <String>[],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<String> extractFacts(String text) {
    final normalized = text.trim();
    final lower = normalized.toLowerCase();
    final shouldRemember = <String>[
      'toi khong an',
      'minh khong an',
      'khong an duoc',
      'di ung',
      'dị ứng',
      'toi thich',
      'minh thich',
      'toi muon',
      'muc tieu',
      'mục tiêu',
      'an chay',
      'ăn chay',
      'low carb',
      'eat clean',
      'giam can',
      'giảm cân',
      'tang can',
      'tăng cân',
    ].any(lower.contains);

    if (!shouldRemember) return const <String>[];

    final compact = normalized.replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length < 8) return const <String>[];
    return <String>[compact.length > 140 ? compact.substring(0, 140) : compact];
  }

  List<String> extractSuggestions(String text) {
    final suggestions = <String>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final cleaned = line
          .replaceAll(RegExp(r'^[^\wÀ-ỹ]+'), '')
          .replaceAll(RegExp(r'\(.+?\)'), '')
          .trim();

      final match = RegExp(
        r'(?:GOI Y|GỢI Ý)\s*\d*\s*:?\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(cleaned);

      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty) {
          suggestions.add(name.length > 60 ? name.substring(0, 60) : name);
        }
      }
    }

    return suggestions.take(6).toList();
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw.map((item) => item.toString()).where((item) {
      return item.trim().isNotEmpty;
    }).toList();
  }

  List<String> _mergeLimited(
    List<String> preferred,
    List<String> secondary,
    int limit,
  ) {
    final merged = <String>[];

    for (final value in [...preferred, ...secondary]) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final exists = merged.any(
        (item) => item.toLowerCase() == trimmed.toLowerCase(),
      );
      if (!exists) merged.add(trimmed);
      if (merged.length >= limit) break;
    }

    return merged;
  }
}
