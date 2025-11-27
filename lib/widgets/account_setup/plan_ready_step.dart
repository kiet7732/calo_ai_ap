import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Cần import intl để format ngày
import '../account_setup/step_container.dart';
import '../../../providers/account_setup_provider.dart';

class PlanReadyStep extends StatelessWidget {
  const PlanReadyStep({super.key});

  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ Provider (đã được tính toán xong)
    final provider = context.watch<AccountSetupProvider>();
    final userProfile = provider.userProfile;
    
    final calorieGoal = userProfile.calorieGoal ?? 0;
    final proteinGrams = userProfile.proteinGoal ?? 0;
    final carbGrams = userProfile.carbGoal ?? 0;
    final fatGrams = userProfile.fatGoal ?? 0;
    
    // Đọc trực tiếp kết quả dự đoán từ các getter mới của Provider
    final targetDate = provider.predictionDate ?? DateTime.now();
    final weeksToGoal = provider.predictionWeeks ?? 0;
    final formattedDate = DateFormat('dd/MM/yyyy').format(targetDate);

    // Các biến này vẫn cần để hiển thị
    final goalWeight = userProfile.goalWeight ?? 0; 
    final currentWeight = userProfile.currentWeight ?? 0; 

    return StepContainer(
      title: "Kế hoạch của bạn đã sẵn sàng!",
      child: SingleChildScrollView( // Thêm cuộn để tránh tràn màn hình trên máy nhỏ
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 1. BIỂU ĐỒ MACROS (PLAN)
            SizedBox(
              height: 220,
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 70,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: Colors.orange.shade400,
                          value: carbGrams.toDouble(),
                          title: '${carbGrams}g',
                          radius: 20,
                          titleStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 2, 0, 0)),
                        ),
                        PieChartSectionData(
                          color: Colors.red.shade400,
                          value: proteinGrams.toDouble(),
                          title: '${proteinGrams}g',
                          radius: 20,
                          titleStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        PieChartSectionData(
                          color: Colors.blue.shade400,
                          value: fatGrams.toDouble(),
                          title: '${fatGrams}g',
                          radius: 20,
                          titleStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$calorieGoal",
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                      ),
                      const Text("kcal / ngày", style: TextStyle(fontSize: 15, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            _buildLegend(),
            
            const SizedBox(height: 30),
            const Divider(height: 1),
            const SizedBox(height: 30),

            // 2. THẺ DỰ ĐOÁN (PREDICTION)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_today_rounded, color: primaryColor, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Đạt mục tiêu ${goalWeight}kg vào:",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$weeksToGoal tuần",
                          style: const TextStyle(color: Color.fromARGB(255, 100, 15, 15), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Thanh hành trình (Current -> Goal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeightLabel("Hiện tại", currentWeight),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(
                              value: 0.6, // Luôn để 60% để minh họa hành trình
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        ),
                      ),
                      _buildWeightLabel("Mục tiêu", goalWeight, isTarget: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                   Text(
                    (goalWeight < currentWeight)
                        ? "Bạn cần giảm ${(currentWeight - goalWeight).abs().toStringAsFixed(1)} kg"
                        : "Bạn cần tăng ${(goalWeight - currentWeight).abs().toStringAsFixed(1)} kg",
                    style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 0, 0, 0), fontStyle: FontStyle.italic),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightLabel(String label, double weight, {bool isTarget = false}) {
    return Column(
      crossAxisAlignment: isTarget ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          "$weight kg",
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: isTarget ? const Color.fromARGB(255, 255, 0, 0) : Colors.black87
          ),
        ),
      ],
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}