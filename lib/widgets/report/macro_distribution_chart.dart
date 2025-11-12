// lib/widgets/report/macro_distribution_chart.dart
// lib/widgets/report/macro_distribution_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget hiển thị biểu đồ tròn "Phân bổ dinh dưỡng". tròn
class MacroDistributionChart extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const MacroDistributionChart({super.key, required this.reportData});

  @override
  State<MacroDistributionChart> createState() => _MacroDistributionChartState();
}

class _MacroDistributionChartState extends State<MacroDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final double totalProtein = widget.reportData['totalProtein'] ?? 0.0;
    final double totalCarbs = widget.reportData['totalCarbs'] ?? 0.0;
    final double totalFat = widget.reportData['totalFat'] ?? 0.0;
    final double totalMacros = totalProtein + totalCarbs + totalFat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Phân bổ dinh dưỡng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: totalMacros > 0
              ? Row(
                  children: <Widget>[
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildPieChartSections(totalMacros),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        _Indicator(color: Colors.purple, text: 'Protein', isSquare: true),
                        SizedBox(height: 4),
                        _Indicator(color: Colors.orange, text: 'Carb', isSquare: true),
                        SizedBox(height: 4),
                        _Indicator(color: Colors.blue, text: 'Fat', isSquare: true),
                      ],
                    ),
                    const SizedBox(width: 28),
                  ],
                )
              : const Center(child: Text("Không có dữ liệu để hiển thị.")),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(double totalMacros) {
    final double totalProtein = widget.reportData['totalProtein'] ?? 0.0;
    final double totalCarbs = widget.reportData['totalCarbs'] ?? 0.0;
    final double totalFat = widget.reportData['totalFat'] ?? 0.0;

    return [
      _buildSection(0, (totalProtein / totalMacros) * 100, Colors.purple),
      _buildSection(1, (totalCarbs / totalMacros) * 100, Colors.orange),
      _buildSection(2, (totalFat / totalMacros) * 100, Colors.blue),
    ];
  }

  PieChartSectionData _buildSection(int index, double value, Color color) {
    final isTouched = index == touchedIndex;
    final fontSize = isTouched ? 20.0 : 14.0;
    final radius = isTouched ? 60.0 : 50.0;
    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toStringAsFixed(1)}%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: const Color(0xffffffff),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;

  const _Indicator({
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))
      ],
    );
  }
}