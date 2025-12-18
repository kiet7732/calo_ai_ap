// lib/providers/history_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_stat.dart';

class HistoryProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _dailyStatsSubscription;
  String? _currentUid;

  List<DailyStat> _dailyStats = [];

  /// Getter để cung cấp danh sách thống kê ngày cho các provider khác (như ReportProvider).
  List<DailyStat> get dailyStats => _dailyStats;

  HistoryProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _cleanup();
      } else {
        if (_currentUid != user.uid) {
          _currentUid = user.uid;
          _listenToDailyStats(user.uid);
        }
      }
    });
  }

  /// Thiết lập một stream để lắng nghe dữ liệu từ collection `daily_stats_meals`.
  void _listenToDailyStats(String uid) {
    _dailyStatsSubscription?.cancel();

    _dailyStatsSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_stats_meals') 
        // BỎ SẮP XẾP Ở ĐÂY: Không dùng orderBy để tránh yêu cầu index.
        .snapshots()
        .listen((snapshot) {
      _dailyStats = snapshot.docs
          .map((doc) => DailyStat.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      // SẮP XẾP PHÍA CLIENT: Sắp xếp list sau khi đã nhận được từ Firestore.
      // `b.date.compareTo(a.date)` sẽ sắp xếp ngày mới nhất lên đầu.
      _dailyStats.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }, 
    // Xử lý khi mất mạng hoặc lỗi quyền truy cập
    onError: (error) {
      print("Lỗi tải lịch sử: $error");
      _dailyStats = []; // Có thể xóa dữ liệu cũ để tránh hiểu nhầm
      notifyListeners();
    });
  }

  /// Dọn dẹp dữ liệu và hủy stream khi người dùng đăng xuất.
  void _cleanup() {
    _dailyStatsSubscription?.cancel();
    _currentUid = null;
    _dailyStats = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _dailyStatsSubscription?.cancel();
    super.dispose();
  }
}
