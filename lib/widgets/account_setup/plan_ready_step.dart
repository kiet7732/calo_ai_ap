import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/account_setup_provider.dart';
import '../account_setup/step_container.dart';

class PlanReadyStep extends StatelessWidget {
  const PlanReadyStep({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<AccountSetupProvider>().userProfile;
    // Đọc dữ liệu đã tính toán từ UserProfile
    final calorieGoal = userProfile.calorieGoal ?? 0;
    final proteinGrams = userProfile.proteinGoal ?? 0;
    final carbGrams = userProfile.carbGoal ?? 0;
    final fatGrams = userProfile.fatGoal ?? 0;

    return StepContainer(
      title: "Kế hoạch của bạn đã sẵn sàng!",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            width: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 80,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: Colors.orange.shade400, // Carbs
                        value: carbGrams.toDouble(),
                        title: '',
                        radius: 25,
                      ),
                      PieChartSectionData(
                        color: Colors.red.shade400, // Protein
                        value: proteinGrams.toDouble(),
                        title: '',
                        radius: 25,
                      ),
                      PieChartSectionData(
                        color: Colors.blue.shade400, // Fat
                        value: fatGrams.toDouble(),
                        title: '',
                        radius: 25,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      calorieGoal.toString(),
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "kcal",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildLegend(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.orange.shade400, "Carbs"),
        _buildLegendItem(Colors.red.shade400, "Protein"),
        _buildLegendItem(Colors.blue.shade400, "Fat"),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}