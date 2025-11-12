//lib/models/activity.dart
class Activity {
  final String id;
  final String name; // Tên hoạt động (ví dụ: "Chạy bộ")
  final DateTime date;
  final int durationInMinutes; // Thời gian (phút)
  final int caloriesBurned; // Calo đã đốt

  const Activity({
    required this.id,
    required this.name,
    required this.date,
    required this.durationInMinutes,
    required this.caloriesBurned,
  });
}