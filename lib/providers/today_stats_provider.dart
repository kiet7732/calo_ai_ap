// lib/providers/today_stats_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';



class TodayStatsProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _goalsSubscription;
  StreamSubscription? _mealsSubscription;
  String? _currentUid;

  // Mục tiêu (Goals)
  int _calorieGoal = 2000;
  int _proteinGoal = 120;
  int _carbGoal = 250;
  int _fatGoal = 70;

  // Hiện tại (Current)
  double _consumedCalories = 0.0;
  double _consumedProtein = 0.0;
  double _consumedCarbs = 0.0;
  double _consumedFat = 0.0;

  // Danh sách các bữa ăn hôm nay
  List<MealEntry> _todayMealEntries = [];

  // Getters
  int get calorieGoal => _calorieGoal;
  int get proteinGoal => _proteinGoal;
  int get carbGoal => _carbGoal;
  int get fatGoal => _fatGoal;

  double get consumedCalories => _consumedCalories;
  double get consumedProtein => _consumedProtein;
  double get consumedCarbs => _consumedCarbs;
  double get consumedFat => _consumedFat;

  List<MealEntry> get todayMealEntries => _todayMealEntries;

  TodayStatsProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _cleanup();
      } else {
        if (_currentUid != user.uid) {
          _currentUid = user.uid;
          initData(user.uid);
        }
      }
    });
  }

  void initData(String uid) {
    _goalsSubscription?.cancel();
    _mealsSubscription?.cancel();

    // Lắng nghe mục tiêu từ `users/{uid}/goals/current`
    _goalsSubscription = _firestore // Lắng nghe mục tiêu (Goals)
        .collection('users')
        .doc(uid)
        .collection('goals')
        .doc('current')
        .snapshots() // Lắng nghe realtime
        .listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _calorieGoal = data['calorieGoal'] ?? 2000;
        _proteinGoal = data['proteinGoal'] ?? 120;
        _carbGoal = data['carbGoal'] ?? 250;
        _fatGoal = data['fatGoal'] ?? 70;
        if (kDebugMode) print("[Provider] Goals updated.");
        notifyListeners();
      }
    });

    // Lắng nghe các bữa ăn của ngày hôm nay từ `current_meals`
    _mealsSubscription = _firestore // Lắng nghe các bữa ăn (Meals)
        .collection('users')
        .doc(uid)
        .collection('current_meals')
        .snapshots() // Lắng nghe realtime
        .listen((snapshot) => _processMealEntries(uid, snapshot.docs));
  }

  Future<void> _processMealEntries(String uid, List<QueryDocumentSnapshot> docs) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    List<MealEntry> todaysEntries = [];
    Map<DateTime, List<MealEntry>> oldEntriesByDate = {};

    print(" Bắt đầu quét ${docs.length} bữa ăn...");

    for (var doc in docs) {
      // --- BẮT ĐẦU VÙNG AN TOÀN ---
      try {
        // Cố gắng đọc dữ liệu
        final entry = MealEntry.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        
        // Nếu đọc thành công thì mới chạy logic tiếp theo
        if (entry.createdAt.isBefore(startOfToday)) {
          final dateKey = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
          oldEntriesByDate.update(dateKey, (list) => list..add(entry), ifAbsent: () => [entry]);
        } else {
          // Kiểm tra xem bữa ăn có món nào không
          if (entry.items.isNotEmpty) {
             todaysEntries.add(entry);
             print("Đã lấy: Bữa ${entry.mealType} (${entry.items.length} món)");
          } else {
             print("Bữa ${doc.id} rỗng (items = []) -> Bỏ qua");
          }
        }
      } catch (e) {
        // --- NẾU CÓ LỖI: Chỉ in ra và BỎ QUA món này ---
        print("LỖI DATA HỎNG tại ID: ${doc.id}");
        print("Lý do: $e");
        continue; 
      }
    }

    // ... (Phần logic Archive cũ giữ nguyên) ...
    if (oldEntriesByDate.isNotEmpty) {
      await _archiveOldMeals(uid, oldEntriesByDate);
    }

    // Sắp xếp lại cho đẹp (Mới nhất lên đầu)
    todaysEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _todayMealEntries = todaysEntries;
    _calculateTodayTotals();
  }

  Future<void> _archiveOldMeals(String uid, Map<DateTime, List<MealEntry>> oldEntriesByDate) async {
    final batch = _firestore.batch();

    oldEntriesByDate.forEach((date, entries) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      double totalCalories = 0.0, totalProtein = 0.0, totalCarbs = 0.0, totalFat = 0.0;

      for (var entry in entries) {
        for (var item in entry.items) {
          totalCalories += item.calories;
          totalProtein += item.protein;
          totalCarbs += item.carbs;
          totalFat += item.fat;
        } // 2. Sao chép bữa ăn vào sub-collection của daily_stats
        final archiveMealRef = _firestore
            .collection('users').doc(uid)
            .collection('daily_stats_meals').doc(dateString)
            .collection('meals').doc(entry.id);
        batch.set(archiveMealRef, entry.toJson());


        // 3. Xóa bữa ăn khỏi `current_meals`
        final currentMealRef = _firestore.collection('users').doc(uid).collection('current_meals').doc(entry.id);
        batch.delete(currentMealRef);
      }

      // 1. Lưu tổng kết vào `daily_stats_meals/{date}`
      final dailyStatRef = _firestore.collection('users').doc(uid).collection('daily_stats_meals').doc(dateString);
      batch.set(dailyStatRef, {
        'totalCalories': totalCalories,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
        'archivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge để không ghi đè nếu đã có
    });

    try {
      await batch.commit();
      if (kDebugMode) print("[Provider] Archiving complete for ${oldEntriesByDate.length} dates.");
    } catch (e) {
      if (kDebugMode) print("[Provider] Error during archiving: $e");
    }
  }

  /// Tính toán lại tổng lượng dinh dưỡng đã tiêu thụ trong ngày hôm nay.
  void _calculateTodayTotals() {
    _consumedCalories = 0.0;
    _consumedProtein = 0.0;
    _consumedCarbs = 0.0;
    _consumedFat = 0.0;

    for (final entry in _todayMealEntries) {
      // Sử dụng getter `totalCalories` đã có trong MealEntry để tính tổng
      // Hoặc cộng dồn từng item như bên dưới
      _consumedCalories += entry.items.fold(0.0, (sum, item) => sum + (item.calories * item.quantity));
      _consumedProtein += entry.items.fold(0.0, (sum, item) => sum + (item.protein * item.quantity));
      _consumedCarbs += entry.items.fold(0.0, (sum, item) => sum + (item.carbs * item.quantity));
      _consumedFat += entry.items.fold(0.0, (sum, item) => sum + (item.fat * item.quantity));
    } // Thông báo cho UI cập nhật
    if (kDebugMode) print("[Provider] Today's totals recalculated.");
    notifyListeners();
  }

  Future<void> addMealEntry(String mealType, List<FoodItem> items) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) print("[Provider] Error: No user logged in to add meal.");
      return;
    }

    final newEntry = MealEntry(
      id: '', // Firestore sẽ tự tạo ID
      mealType: mealType,
      createdAt: DateTime.now(),
      items: items,
    );

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('current_meals')
          .add(newEntry.toJson());
      if (kDebugMode) print("[Provider] Meal entry added successfully for $mealType.");
    } catch (e) {
      if (kDebugMode) print("[Provider] Error adding meal entry: $e");
    }
  }

  /// Dọn dẹp dữ liệu và hủy các stream khi người dùng đăng xuất.
  void _cleanup() {
    _goalsSubscription?.cancel();
    _mealsSubscription?.cancel();
    _currentUid = null;
    _todayMealEntries = [];
    _calorieGoal = 2000;
    _proteinGoal = 120;
    _carbGoal = 250;
    _fatGoal = 70;
    _consumedCalories = 0.0;
    _consumedProtein = 0.0;
    _consumedCarbs = 0.0;
    _consumedFat = 0.0;
    if (kDebugMode) print("[Provider] Cleaned up data and streams.");
    notifyListeners();
  }

  @override
  void dispose() {
    _goalsSubscription?.cancel();
    _mealsSubscription?.cancel();
    super.dispose();
  }
}