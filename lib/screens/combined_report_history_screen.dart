import 'package:flutter/material.dart';
import '../screens/history_screen.dart';
import '../screens/report_screen.dart';
import '../providers/report/report_provider.dart';

enum ReportViewType { history, report }

class CombinedReportHistoryScreen extends StatefulWidget {
  final ReportViewType initialViewType;
  const CombinedReportHistoryScreen({
    super.key,
    this.initialViewType = ReportViewType.history, // Mặc định hiển thị Nhật ký
  });

  @override
  State<CombinedReportHistoryScreen> createState() => _CombinedReportHistoryScreenState();
}

class _CombinedReportHistoryScreenState extends State<CombinedReportHistoryScreen> {
  late ReportViewType _selectedViewType;

  @override
  void initState() {
    super.initState();
    _selectedViewType = widget.initialViewType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Nhật ký'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildViewTypeSelector(),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedViewType.index,
              children: const [
                HistoryScreen(),
                ReportScreen(timeRange: TimeRange.week),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTypeSelector() {
    return SegmentedButton<ReportViewType>(
      segments: const [
        ButtonSegment(value: ReportViewType.history, label: Text('Nhật ký')),
        ButtonSegment(value: ReportViewType.report, label: Text('Báo cáo')),
      ],
      selected: {_selectedViewType},
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedViewType = newSelection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: const Color(0xFFA8D15D),
      ),
    );
  }
}