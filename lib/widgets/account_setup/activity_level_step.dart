import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../providers/account_setup_provider.dart';
import '../account_setup/step_container.dart';

class ActivityLevelStep extends StatelessWidget {
  const ActivityLevelStep({super.key});

  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountSetupProvider>();
    final activityLevel = provider.userProfile.activityLevel;

    return StepContainer(
      title: "Mức độ hoạt động?",
      child: ListView(
        children: [
          _buildChoiceCard(
            title: "Ít vận động",
            subtitle: "Ngồi văn phòng, ít hoặc không tập thể dục.",
            icon: Icons.airline_seat_recline_normal_rounded,
            iconColor: Colors.blue, // Màu cho icon
            isSelected: activityLevel == ActivityLevel.sedentary,
            onTap: () => context.read<AccountSetupProvider>().updateActivityLevel(ActivityLevel.sedentary),
          ),
          const SizedBox(height: 16),
          _buildChoiceCard(
            title: "Vận động nhẹ",
            subtitle: "Tập thể dục nhẹ 1-3 ngày/tuần.",
            icon: Icons.directions_walk_rounded,
            iconColor: const Color.fromARGB(255, 102, 0, 197), // Màu cho icon
            isSelected: activityLevel == ActivityLevel.light,
            onTap: () => context.read<AccountSetupProvider>().updateActivityLevel(ActivityLevel.light),
          ),
          const SizedBox(height: 16),
          _buildChoiceCard(
            title: "Vận động vừa",
            subtitle: "Tập thể dục vừa phải 3-5 ngày/tuần.",
            icon: Icons.directions_run_rounded,
            iconColor: Colors.orange, // Màu cho icon
            isSelected: activityLevel == ActivityLevel.moderate,
            onTap: () => context.read<AccountSetupProvider>().updateActivityLevel(ActivityLevel.moderate),
          ),
          const SizedBox(height: 16),
          _buildChoiceCard(
            title: "Vận động nhiều",
            subtitle: "Tập luyện cường độ cao 6-7 ngày/tuần.",
            icon: Icons.fitness_center_rounded,
            iconColor: Colors.red, // Màu cho icon
            isSelected: activityLevel == ActivityLevel.veryActive,
            onTap: () => context.read<AccountSetupProvider>().updateActivityLevel(ActivityLevel.veryActive),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
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
            Icon(
              icon,
              size: 40,
              //Sử dụng màu icon được truyền vào
              color: isSelected ? primaryColor : iconColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}