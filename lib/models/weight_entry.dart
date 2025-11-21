//lib/models/weight_entry.dart
class WeightEntry {
  final String id;
  final DateTime date;  // Ngày ghi nhận
  final double weight;  // Cân nặng (ví dụ: 70.5 kg)

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
  });
}