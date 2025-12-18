import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';

/// Hàm helper để hiển thị BottomSheet chọn mức độ hoạt động
void showActivityLevelBottomSheet(BuildContext context, {required Function(ActivityLevel) onSelect}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ActivityLevelBottomSheet(onSelect: onSelect),
  );
}

class ActivityLevelBottomSheet extends StatelessWidget {
  final Function(ActivityLevel) onSelect;

  const ActivityLevelBottomSheet({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // Lấy UserProvider để đọc dữ liệu hiện tại
    final userProvider = context.read<UserProvider>();
    final currentLevel = userProvider.userProfile?.activityLevel;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // Chiếm 60% màn hình
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 238, 87, 87),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Chọn mức độ hoạt động",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildActivityChoiceCard(context, "Ít vận động", "Ngồi văn phòng, ít hoặc không tập thể dục.", Icons.airline_seat_recline_normal_rounded, Colors.blue, ActivityLevel.sedentary, currentLevel, userProvider),
                const SizedBox(height: 12),
                _buildActivityChoiceCard(context, "Vận động nhẹ", "Tập thể dục nhẹ 1-3 ngày/tuần.", Icons.directions_walk_rounded, const Color.fromARGB(255, 102, 0, 197), ActivityLevel.light, currentLevel, userProvider),
                const SizedBox(height: 12),
                _buildActivityChoiceCard(context, "Vận động vừa", "Tập thể dục vừa phải 3-5 ngày/tuần.", Icons.directions_run_rounded, Colors.orange, ActivityLevel.moderate, currentLevel, userProvider),
                const SizedBox(height: 12),
                _buildActivityChoiceCard(context, "Vận động nhiều", "Tập luyện cường độ cao 6-7 ngày/tuần.", Icons.fitness_center_rounded, Colors.red, ActivityLevel.veryActive, currentLevel, userProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChoiceCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    ActivityLevel level,
    ActivityLevel? currentLevel,
    UserProvider userProvider,
  ) {
    final isSelected = currentLevel == level;
    const primaryColor = Color(0xFFA8D15D);

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context); // Đóng sheet trước
        if (!isSelected) {
          onSelect(level);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: isSelected ? primaryColor : iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: primaryColor),
          ],
        ),
      ),
    );
  }
}