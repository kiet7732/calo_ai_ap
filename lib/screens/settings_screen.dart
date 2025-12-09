import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../providers/auth/auth_provider.dart';
import '../utils/app_routes.dart';

import '../widgets/settings/profile_header.dart';
import '../widgets/settings/settings_group.dart';
import '../widgets/settings/settings_tile.dart';

import '../providers/account_setup_provider.dart';
import '../models/sample_meals.dart';
import '../services/seed_meals_service.dart';
import '../services/seed_data_service.dart';
import '../providers/notification_settings_provider.dart';
import '../services/notification_service.dart'; // THÊM DÒNG NÀY


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Giữ nguyên state của màn hình
  bool _isDarkMode = false; // Thêm state cho giao diện tối

  /// VIẾT LẠI: Hiển thị bottom sheet để chọn giờ.
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
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Hủy'),
                      onPressed: () => Navigator.of(context).pop(),
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
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(DateTime.now().year, 1, 1, initialTime.hour, initialTime.minute),
                  onDateTimeChanged: (DateTime dt) => newTime = TimeOfDay.fromDateTime(dt),
                  use24hFormat: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //logout
  void _showLogoutDialog() {
    // Hiển thị một AlertDialog để xác nhận
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
              },
            ),
            TextButton(
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                // Đóng dialog trước
                Navigator.of(dialogContext).pop();

                // Lấy provider và thực hiện đăng xuất
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();

                // Điều hướng về màn hình đăng nhập và xóa tất cả các route trước đó
                if (!mounted) return;
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // SỬ DỤNG CONSUMER ĐỂ LẮNG NGHE THAY ĐỔI
    return Consumer<NotificationSettingsProvider>(
      builder: (context, notificationSettings, child) {
        final accountProvider = context.watch<AccountSetupProvider>();
        final userProfile = (accountProvider.userProfile.uid ?? '').isEmpty
            ? sampleUserProfile : accountProvider.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Cài đặt'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        children: [
          ProfileHeader(
            name: userProfile.displayName ?? "Người dùng mới",
            email: userProfile.email ?? "chưa có email",
          ),

          SettingsGroup(
            title: 'Tài khoản',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                iconColor: Colors.blue,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () {},
              ),
              // SettingsTile(
              //   icon: Icons.shield_outlined,
              //   iconColor: Colors.green,
              //   title: 'Bảo mật',
              //   onTap: () {},
              // ),
            ],
          ),

          SettingsGroup(
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
          ),

          SettingsGroup(
            title: 'Chung',
            children: [
              SettingsTile(
                icon: Icons.monitor_weight_outlined,
                iconColor: Colors.purple,
                title: 'Đơn vị cân nặng',
                //trailing: Text(userProfile.weightUnit ?? 'kg', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                onTap: () { /* Logic chọn đơn vị */ },
              ),
              SettingsTile(
                icon: Icons.height,
                iconColor: Colors.teal,
                title: 'Đơn vị chiều cao',
                //trailing: Text(userProfile.heightUnit ?? 'cm', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                onTap: () { /* Logic chọn đơn vị */ },
              ),
              SettingsTile(
                icon: Icons.brightness_6_outlined,
                iconColor: Colors.grey.shade800,
                title: 'Giao diện tối',
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: (value) => setState(() => _isDarkMode = value),
                  activeColor: const Color(0xFFA8D15D),
                ),
              ),
              SettingsTile(
                icon: Icons.language,
                iconColor: Colors.indigo,
                title: 'Ngôn ngữ',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                title: 'Đăng xuất',
                onTap: _showLogoutDialog,
              ),
            ],
          ),
          const SizedBox(height: 17),
          ElevatedButton(
            onPressed: () async {
              await SeedMealsService().seedMealsToFirestore();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo dữ liệu lịch sử món ăn!')),
              );
            },
            child: const Text("Tạo Dữ Liệu Món Ăn Mẫu"),
          ),

          ElevatedButton(
            onPressed: () async {
              await SeedDataService().seedCurrentMeals();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã thêm dữ liệu hôm nay!')),
              );
            },
            child: const Text("Tạo Dữ Liệu Hôm Nay"),
          ),
          const SizedBox(height: 20),
          // --- KHU VỰC TEST THÔNG BÁO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text("--- Dành cho nhà phát triển ---", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    context.read<NotificationService>().scheduleRepeatedTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã bắt đầu gửi thông báo test mỗi 15 giây.')),
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text("Bắt đầu Test thông báo liên tục"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: () {
                    context.read<NotificationService>().cancelTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã dừng gửi thông báo test.')),
                    );
                  },
                  icon: const Icon(Icons.stop_circle),
                  label: const Text("Dừng Test thông báo"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  /// VIẾT LẠI: Widget helper để xây dựng một dòng cài đặt thông báo.
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
            // Text hiển thị giờ
            Text(
              time.format(context),
              style: TextStyle(
                color: value ? Colors.grey.shade700 : Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            // Công tắc Bật/Tắt
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
}
