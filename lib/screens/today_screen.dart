// lib/screens/today_screen.dart
import 'package:flutter/material.dart';

import '../widgets/calorie_progress_ring.dart';
import '../widgets/macro_card.dart';
import '../widgets/meal_item_tile.dart';

import '../models/meal.dart';
import '../models/meal_entry.dart';
import '../providers/today_stats_provider.dart';
import 'package:provider/provider.dart';

class TodayScreen extends StatelessWidget {
  // Hàm callback để yêu cầu cha (MainNavigatorScreen) chuyển tab
  final Function(int) onNavigate;

  const TodayScreen({super.key, required this.onNavigate});

  // Dữ liệu mẫu
  static const Color primaryColor = Color(0xFFA8D15D);

  String getCurrentDate() {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final now = DateTime.now();
    return '${days[now.weekday % 7]}, ${now.day} tháng ${now.month}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước an toàn (safe area) trên cùng (chỗ tai thỏ, đồng hồ)
    final double topPadding = MediaQuery.of(context).padding.top;

    final stats = context.watch<TodayStatsProvider>();
    final List<MealEntry> todayMealEntries = stats.todayMealEntries;

   print(" UI UPDATE: Có ${todayMealEntries.length} bữa ăn.");
    for(var e in todayMealEntries) {
       print("   - Bữa ${e.id}: ${e.items.length} món");
    }

    
    return Scaffold(
      // Đặt màu nền chung cho khu vực cuộn
      backgroundColor: const Color(0xFFF9F9F9),                         //nen mau

      // SỬ DỤNG STACK ĐỂ XẾP CHỒNG NỘI DUNG
      body: Stack(
        children: [
          // LỚP 1: NỀN XANH LÁ (HEADER)
          Container(
            height: 300, // Chiều cao của vùng nền xanh
            decoration: const BoxDecoration(
              color: primaryColor,
              // thêm hình ảnh sóng (wavy) ở đây 
              // image: DecorationImage(
              //   image: AssetImage('assets/images/header_wave.png'),
              //   fit: BoxFit.cover,
              // ),
            ),
          ),

          // LỚP 2: NỘI DUNG CUỘN (SCROLLABLE CONTENT)
          SingleChildScrollView(
            // Thêm padding dưới cùng để không bị BottomNavigationBar che khuất
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- AppBar Tùy chỉnh (Nằm trên nền xanh) ---
                Padding(
                  // Thêm padding cho thanh trạng thái (status bar)
                  padding: EdgeInsets.fromLTRB(16, topPadding, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hôm nay',
                        //Đổi màu chữ thành TRẮNG để nổi bật trên nền xanh
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // ĐỔI MÀU
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          //Dùng màu trắng mờ cho nền avatar
                          color: Colors.white.withOpacity(0.3), // ĐỔI MÀU
                        ),
                        //Đổi màu icon thành TRẮNG
                        child: const Icon(
                          Icons.person,
                          size: 22,
                          color: Colors.white,
                        ), // ĐỔI MÀU
                      ),
                    ],
                  ),
                ),

                // --- Nội dung chính của màn hình ---
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Thẻ Thống kê chính (Nằm đè lên nền xanh) ---
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Ngày tháng
                            Center(
                              child: Text(
                                getCurrentDate(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(
                                    255,
                                    0,
                                    0,
                                    0,
                                  ), // ĐỔI MÀU
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // SỬ DỤNG WIDGET: Biểu đồ Tiến độ Calo
                            CalorieProgressRing(
                              consumed: stats.consumedCalories,
                              goal: stats.calorieGoal.toDouble(),
                            ),
                            const SizedBox(height: 32),
                            // SỬ DỤNG WIDGET: Thẻ Dinh dưỡng (Macro Cards)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: MacroCard(
                                    label: "Protein",
                                    current: stats.consumedProtein,
                                    goal: stats.proteinGoal.toDouble(),
                                    unit: "g",
                                    color: const Color(0xFF6C63FF),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MacroCard(
                                    label: "Carb",
                                    current: stats.consumedCarbs,
                                    goal: stats.carbGoal.toDouble(),
                                    unit: "g",
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      153,
                                      0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MacroCard(
                                    label: "Fat",
                                    current: stats.consumedFat,
                                    goal: stats.fatGoal.toDouble(),
                                    unit: "g",
                                    color: const Color.fromARGB(255, 255, 0, 0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tiêu đề "Gần đây"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gần đây',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Gọi hàm callback để chuyển đến tab Nhật ký (index = 1)
                              // mà không cần push màn hình mới.
                              onNavigate(2);
                            },
                            child: const Text(
                              'Xem tất cả',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // SỬ DỤNG WIDGET: Danh sách Món ăn Gần đây
                      Column(
                        children:
                            todayMealEntries
                                .take(5)
                                .expand((entry) => entry.items.map((item) => (entry, item)))
                                .map((record) {
                                  final entry = record.$1;
                                  final item = record.$2;
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
                                })
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
