import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các widget con và provider
import '../providers/report/report_provider.dart'; // SỬA: Dùng ReportProvider
import '../widgets/report/calorie_trend_chart.dart';
import '../widgets/report/macro_distribution_chart.dart'; // FIX: Corrected import path
import '../providers/report/report_stat_card.dart'; // FIX: Corrected import path
import '../providers/report/report_provider.dart'; // Để sử dụng enum TimeRange

class ReportScreen extends StatefulWidget {
  final TimeRange timeRange; // Nhận tham số timeRange từ StatsScreen
  const ReportScreen({super.key, required this.timeRange});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  TimeRange _selectedTimeRange = TimeRange.week;
  
  @override
  void initState() {
    super.initState();
    _selectedTimeRange = widget.timeRange; // Khởi tạo từ tham số truyền vào
  }
  @override
  Widget build(BuildContext context) {
    // Lấy provider và tính toán dữ liệu
    final reportProvider = context.watch<ReportProvider>();
    final reportData = reportProvider.getReportData(widget.timeRange); // Sử dụng widget.timeRange

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0), // Giữ padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loại bỏ _buildTimeRangeSelector()
          const SizedBox(height: 24),
          CalorieTrendChart(reportData: reportData),
          const SizedBox(height: 24),
          _buildAverageStatsCards(reportData),
          const SizedBox(height: 24),
          MacroDistributionChart(reportData: reportData),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAverageStatsCards(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trung bình mỗi ngày',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            ReportStatCard(
              title: 'Calo',
              value: '${data['avgCalories']} kcal',
              icon: Icons.local_fire_department,
              color: Colors.red,
            ),
            ReportStatCard(
              title: 'Protein',
              value: '${data['avgProtein']} g',
              icon: Icons.bolt,
              color: Colors.purple,
            ),
            ReportStatCard(
              title: 'Carb',
              value: '${data['avgCarbs']} g',
              icon: Icons.bakery_dining,
              color: Colors.orange,
            ),
            ReportStatCard(
              title: 'Fat',
              value: '${data['avgFat']} g',
              icon: Icons.opacity,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}
