import 'dart:math';
import '../models/user_profile.dart';
import '../models/meal.dart';
import '../models/activity.dart';
import '../models/weight_entry.dart';
import '../models/water_entry.dart';

// --- HÀM HELPER ĐỂ TẠO NGÀY ---
DateTime _getDate(int daysAgo, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
}

// (Giả sử bạn đã import 'user_profile.dart' và các enum)

final UserProfile sampleUserProfile = UserProfile(
  uid: "sample_user_01",
  email: "user@example.com",
  displayName: "Tuấn Kiệt",
  
  // Thông tin sinh trắc học
  dateOfBirth: DateTime(1204, 5, 20), 
  height: 175,
  gender: Gender.male,
  
  // THÊM: Các trường bắt buộc còn thiếu
  currentWeight: 70.0,
  goalWeight: 65.0,
  activityLevel: ActivityLevel.light, // Mức độ hoạt động (ví dụ)

  // Mục tiêu (đã tính toán)
  calorieGoal: 2200,
  proteinGoal: 130,
  carbGoal: 260,
  fatGoal: 70,
);

// --- 2. DỮ LIỆU MÓN ĂN (MEALS) - 78 MÓN / 26 NGÀY ---
final List<Meal> sampleMeals = [
  // Ngày 0 (Hôm nay)
  Meal(id: "1", name: "Phở bò", date: _getDate(0, 7, 30), calories: 450, emoji: "🍜", protein: 30, carbs: 50, fat: 15),
  Meal(id: "2", name: "Bún chả", date: _getDate(0, 12, 30), calories: 550, emoji: "🍲", protein: 20, carbs: 60, fat: 22), // Bữa trưa
  Meal(id: "3", name: "Cơm gà xối mỡ", date: _getDate(0, 19, 15), calories: 650, emoji: "🍚", protein: 25, carbs: 80, fat: 20),

  // Ngày 1
  Meal(id: "4", name: "Bánh mì thịt", date: _getDate(1, 8, 0), calories: 350, emoji: "🥖", protein: 10, carbs: 40, fat: 15),
  Meal(id: "5", name: "Salad cá ngừ", date: _getDate(1, 12, 0), calories: 300, emoji: "🥗", protein: 25, carbs: 10, fat: 15), // Bữa trưa
  Meal(id: "6", name: "Bít tết (Steak bò)", date: _getDate(1, 20, 0), calories: 700, emoji: "🥩", protein: 50, carbs: 10, fat: 50),

  // Ngày 2
  Meal(id: "7", name: "Xôi mặn", date: _getDate(2, 6, 45), calories: 400, emoji: "🍙", protein: 15, carbs: 60, fat: 12),
  Meal(id: "8", name: "Cơm rang dưa bò", date: _getDate(2, 12, 15), calories: 500, emoji: "🍚", protein: 15, carbs: 70, fat: 18), // Bữa trưa
  Meal(id: "9", name: "Salad ức gà", date: _getDate(2, 18, 30), calories: 350, emoji: "🥗", protein: 40, carbs: 10, fat: 18),

  // Ngày 3
  Meal(id: "10", name: "Bún bò Huế", date: _getDate(3, 7, 15), calories: 550, emoji: "🍲", protein: 28, carbs: 55, fat: 20),
  Meal(id: "11", name: "Cơm tấm sườn", date: _getDate(3, 12, 0), calories: 580, emoji: "🍖", protein: 25, carbs: 70, fat: 20), // Bữa trưa
  Meal(id: "12", name: "Mì Ý (Spaghetti)", date: _getDate(3, 19, 0), calories: 600, emoji: "🍝", protein: 22, carbs: 70, fat: 25),

  // Ngày 4
  Meal(id: "13", name: "Trứng ốp la & Bánh mì", date: _getDate(4, 9, 0), calories: 300, emoji: "🍳", protein: 15, carbs: 30, fat: 12),
  Meal(id: "14", name: "Gỏi cuốn (4 cuốn)", date: _getDate(4, 12, 30), calories: 300, emoji: "🌯", protein: 20, carbs: 40, fat: 8), // Bữa trưa
  Meal(id: "15", name: "Pizza Hải sản", date: _getDate(4, 19, 30), calories: 800, emoji: "🍕", protein: 30, carbs: 90, fat: 35),

  // Ngày 5
  Meal(id: "16", name: "Cơm tấm sườn", date: _getDate(5, 7, 0), calories: 580, emoji: "🍖", protein: 25, carbs: 70, fat: 20),
  Meal(id: "17", name: "Sushi (Set 6 miếng)", date: _getDate(5, 13, 0), calories: 350, emoji: "🍣", protein: 15, carbs: 50, fat: 8), // Bữa trưa
  Meal(id: "18", name: "Gỏi cuốn (4 cuốn)", date: _getDate(5, 18, 0), calories: 300, emoji: "🌯", protein: 20, carbs: 40, fat: 8),

  // Ngày 6
  Meal(id: "19", name: "Cà phê sữa", date: _getDate(6, 8, 30), calories: 120, emoji: "☕", protein: 3, carbs: 15, fat: 5),
  Meal(id: "20", name: "Bún bò Huế", date: _getDate(6, 12, 0), calories: 550, emoji: "🍲", protein: 28, carbs: 55, fat: 20), // Bữa trưa
  Meal(id: "21", name: "Thịt kho trứng", date: _getDate(6, 19, 0), calories: 500, emoji: "🥘", protein: 28, carbs: 50, fat: 20),

  // Ngày 7
  Meal(id: "22", name: "Hủ tiếu", date: _getDate(7, 7, 45), calories: 400, emoji: "🍜", protein: 20, carbs: 50, fat: 15),
  Meal(id: "23", name: "Cơm gà xối mỡ", date: _getDate(7, 12, 15), calories: 650, emoji: "🍚", protein: 25, carbs: 80, fat: 20), // Bữa trưa
  Meal(id: "24", name: "Sushi (Set 6 miếng)", date: _getDate(7, 19, 30), calories: 350, emoji: "🍣", protein: 15, carbs: 50, fat: 8),

  // Ngày 8
  Meal(id: "25", name: "Bò kho", date: _getDate(8, 8, 0), calories: 480, emoji: "🍲", protein: 30, carbs: 40, fat: 20),
  Meal(id: "26", name: "Bánh xèo", date: _getDate(8, 12, 30), calories: 400, emoji: "🥞", protein: 15, carbs: 40, fat: 20), // Bữa trưa
  Meal(id: "27", name: "Cơm chiên dương châu", date: _getDate(8, 18, 30), calories: 500, emoji: "🍚", protein: 15, carbs: 70, fat: 18),

  // Ngày 9
  Meal(id: "28", name: "Phở gà", date: _getDate(9, 7, 0), calories: 420, emoji: "🍜", protein: 28, carbs: 48, fat: 12),
  Meal(id: "29", name: "Salad ức gà", date: _getDate(9, 12, 0), calories: 350, emoji: "🥗", protein: 40, carbs: 10, fat: 18), // Bữa trưa
  Meal(id: "30", name: "Bánh tráng trộn", date: _getDate(9, 16, 0), calories: 300, emoji: "🥡", protein: 8, carbs: 40, fat: 10),

  // Ngày 10
  Meal(id: "31", name: "Bánh mì ốp la", date: _getDate(10, 8, 15), calories: 320, emoji: "🍳", protein: 14, carbs: 30, fat: 15),
  Meal(id: "32", name: "Bún chả", date: _getDate(10, 12, 30), calories: 550, emoji: "🍲", protein: 20, carbs: 60, fat: 22), // Bữa trưa
  Meal(id: "33", name: "Cơm sườn bì chả", date: _getDate(10, 19, 0), calories: 600, emoji: "🍖", protein: 28, carbs: 75, fat: 22),

  // Ngày 11
  Meal(id: "34", name: "Ngũ cốc & Sữa", date: _getDate(11, 7, 0), calories: 300, emoji: "🥣", protein: 10, carbs: 55, fat: 5), // Thay thế
  Meal(id: "35", name: "Salad cá ngừ", date: _getDate(11, 12, 0), calories: 300, emoji: "🥗", protein: 25, carbs: 10, fat: 15),
  Meal(id: "36", name: "Canh chua cá", date: _getDate(11, 19, 15), calories: 300, emoji: "🐟", protein: 20, carbs: 30, fat: 10),

  // Ngày 12
  Meal(id: "37", name: "Bún chả", date: _getDate(12, 7, 30), calories: 550, emoji: "🍲", protein: 20, carbs: 60, fat: 22), // Thay thế
  Meal(id: "38", name: "Cơm gà xối mỡ", date: _getDate(12, 12, 30), calories: 650, emoji: "🍚", protein: 25, carbs: 80, fat: 20), // Bữa trưa
  Meal(id: "39", name: "Bít tết (Steak bò)", date: _getDate(12, 20, 0), calories: 700, emoji: "🥩", protein: 50, carbs: 10, fat: 50),

  // Ngày 13
  Meal(id: "40", name: "Cơm tấm sườn", date: _getDate(13, 7, 30), calories: 580, emoji: "🍖", protein: 25, carbs: 70, fat: 20),
  Meal(id: "41", name: "Bánh mì que", date: _getDate(13, 12, 0), calories: 180, emoji: "🥖", protein: 5, carbs: 25, fat: 6), // Bữa trưa
  Meal(id: "42", name: "Trà sữa", date: _getDate(13, 15, 0), calories: 350, emoji: "🥤", protein: 2, carbs: 50, fat: 15),

  // Ngày 14
  Meal(id: "43", name: "Phở bò", date: _getDate(14, 8, 0), calories: 450, emoji: "🍜", protein: 30, carbs: 50, fat: 15),
  Meal(id: "44", name: "Cơm chiên dương châu", date: _getDate(14, 12, 30), calories: 500, emoji: "🍚", protein: 15, carbs: 70, fat: 18), // Bữa trưa
  Meal(id: "45", name: "Thịt kho trứng", date: _getDate(14, 19, 0), calories: 500, emoji: "🥘", protein: 28, carbs: 50, fat: 20),

  // Ngày 15
  Meal(id: "46", name: "Bánh cuốn", date: _getDate(15, 7, 0), calories: 300, emoji: "🥟", protein: 10, carbs: 45, fat: 8),
  Meal(id: "47", name: "Bánh mì thịt", date: _getDate(15, 12, 0), calories: 350, emoji: "🥖", protein: 10, carbs: 40, fat: 15), // Bữa trưa
  Meal(id: "48", name: "Lẩu Thái", date: _getDate(15, 19, 30), calories: 800, emoji: "🔥", protein: 40, carbs: 80, fat: 35),

  // Ngày 16
  Meal(id: "49", name: "Cà phê đen", date: _getDate(16, 7, 0), calories: 5, emoji: "☕", protein: 0, carbs: 1, fat: 0), // Thay thế
  Meal(id: "50", name: "Cơm gà xối mỡ", date: _getDate(16, 12, 0), calories: 650, emoji: "🍚", protein: 25, carbs: 80, fat: 20),
  Meal(id: "51", name: "Salad trộn", date: _getDate(16, 19, 0), calories: 200, emoji: "🥗", protein: 5, carbs: 15, fat: 12),

  // Ngày 17
  Meal(id: "52", name: "Bánh mì que", date: _getDate(17, 9, 0), calories: 180, emoji: "🥖", protein: 5, carbs: 25, fat: 6),
  Meal(id: "53", name: "Bò kho", date: _getDate(17, 12, 30), calories: 480, emoji: "🍲", protein: 30, carbs: 40, fat: 20), // Bữa trưa
  Meal(id: "54", name: "Phở bò (tái)", date: _getDate(17, 18, 30), calories: 430, emoji: "🍜", protein: 28, carbs: 50, fat: 12),

  // Ngày 18
  Meal(id: "55", name: "Trà đào", date: _getDate(18, 10, 0), calories: 150, emoji: "🍑", protein: 1, carbs: 35, fat: 0), // Thay thế
  Meal(id: "56", name: "Chè (Ly)", date: _getDate(18, 15, 0), calories: 300, emoji: "🍧", protein: 5, carbs: 60, fat: 4),
  Meal(id: "57", name: "Pizza", date: _getDate(18, 19, 30), calories: 800, emoji: "🍕", protein: 30, carbs: 90, fat: 35),

  // Ngày 19
  Meal(id: "58", name: "Bún bò Huế", date: _getDate(19, 7, 30), calories: 550, emoji: "🍲", protein: 28, carbs: 55, fat: 20),
  Meal(id: "59", name: "Salad cá ngừ", date: _getDate(19, 12, 0), calories: 300, emoji: "🥗", protein: 25, carbs: 10, fat: 15), // Bữa trưa
  Meal(id: "60", name: "Bánh xèo", date: _getDate(19, 19, 0), calories: 400, emoji: "🥞", protein: 15, carbs: 40, fat: 20),

  // Ngày 20
  Meal(id: "61", name: "Cơm sườn", date: _getDate(20, 8, 0), calories: 580, emoji: "🍖", protein: 25, carbs: 70, fat: 20),
  Meal(id: "62", name: "Bánh tráng trộn", date: _getDate(20, 15, 0), calories: 300, emoji: "🥡", protein: 8, carbs: 40, fat: 10), // Bữa trưa
  Meal(id: "63", name: "Thịt kho trứng", date: _getDate(20, 18, 45), calories: 500, emoji: "🥘", protein: 28, carbs: 50, fat: 20),

  // Ngày 21
  Meal(id: "64", name: "Hủ tiếu", date: _getDate(21, 7, 15), calories: 400, emoji: "🍜", protein: 20, carbs: 50, fat: 15),
  Meal(id: "65", name: "Cơm chiên dương châu", date: _getDate(21, 12, 30), calories: 500, emoji: "🍚", protein: 15, carbs: 70, fat: 18), // Bữa trưa
  Meal(id: "66", name: "Gỏi cuốn (4 cuốn)", date: _getDate(21, 19, 0), calories: 300, emoji: "🌯", protein: 20, carbs: 40, fat: 8),

  // Ngày 22
  Meal(id: "67", name: "Trứng ốp la", date: _getDate(22, 8, 30), calories: 200, emoji: "🍳", protein: 12, carbs: 2, fat: 15),
  Meal(id: "68", name: "Bánh mì thịt", date: _getDate(22, 12, 0), calories: 350, emoji: "🥖", protein: 10, carbs: 40, fat: 15), // Bữa trưa
  Meal(id: "69", name: "Cơm gà xối mỡ", date: _getDate(22, 19, 0), calories: 650, emoji: "🍚", protein: 25, carbs: 80, fat: 20),

  // Ngày 23
  Meal(id: "70", name: "Bánh mì thịt", date: _getDate(23, 7, 0), calories: 350, emoji: "🥖", protein: 10, carbs: 40, fat: 15),
  Meal(id: "71", name: "Phở bò", date: _getDate(23, 12, 30), calories: 450, emoji: "🍜", protein: 30, carbs: 50, fat: 15), // Bữa trưa
  Meal(id: "72", name: "Bít tết (Steak bò)", date: _getDate(23, 19, 30), calories: 700, emoji: "🥩", protein: 50, carbs: 10, fat: 50),

  // Ngày 24
  Meal(id: "73", name: "Cà phê sữa", date: _getDate(24, 8, 0), calories: 120, emoji: "☕", protein: 3, carbs: 15, fat: 5), // Thay thế
  Meal(id: "74", name: "Salad ức gà", date: _getDate(24, 12, 0), calories: 350, emoji: "🥗", protein: 40, carbs: 10, fat: 18),
  Meal(id: "75", name: "Mì Ý (Spaghetti)", date: _getDate(24, 19, 0), calories: 600, emoji: "🍝", protein: 22, carbs: 70, fat: 25),

  // Ngày 25
  Meal(id: "76", name: "Xôi mặn", date: _getDate(25, 7, 0), calories: 400, emoji: "🍙", protein: 15, carbs: 60, fat: 12),
  Meal(id: "77", name: "Hủ tiếu", date: _getDate(25, 12, 15), calories: 400, emoji: "🍜", protein: 20, carbs: 50, fat: 15), // Bữa trưa
  Meal(id: "78", name: "Bún chả", date: _getDate(25, 18, 30), calories: 550, emoji: "🍲", protein: 20, carbs: 60, fat: 22),
];

