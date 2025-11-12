//lib /widgets/history/date_selector.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


//Widget này là một Bộ chọn ngày (Date Selector) cuộn ngang, hiển thị 30 ngày qua.
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final int dayCount;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.dayCount = 30,
  });

  bool _isSameDay(DateTime dateA, DateTime dateB) {
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA8D15D);

    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Bắt đầu từ ngày hôm nay
        itemCount: dayCount,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: index));
          final dayDate = DateTime(date.year, date.month, date.day);
          final bool isSelected = _isSameDay(dayDate, selectedDate);

          return GestureDetector(
            onTap: () => onDateSelected(dayDate),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'vi_VN').format(date), // "T2", "T3"
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}