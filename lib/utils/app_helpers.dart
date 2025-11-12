// lib/utils/app_helpers.dart

/// Trả về chuỗi ngày tháng năm hiện tại theo định dạng "T2, 29 tháng 7, 2024".
String getCurrentDate() {
  const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  final now = DateTime.now();
  // Dùng `now.weekday % 7` để Chủ Nhật (weekday 7) thành index 0
  return '${days[now.weekday % 7]}, ${now.day} tháng ${now.month}, ${now.year}';
}

// Hàm _getTodayOnly để lấy ngày hôm nay (loại bỏ giờ, phút, giây)
DateTime getToday() {
  final DateTime now = DateTime.now(); 
return DateTime(now.year, now.month, now.day, now.hour, now.minute);
} 