// --- 3. DỮ LIỆU CÂN NẶNG (WEIGHT) ---
final List<WeightEntry> sampleWeightEntries = [
  WeightEntry(id: "w1", date: _getDate(25, 6, 0), weight: 72.5), // Bắt đầu
  WeightEntry(id: "w2", date: _getDate(20, 6, 0), weight: 72.0),
  WeightEntry(id: "w3", date: _getDate(14, 6, 0), weight: 71.8),
  WeightEntry(id: "w4", date: _getDate(7, 6, 0), weight: 71.0),
  WeightEntry(id: "w5", date: _getDate(1, 6, 0), weight: 70.5), // Hiện tại
];

// --- 4. DỮ LIỆU UỐNG NƯỚC (WATER) ---
final List<WaterEntry> sampleWaterEntries = [
  // Hôm nay (0)
  WaterEntry(id: "wt1", date: _getDate(0, 8, 0), amountInMl: 300),
  WaterEntry(id: "wt2", date: _getDate(0, 10, 30), amountInMl: 250),
  WaterEntry(id: "wt3", date: _getDate(0, 14, 0), amountInMl: 500),
  WaterEntry(id: "wt4", date: _getDate(0, 17, 0), amountInMl: 250),
  // Hôm qua (1)
  WaterEntry(id: "wt5", date: _getDate(1, 9, 0), amountInMl: 500),
  WaterEntry(id: "wt6", date: _getDate(1, 15, 0), amountInMl: 500),
];

