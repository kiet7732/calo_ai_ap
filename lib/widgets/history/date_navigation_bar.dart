// Widget: lib/widgets/date_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Một thanh điều hướng cho phép người dùng chọn ngày.
///
/// Widget này hiển thị ngày được chọn, các nút để chuyển đến ngày
/// hôm trước/hôm sau, và mở một [showDatePicker] để chọn ngày bất kỳ.
class DateNavigationBar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateNavigationBar({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  static const Color primaryColor = Color(0xFFA8D15D);

  // Giới hạn ngày sớm nhất có thể chọn
  static final DateTime _earliestDate = DateTime(2025, 11, 1);

  // Hàm helper để kiểm tra hai ngày có giống nhau không
  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  // Hàm kiểm tra xem ngày được chọn có phải là hôm nay không
  bool _isTodaySelected() {
    final now = DateTime.now();
    return _isSameDay(selectedDate, now);
  }

  // Hàm kiểm tra xem ngày được chọn có phải là hôm qua không
  bool _isYesterdaySelected() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return _isSameDay(selectedDate, yesterday);
  }

  // Hàm định dạng chuỗi ngày tháng cho thanh điều hướng
  String _formatDisplayDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(date, today)) {
      return 'Hôm nay';
    }
    if (_isSameDay(date, yesterday)) {
      return 'Hôm qua';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Hàm hiển thị DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: _earliestDate,// : Dùng ngày giới hạn đã định nghĩa
      lastDate: DateTime.now(), // Không cho chọn ngày trong tương lai
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && !_isSameDay(picked, selectedDate)) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút ngày hôm trước
          IconButton(
            icon: Icon(
              Icons.chevron_left,

              // LỖI: Xóa dấu ngoặc đơn ( và ) ở đây
              color: selectedDate.isAfter(_earliestDate)
                  ? const Color.fromARGB(255, 11, 0, 75)
                  : Colors.grey,
              size: 30,
            ),
            onPressed: selectedDate.isAfter(_earliestDate)
                ? () => onDateChanged(
                    selectedDate.subtract(const Duration(days: 1)),
                  )
                : null,
          ),
          // Hiển thị ngày và nút mở lịch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: const Color.fromARGB(255, 16, 0, 107),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDisplayDate(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
              // NÚT "TRỞ VỀ HÔM NAY" - CHỈ HIỂN THỊ KHI KHÔNG PHẢI NGÀY HÔM NAY VÀ HÔM QUA
              if (!_isTodaySelected() && !_isYesterdaySelected())
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: InkWell(
                    onTap: () {
                      final now = DateTime.now();
                      onDateChanged(DateTime(now.year, now.month, now.day));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Icon(
                      Icons.replay_circle_filled,
                      color: Color.fromARGB(255, 190, 35, 35),
                      size: 25,
                    ),
                  ),
                ),
            ],
          ),
          // Nút ngày hôm sau (vô hiệu hóa nếu là ngày hôm nay)
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _isTodaySelected()
                  ? Colors.grey
                  : const Color.fromARGB(255, 16, 0, 107),
              size: 30,
            ),
            onPressed: _isTodaySelected()
                ? null
                : () =>
                      onDateChanged(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}
