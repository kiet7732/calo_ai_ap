import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../providers/account_setup_provider.dart';
import '../account_setup/step_container.dart';

class GenderStep extends StatelessWidget {
  const GenderStep({super.key});

  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountSetupProvider>();
    final gender = provider.userProfile.gender;

    return StepContainer(
      title: "Bạn là...",
      child: Row(
        children: [
          Expanded(
            child: _buildChoiceCard(
              label: "Nam",
              icon: Icons.male,
              isSelected: gender == Gender.male,
              onTap: () => context.read<AccountSetupProvider>().updateGender(Gender.male),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildChoiceCard(
              label: "Nữ",
              icon: Icons.female,
              isSelected: gender == Gender.female,
              onTap: () => context.read<AccountSetupProvider>().updateGender(Gender.female),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 60,
                color: isSelected ? primaryColor : Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}