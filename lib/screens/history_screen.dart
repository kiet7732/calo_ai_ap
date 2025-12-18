import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; //Thêm import cho DateFormat

// Import các model và provider cần thiết
import '../models/daily_stat.dart';
import '../models/meal_entry.dart';
import '../providers/history_provider.dart';
import '../widgets/history/daily_summary_card.dart';
import '../widgets/history/date_navigation_bar.dart';
import '../widgets/meal_item_tile.dart';
import '../models/meal.dart';
import '../providers/today_stats_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  // Quản lý ngày đang được chọn, khởi tạo là ngày hôm nay
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ngày được chọn là hôm nay (loại bỏ thông tin giờ, phút)
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  @override
  Widget build(BuildContext context) {
    final bool isToday = _isSameDay(_selectedDate, DateTime.now());
    DailyStat statForDisplay;

    if (isToday) {
      // Nếu là hôm nay, lấy dữ liệu tổng từ TodayStatsProvider
      final todayStats = context.watch<TodayStatsProvider>();
      statForDisplay = DailyStat(
        date: _selectedDate,
        totalCalories: todayStats.consumedCalories,
        totalProtein: todayStats.consumedProtein,
        totalCarbs: todayStats.consumedCarbs,
        totalFat: todayStats.consumedFat,
      );
    } else {
      // Nếu là ngày trong quá khứ, lấy từ HistoryProvider
      final dailyStats = context.watch<HistoryProvider>().dailyStats;
      statForDisplay = dailyStats.firstWhere((stat) => stat.date == _selectedDate, orElse: () => DailyStat(date: _selectedDate, totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0));
    }

    return Column(
        children: [
          // SỬ DỤNG WIDGET ĐÃ TÁCH
          DateNavigationBar(
            selectedDate: _selectedDate,
            onDateChanged: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          ),
          DailySummaryCard(dailyStat: statForDisplay),
          //Dùng StreamBuilder để tải danh sách bữa ăn chi tiết cho ngày đã chọn
          Expanded(child: _buildMealListForDate(_selectedDate)),
        ],
    );
  }

  /// Widget này sử dụng StreamBuilder để lắng nghe sub-collection 'meals'
  /// của một ngày cụ thể trong 'daily_stats_meals'.
  Widget _buildMealListForDate(DateTime date) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Vui lòng đăng nhập để xem lịch sử."));
    }

    final bool isToday = _isSameDay(date, DateTime.now());
    final String dateString = DateFormat('yyyy-MM-dd').format(date);

    //xây dựng stream một cách linh hoạt dựa trên ngày được chọn
    late final Stream<QuerySnapshot> mealStream;

    if (isToday) {
      // Nếu là hôm nay, lắng nghe trực tiếp từ collection 'current_meals'
      mealStream = FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('current_meals')
          .orderBy('createdAt', descending: false)
          .snapshots();
    } else {
      // Nếu là ngày trong quá khứ, lắng nghe từ sub-collection 'meals' của ngày đó
      mealStream = FirebaseFirestore.instance
          .collection('users').doc(user.uid)
          .collection('daily_stats_meals').doc(dateString)
          .collection('meals')
          .orderBy('createdAt', descending: false)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: mealStream, // Sử dụng biến stream đã được tạo
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có dữ liệu cho ngày này."));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Đã xảy ra lỗi khi tải dữ liệu."));
        }

        final mealEntries = snapshot.data!.docs.map((doc) => MealEntry.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)).toList();

        // Sử dụng lại logic hiển thị từ today_screen
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: mealEntries.expand((entry) => entry.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MealItemTile(
                meal: Meal(
                  id: entry.id, name: item.name, date: entry.createdAt,
                  calories: item.calories.toInt(), emoji: item.idIcon, protein: item.protein.toInt(),
                  carbs: item.carbs.toInt(), fat: item.fat.toInt()
                ),
              ),
            );
          })).toList(),
        );
      },
    );
  }
}
