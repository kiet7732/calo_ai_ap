import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/account_setup_provider.dart';
import '../account_setup/step_container.dart';

class DobStep extends StatefulWidget {
  const DobStep({super.key});

  @override
  State<DobStep> createState() => _DobStepState();
}

class _DobStepState extends State<DobStep> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  // Dữ liệu cho các bánh xe cuộn
  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<int> _months = List.generate(12, (index) => index + 1);
  final List<int> _years = List.generate(101, (index) => DateTime.now().year - index); // 101 năm gần nhất

  static const Color primaryColor = Color(0xFFA8D15D);
  static const double _itemExtent = 45.0;

  @override
  void initState() {
    super.initState();
    final initialDate = context.read<AccountSetupProvider>().userProfile.dateOfBirth ?? DateTime.now();

    _dayController = FixedExtentScrollController(initialItem: initialDate.day - 1);
    _monthController = FixedExtentScrollController(initialItem: initialDate.month - 1);
    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(initialDate.year));
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onDateChanged() {
    final newDay = _days[_dayController.selectedItem];
    final newMonth = _months[_monthController.selectedItem];
    final newYear = _years[_yearController.selectedItem];

    // Logic để xử lý ngày không hợp lệ (ví dụ: 31/2)
    // Lấy ngày cuối cùng của tháng được chọn
    final daysInMonth = DateUtils.getDaysInMonth(newYear, newMonth);
    if (newDay > daysInMonth) {
      // Nếu ngày hiện tại vượt quá, tự động cuộn về ngày cuối cùng của tháng
      _dayController.animateToItem(daysInMonth - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    final newDate = DateTime(newYear, newMonth, newDay > daysInMonth ? daysInMonth : newDay);
    context.read<AccountSetupProvider>().updateDob(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      title: "Ngày sinh của bạn?",
      child: SizedBox(
        height: 250, // Giới hạn chiều cao của khu vực cuộn
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Lớp chứa các vạch kẻ ngang
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 23),
                const Spacer(),
                Divider(color: Colors.grey.shade300, thickness: 2),
                const SizedBox(height: _itemExtent),
                Divider(color: Colors.grey.shade300, thickness: 2),
                const Spacer(),
              ],
            ),
            // Lớp chứa các bánh xe cuộn
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWheelScroller(
                  controller: _dayController,
                  items: _days,
                  label: "Ngày",
                ),
                _buildWheelScroller(
                  controller: _monthController,
                  items: _months,
                  label: "Tháng",
                ),
                _buildWheelScroller(
                  controller: _yearController,
                  items: _years,
                  label: "Năm",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheelScroller({
    required FixedExtentScrollController controller,
    required List<int> items,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: _itemExtent,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (_) => _onDateChanged(),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: items.length,
                builder: (context, index) {
                  // Sử dụng `AnimatedBuilder` để lắng nghe sự thay đổi của controller
                  // và build lại chỉ widget này, giúp tối ưu hiệu suất.
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      // Kiểm tra xem item có đang được chọn không
                      final bool isSelected = controller.hasClients && controller.selectedItem == index;
                      return Center(
                        child: Text(
                          items[index].toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? primaryColor : Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}