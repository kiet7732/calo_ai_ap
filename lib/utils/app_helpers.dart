
import 'package:cloud_firestore/cloud_firestore.dart';

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

class AppHelpers {
  /// Xử lý Ngày tháng (Chấp nhận cả String và Timestamp)
  static DateTime parseDate(dynamic val, {DateTime? fallback}) {
    if (val is Timestamp) return val.toDate();
    if (val is String) {
      return DateTime.tryParse(val) ?? (fallback ?? DateTime(2000, 1, 1));
    }
    return fallback ?? DateTime(2000, 1, 1);
  }

  /// Xử lý Số (Chấp nhận cả int và double)
  static int parseInt(dynamic val) => (val is num) ? val.toInt() : 0;
  static double parseDouble(dynamic val) => (val is num) ? val.toDouble() : 0.0;

  /// Xử lý Enum (Không phân biệt hoa thường)
  /// Ví dụ: AppHelpers.parseEnum(data['gender'], Gender.values, Gender.other)
  static T parseEnum<T extends Enum>(dynamic val, List<T> values, T defaultValue) {
    final String s = (val ?? '').toString().toLowerCase();
    return values.firstWhere(
      (e) => e.name.toLowerCase() == s,
      orElse: () => defaultValue,
    );
  }
}