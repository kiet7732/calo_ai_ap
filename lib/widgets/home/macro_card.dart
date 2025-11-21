// lib/widgets/macro_card.dart

import 'package:flutter/material.dart';

class MacroCard extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;

  const MacroCard({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (current / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Màu nền nhạt dựa trên màu chính của thẻ
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current $unit',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '/$goal $unit',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Thêm thanh tiến độ (LinearProgressIndicator)
          LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
