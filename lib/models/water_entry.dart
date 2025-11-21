// lib/models/water_entry.dart
class WaterEntry {
  final String id;
  final DateTime date;      // Ngày giờ ghi nhận
  final int amountInMl; // Lượng nước (ví dụ: 250 ml)

  const WaterEntry({
    required this.id,
    required this.date,
    required this.amountInMl,
  });
}