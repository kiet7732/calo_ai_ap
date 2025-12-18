import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../utils/app_routes.dart';

import '../widgets/settings/profile_header.dart';
import '../widgets/settings/settings_group.dart';
import '../widgets/settings/settings_tile.dart';

import '../providers/account_setup_provider.dart';
import '../models/sample_meals.dart';
import '../services/seed_meals_service.dart';
import '../services/seed_data_service.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Giữ nguyên state của màn hình
  bool _mealReminders = true;
  bool _waterReminders = false;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  bool _isDarkMode = false; // Thêm state cho giao diện tối

  void _showUnitPicker(
    String title,
    List<String> options,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    print("Showing picker for $title");
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
    //Lấy dữ liệu từ provider
    final providerProfile = context.watch<AccountSetupProvider>().userProfile;

    // Logic: Nếu dữ liệu từ provider chưa có (ví dụ: uid rỗng),
    // thì dùng dữ liệu mẫu. Khi có dữ liệu thật, sẽ tự động dùng dữ liệu thật.
    final userProfile = (providerProfile.uid ?? '').isEmpty
        ? sampleUserProfile
        : providerProfile;

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
              SettingsTile(
                icon: Icons.shield_outlined,
                iconColor: Colors.green,
                title: 'Bảo mật',
                onTap: () {},
              ),
            ],
          ),

          SettingsGroup(
            title: 'Thông báo',
            children: [
              SettingsTile(
                icon: Icons.restaurant_menu,
                iconColor: Colors.orange,
                title: 'Nhắc nhở bữa ăn',
                trailing: Switch(
                  value: _mealReminders,
                  onChanged: (value) => setState(() => _mealReminders = value),
                  activeColor: const Color(0xFFA8D15D),
                ),
              ),
              SettingsTile(
                icon: Icons.water_drop_outlined,
                iconColor: Colors.lightBlue,
                title: 'Nhắc nhở uống nước',
                trailing: Switch(
                  value: _waterReminders,
                  onChanged: (value) => setState(() => _waterReminders = value),
                  activeColor: const Color(0xFFA8D15D),
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
                trailing: Text(
                  _weightUnit,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                onTap: () => _showUnitPicker(
                  'Cân nặng',
                  ['kg', 'lbs'],
                  _weightUnit,
                  (val) => setState(() => _weightUnit = val),
                ),
              ),
              SettingsTile(
                icon: Icons.height,
                iconColor: Colors.teal,
                title: 'Đơn vị chiều cao',
                trailing: Text(
                  _heightUnit,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                onTap: () => _showUnitPicker(
                  'Chiều cao',
                  ['cm', 'ft'],
                  _heightUnit,
                  (val) => setState(() => _heightUnit = val),
                ),
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
        ],
      ),
    );
  }
}
