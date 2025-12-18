import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_settings_provider.dart';
import 'settings_group.dart';
import 'settings_tile.dart';

class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({super.key});

  /// Hiển thị bottom sheet để chọn giờ.
  void _showTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    TimeOfDay newTime = initialTime;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              // Thanh công cụ với nút Hủy và Lưu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Hủy'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Lưu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        onTimeChanged(newTime);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    DateTime.now().year,
                    1,
                    1,
                    initialTime.hour,
                    initialTime.minute,
                  ),
                  onDateTimeChanged: (DateTime dt) =>
                      newTime = TimeOfDay.fromDateTime(dt),
                  use24hFormat: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget helper để xây dựng một dòng cài đặt thông báo.
  Widget _buildNotificationTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return SettingsTile(
      icon: icon,
      iconColor: value ? iconColor : Colors.grey.shade400,
      title: title,
      onTap: onTimeTap, // Nhấn vào cả dòng để mở time picker
      customTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time.format(context),
            style: TextStyle(
              color: value ? Colors.grey.shade700 : Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onToggle,
              activeColor: const Color(0xFFA8D15D),
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationSettingsProvider>(
      builder: (context, notificationSettings, child) {
        return SettingsGroup(
          title: 'Thông báo',
          children: [
            _buildNotificationTile(
              context: context,
              title: 'Nhắc nhở bữa ăn',
              icon: Icons.restaurant_menu,
              iconColor: Colors.orange,
              value: notificationSettings.mealReminders,
              time: notificationSettings.mealReminderTime,
              onToggle: (value) => notificationSettings.toggleMealReminder(value),
              onTimeTap: () => _showTimePicker(
                context: context,
                initialTime: notificationSettings.mealReminderTime,
                onTimeChanged: (newTime) => notificationSettings.updateMealReminderTime(newTime),
              ),
            ),
            _buildNotificationTile(
              context: context,
              title: 'Nhắc nhở uống nước',
              icon: Icons.water_drop_outlined,
              iconColor: Colors.lightBlue,
              value: notificationSettings.waterReminders,
              time: notificationSettings.waterReminderTime,
              onToggle: (value) => notificationSettings.toggleWaterReminder(value),
              onTimeTap: () => _showTimePicker(
                context: context,
                initialTime: notificationSettings.waterReminderTime,
                onTimeChanged: (newTime) => notificationSettings.updateWaterReminderTime(newTime),
              ),
            ),
          ],
        );
      },
    );
  }
}