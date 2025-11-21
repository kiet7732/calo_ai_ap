import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các model và provider cần thiết
import '../models/meal.dart';
import '../providers/history_provider.dart';
import '../widgets/history/daily_summary_card.dart';
import '../widgets/history/meal_history_list_view.dart';
import '../widgets/history/date_navigation_bar.dart';

class HistoryScreen extends StatefulWidget { // Đổi tên thành HistoryView nếu muốn, nhưng giữ HistoryScreen cũng không sao
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

  // Hàm helper để kiểm tra hai ngày có giống nhau không
  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ provider
    final historyProvider = context.watch<HistoryProvider>();
    final allMeals = historyProvider.allMeals;

    // Lọc danh sách bữa ăn dựa trên ngày đã chọn
    final dailyMeals =
        allMeals.where((meal) => _isSameDay(meal.date, _selectedDate)).toList();

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
          DailySummaryCard(dailyMeals: dailyMeals, selectedDate: _selectedDate),
          Expanded(child: MealListView(dailyMeals: dailyMeals)),
        ],
    );
  }
}
