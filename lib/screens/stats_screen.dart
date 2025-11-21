import 'package:flutter/material.dart';
import '../screens/history_screen.dart'; // HistoryView
import '../screens/report_screen.dart'; // ReportView
import '../providers/report/report_provider.dart'; // Để sử dụng enum TimeRange

class StatsScreen extends StatefulWidget {
  // initialViewIndex sẽ được dùng để xác định tab mặc định khi mở màn hình
  final int initialViewIndex;
  const StatsScreen({
    super.key,
    this.initialViewIndex = 0, // Mặc định hiển thị Nhật ký (index 0)
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 0: Nhật ký, 1: Tuần, 2: Tháng
  late int _selectedViewIndex;

  @override
  void initState() {
    super.initState();
    _selectedViewIndex = widget.initialViewIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo của ứng dụng
    const Color primaryColor = Color(0xFFA8D15D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Nhật ký'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: _buildViewTypeSelector(),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedViewIndex,
              children: [
                const HistoryScreen(), // Index 0: Nhật ký
                // Index 1: Báo cáo Tuần
                ReportScreen(timeRange: TimeRange.week),
                // Index 2: Báo cáo Tháng
                ReportScreen(timeRange: TimeRange.month),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTypeSelector() {
    const Color primaryColor = Color(0xFFA8D15D);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth; // Chiều rộng của Padding cha
        const double itemMargin = 4.0; // Margin áp dụng cho mỗi _buildToggleItem
        final double segmentFullWidth = totalWidth / 3; // Chiều rộng của một Expanded child
        final double segmentWidth = segmentFullWidth - (itemMargin * 2); // Chiều rộng thực tế của "viên thuốc"

        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              // "Viên thuốc" di chuyển (Sliding indicator)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedViewIndex * segmentFullWidth + itemMargin,
                width: segmentWidth,
                height: 44 - (itemMargin * 2), // Chiều cao của "viên thuốc"
                top: itemMargin, // Vị trí top của "viên thuốc"
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 211, 88, 88),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              // Các nút văn bản (Buttons)
              Row(
                children: [
                  _buildToggleItem(0, 'Nhật ký', primaryColor),
                  _buildToggleItem(1, 'Tuần', primaryColor),
                  _buildToggleItem(2, 'Tháng', primaryColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleItem(int index, String text, Color primaryColor) {
    final bool isSelected = _selectedViewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedViewIndex = index;
          });
        },
        child: Container( // Đã thay đổi từ AnimatedContainer thành Container
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}