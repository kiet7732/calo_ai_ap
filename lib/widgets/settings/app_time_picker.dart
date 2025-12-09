import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Hiển thị một bottom sheet tùy chỉnh để chọn giờ.
void showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required ValueChanged<TimeOfDay> onTimeChanged,
}) {
  // Biến tạm để lưu thời gian người dùng chọn
  TimeOfDay newTime = initialTime;
  // Cờ để xác định xem người dùng có bấm nút "Hủy" hay không
  bool cancelled = false;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext builder) {
      return SizedBox(
        height: 300,
        child: Column(
          children: [
            // Tay nắm (Drag Handle)
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Thanh công cụ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Hủy'),
                    onPressed: () {
                      cancelled = true;
                      Navigator.of(context).pop();
                    },
                  ),
                  CupertinoButton(
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      onTimeChanged(newTime);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // Time Picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(DateTime.now().year, 1, 1, initialTime.hour, initialTime.minute),
                onDateTimeChanged: (DateTime newDateTime) {
                  newTime = TimeOfDay.fromDateTime(newDateTime);
                },
                use24hFormat: true,
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    // Tự động lưu khi người dùng bấm ra ngoài (chỉ khi không bấm "Hủy")
    if (!cancelled) {
      onTimeChanged(newTime);
    }
  });
}