// lib/widgets/calorie_progress_ring.dart

import 'package:flutter/material.dart';

class CalorieProgressRing extends StatelessWidget {
  final double consumed;
  final double goal;
  
  // Màu chủ đạo bạn chọn
  static const Color primaryColor = Color(0xFFA8D15D);

  const CalorieProgressRing({
    required this.consumed,
    required this.goal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = goal - consumed;
    final double progress = consumed / goal;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: TweenAnimationBuilder<double>(
              // Tạo hiệu ứng chuyển động mượt mà cho vòng tròn
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: 16,
                  color: primaryColor,
                  backgroundColor: const Color(0xFFE5E7EB),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                consumed.toString(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const Text('kcal', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                remaining > 0 ? 'Còn ${remaining.toStringAsFixed(1)} kcal' : 'Vượt ${(-remaining).toStringAsFixed(1)} kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  // Đổi màu nếu vượt mục tiêu
                  color: remaining > 0 ? primaryColor : Colors.red.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}