// --- 5. DỮ LIỆU TẬP LUYỆN (ACTIVITY) ---
final List<Activity> sampleActivities = [
  Activity(id: "a1", name: "Chạy bộ", date: _getDate(1, 17, 0), durationInMinutes: 30, caloriesBurned: 250),
  Activity(id: "a2", name: "Tập Gym", date: _getDate(3, 18, 0), durationInMinutes: 60, caloriesBurned: 400),
  Activity(id: "a3", name: "Đi bộ", date: _getDate(4, 8, 0), durationInMinutes: 45, caloriesBurned: 150),
  Activity(id: "a4", name: "Chạy bộ", date: _getDate(5, 17, 0), durationInMinutes: 30, caloriesBurned: 250),
  Activity(id: "a5", name: "Tập Gym", date: _getDate(7, 18, 0), durationInMinutes: 60, caloriesBurned: 400),
  Activity(id: "a6", name: "Chạy bộ", date: _getDate(9, 17, 0), durationInMinutes: 30, caloriesBurned: 250),
  Activity(id: "a7", name: "Tập Gym", date: _getDate(11, 18, 0), durationInMinutes: 60, caloriesBurned: 400),
  Activity(id: "a8", name: "Đi bộ", date: _getDate(13, 8, 0), durationInMinutes: 45, caloriesBurned: 150),
  Activity(id: "a9", name: "Chạy bộ", date: _getDate(15, 17, 0), durationInMinutes: 30, caloriesBurned: 250),
  Activity(id: "a10", name: "Tập Gym", date: _getDate(17, 18, 0), durationInMinutes: 60, caloriesBurned: 400),
  Activity(id: "a11", name: "Chạy bộ", date: _getDate(19, 17, 0), durationInMinutes: 30, caloriesBurned: 250),
  Activity(id: "a12", name: "Tập Gym", date: _getDate(21, 18, 0), durationInMinutes: 60, caloriesBurned: 400),
  Activity(id: "a13", name: "Đi bộ", date: _getDate(23, 8, 0), durationInMinutes: 45, caloriesBurned: 150),
  Activity(id: "a14", name: "Chạy bộ", date: _getDate(25, 17, 0), durationInMinutes: 30, caloriesBurned: 250),
];