//lib /widgets/macro_history_card.dart
import 'package:flutter/material.dart';

/// Một widget hiển thị một chỉ số dinh dưỡng (macro) với icon, giá trị và nhãn.
class MacroHistoryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const MacroHistoryItem({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(
                text: value.split(' ')[0], // Lấy phần số
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              TextSpan(
                text: ' ${value.split(' ')[1]}', // Lấy phần đơn vị
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
