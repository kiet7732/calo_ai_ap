import 'package:cloud_firestore/cloud_firestore.dart';

class PersistedChatMessage {
  PersistedChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  String get apiRole => isUser ? 'user' : 'model';

  Map<String, dynamic> toGeminiContent() {
    return {
      'role': apiRole,
      'parts': [
        {'text': text},
      ],
    };
  }

  factory PersistedChatMessage.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final timestamp = data['createdAt'];
    return PersistedChatMessage(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      isUser: data['isUser'] == true,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}

class ChatSessionService {
  ChatSessionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _sessionRef(
    String uid,
    String sessionId,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chat_sessions')
        .doc(sessionId);
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String uid,
    String sessionId,
  ) {
    return _sessionRef(uid, sessionId).collection('messages');
  }

  Future<String> createSession(String uid, {String? title}) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _sessionRef(uid, sessionId);
    await ref.set({
      'title': title ?? 'Tro ly dinh duong',
      'summary': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return sessionId;
  }

  Future<String> loadSummary(String uid, String sessionId) async {
    final snap = await _sessionRef(uid, sessionId).get();
    return (snap.data()?['summary'] ?? '').toString();
  }

  Future<String> loadTitle(String uid, String sessionId) async {
    final snap = await _sessionRef(uid, sessionId).get();
    return (snap.data()?['title'] ?? 'Tro ly dinh duong').toString();
  }

  Future<List<PersistedChatMessage>> loadRecentMessages(
    String uid,
    String sessionId, {
    int limit = 24,
  }) async {
    final snap = await _messagesRef(
      uid,
      sessionId,
    ).orderBy('createdAt').limitToLast(limit).get();

    return snap.docs.map(PersistedChatMessage.fromDoc).toList();
  }

  Future<String> saveMessage({
    required String uid,
    required String sessionId,
    required String text,
    required bool isUser,
  }) async {
    final doc = await _messagesRef(uid, sessionId).add({
      'text': text,
      'isUser': isUser,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sessionRef(
      uid,
      sessionId,
    ).set({'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    return doc.id;
  }

  Future<void> deleteMessage({
    required String uid,
    required String sessionId,
    required String messageId,
  }) async {
    await _messagesRef(uid, sessionId).doc(messageId).delete();
  }

  Future<void> deleteMessages({
    required String uid,
    required String sessionId,
    required List<String> messageIds,
  }) async {
    if (messageIds.isEmpty) return;

    final batch = _firestore.batch();
    for (final messageId in messageIds) {
      batch.delete(_messagesRef(uid, sessionId).doc(messageId));
    }
    await batch.commit();
  }

  Future<void> updateSummary({
    required String uid,
    required String sessionId,
    required String summary,
  }) async {
    await _sessionRef(uid, sessionId).set({
      'summary': summary,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateTitle({
    required String uid,
    required String sessionId,
    required String title,
  }) async {
    await _sessionRef(uid, sessionId).set({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
