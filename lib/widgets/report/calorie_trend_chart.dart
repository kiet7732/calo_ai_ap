// lib/widgets/report/calorie_trend_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Widget hiển thị biểu đồ đường "Xu hướng Calo".
class CalorieTrendChart extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const CalorieTrendChart({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final List<double> dailyCalories = reportData['dailyCalories'] ?? [];
    final List<String> labels = reportData['labels'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xu hướng Calo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        //--------------bieu do duong---------------
        Container(
          height: 230,
          padding: const EdgeInsets.symmetric(
            vertical:8,
            horizontal: 0,
          ), // Tối ưu chiều ngang
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: dailyCalories.every((element) => element == 0)
              ? const Center(child: Text("Không có dữ liệu để vẽ biểu đồ."))
              : LineChart(
                  LineChartData(
                    minY: 0,
                    // 1. THIẾT KẾ LẠI LƯỚI (GRID)
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [3, 3],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (labels.length / 5)
                              .floor()
                              .toDouble(), // Tự động chia khoảng cách
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final style = const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            );
                            int index = value.toInt();
                            final text = (index >= 0 && index < labels.length)
                                ? labels[index]
                                : '';
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8.0,
                              child: Text(text, style: style),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 500, // Hiển thị nhãn mỗi 500 kcal
                          reservedSize: 42,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final style = const TextStyle(
                              color: Color(0xff67727d),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            );
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8.0,
                              child: Text(meta.formattedValue, style: style),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false, // 2. BỎ ĐƯỜNG VIỀN
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: dailyCalories.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value);
                        }).toList(),
                        isCurved: true, // Đường cong mượt mà
                        // 3. THAY ĐỔI BẢNG MÀU
                        gradient: const LinearGradient(
                          colors: [Color(0xff23b6e6), Color(0xff02d39a)],
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true, // Cho phép hiển thị chấm
                          checkToShowDot: (spot, barData) {
                            if (labels.length <= 7) {
                              // Nếu là chế độ tuần (7 ngày), hiển thị tất cả các chấm
                              return true;
                            } else {
                              // Nếu là chế độ tháng (30 ngày), chỉ hiển thị chấm cuối cùng
                              return spot.x == barData.spots.last.x;
                            }
                          },
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              // Giảm bán kính một chút để trông cân đối hơn khi có nhiều chấm
                              radius: labels.length <= 7 ? 4 : 6,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xff02d39a),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xff23b6e6).withOpacity(0.3),
                              const Color(0xff02d39a).withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                    // 4. THIẾT KẾ LẠI TOOLTIP
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (LineBarSpot spot) =>
                            Colors.black.withOpacity(0.8),
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final flSpot = barSpot;
                            final dateLabel = labels[flSpot.x.toInt()];

                            return LineTooltipItem(
                              '$dateLabel\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: '${flSpot.y.round()} kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
