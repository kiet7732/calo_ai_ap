import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/sample_meals.dart'; // Import file chứa sampleMeals của bạn
import '../models/meal.dart';

class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> seedCurrentMeals() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("❌ Lỗi: Chưa đăng nhập!");
      return;
    }

    print("⏳ Đang tạo dữ liệu mẫu 'current_meals' cho hôm nay...");
    final batch = _firestore.batch();
    final now = DateTime.now();

    // --- 1. BỮA SÁNG (2 món) ---
    final breakfastRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('current_meals')
        .doc(); // Auto ID

    batch.set(breakfastRef, {
      'mealType': 'breakfast',
      'createdAt': Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 7, 30),
      ), // 7:30 sáng nay
      'items': [
        {
          'name': 'Phở bò tái',
          'calories': 450,
          'protein': 30,
          'carbs': 50,
          'fat': 15,
          'quantity': 1,
          'unit': 'tô',
          'idIcon': '🍜',
        },
        {
          'name': 'Quẩy',
          'calories': 150,
          'protein': 3,
          'carbs': 20,
          'fat': 8,
          'quantity': 2,
          'unit': 'cái',
          'idIcon': '🥖',
        },
      ],
    });

    // --- 2. BỮA TRƯA (1 món) ---
    final lunchRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('current_meals')
        .doc();

    batch.set(lunchRef, {
      'mealType': 'lunch',
      'createdAt': Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 12, 15),
      ), // 12:15 trưa nay
      'items': [
        {
          'name': 'Cơm sườn bì chả',
          'calories': 650,
          'protein': 35,
          'carbs': 80,
          'fat': 25,
          'quantity': 1,
          'unit': 'dĩa',
          'idIcon': '🍛',
        },
      ],
    });

    // --- 3. BỮA XẾ (Snack) ---
    final snackRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('current_meals')
        .doc();

    batch.set(snackRef, {
      'mealType': 'snack',
      'createdAt': Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 16, 0),
      ), // 4:00 chiều nay
      'items': [
        {
          'name': 'Sữa chua',
          'calories': 100,
          'protein': 5,
          'carbs': 15,
          'fat': 2,
          'quantity': 1,
          'unit': 'hộp',
          'idIcon': '🥛',
        },
      ],
    });

    await batch.commit();
    print("✅ Đã tạo xong 3 bữa ăn mẫu cho ngày hôm nay!");
  }
}
