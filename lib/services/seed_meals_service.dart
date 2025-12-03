import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/sample_meals.dart'; // Import file chứa sampleMeals của bạn
import '../models/meal.dart'; // Import model Meal gốc để đọc dữ liệu mẫu

class SeedMealsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Hàm chính để đẩy dữ liệu món ăn lên Firestore
  Future<void> seedMealsToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ Lỗi: Chưa đăng nhập!");
      return;
    }

    print("⏳ Đang xử lý và đẩy 78 món ăn mẫu lên Firestore...");
    final batch = _firestore.batch();

    // 1. Nhóm các món ăn theo Ngày (yyyy-MM-dd)
    // Map<String, List<Meal>>
    final Map<String, List<Meal>> mealsByDay = {};

    for (var meal in sampleMeals) {
      final dateKey = DateFormat('yyyy-MM-dd').format(meal.date);
      if (!mealsByDay.containsKey(dateKey)) {
        mealsByDay[dateKey] = [];
      }
      mealsByDay[dateKey]!.add(meal);
    }

    // 2. Xử lý từng ngày
    for (var dateKey in mealsByDay.keys) {
      final dayMeals = mealsByDay[dateKey]!;
      
      // Tính tổng dinh dưỡng của cả ngày
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      // 2a. Nhóm các món trong ngày theo Bữa (Breakfast/Lunch/Dinner)
      // Map<String, List<Meal>> -> Key là mealType
      final Map<String, List<Meal>> mealsBySession = {
        'breakfast': [],
        'lunch': [],
        'dinner': [],
        'snack': [],
      };

      for (var meal in dayMeals) {
        // Cộng dồn tổng ngày
        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFat += meal.fat;

        // Phân loại bữa dựa vào giờ
        final hour = meal.date.hour;
        String mealType = 'snack';
        if (hour >= 5 && hour < 11) mealType = 'breakfast';
        else if (hour >= 11 && hour < 16) mealType = 'lunch';
        else if (hour >= 16 && hour < 22) mealType = 'dinner';

        mealsBySession[mealType]!.add(meal);
      }

      // 3. Tạo Document Thống kê Ngày (daily_stats_meals/{date})
      final dailyStatRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_stats_meals')
          .doc(dateKey);

      // Lưu tổng kết ngày
      batch.set(dailyStatRef, {
        'date': Timestamp.fromDate(dayMeals.first.date), // Lấy ngày của món đầu tiên
        'totalCalories': totalCalories,
        'totalProtein': totalProtein,
        'totalCarbs': totalCarbs,
        'totalFat': totalFat,
      }, SetOptions(merge: true)); // Merge để không mất dữ liệu khác nếu có

      // 4. Tạo các MealEntry (Bữa ăn) trong sub-collection 'meals'
      for (var mealType in mealsBySession.keys) {
        final sessionMeals = mealsBySession[mealType]!;
        
        if (sessionMeals.isNotEmpty) {
          final mealEntryRef = dailyStatRef.collection('meals').doc();
          
          // Chuyển đổi list Meal thành list Map (items)
          final List<Map<String, dynamic>> itemsList = sessionMeals.map((m) {
            return {
              'name': m.name,
              'calories': m.calories,
              'protein': m.protein,
              'carbs': m.carbs,
              'fat': m.fat,
              'quantity': 1,
              'unit': 'phần',
              'idIcon': m.emoji,
            };
          }).toList();

          // Lưu MealEntry (Ví dụ: Bữa Sáng gồm Phở + Cà phê)
          batch.set(mealEntryRef, {
            'mealType': mealType,
            'createdAt': Timestamp.fromDate(sessionMeals.first.date),
            'items': itemsList, // Mảng chứa các món ăn
          });
        }
      }
    }

    // 5. Thực thi Batch
    await batch.commit();
    print("✅ Đã đẩy xong lịch sử ăn uống (26 ngày) lên Firestore!");
  }
}