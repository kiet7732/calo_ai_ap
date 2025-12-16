import 'package:flutter/material.dart';
import '../utils/app_routes.dart';
import 'settings_screen.dart';
import 'today_screen.dart';
import 'stats_screen.dart'; // Import StatsScreen mới
import 'chat_screen.dart'; // Import ChatScreen mới

class MainNavigatorScreen extends StatefulWidget {
  const MainNavigatorScreen({super.key});

  @override
  State<MainNavigatorScreen> createState() => _MainNavigatorScreenState();
}

class _MainNavigatorScreenState extends State<MainNavigatorScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình. Phải khởi tạo trong initState để truyền hàm callback.
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      // Truyền hàm _onItemTapped xuống cho TodayScreen
      TodayScreen(onNavigate: _onItemTapped),
      const ChatScreen(), // Thay thế Tab Nhật ký bằng Chat Box
      const StatsScreen(initialViewIndex: 1), // Tab Báo cáo (mặc định là Tuần)
      const SettingsScreen(),
    ];
  }

  // Màu chủ đạo của ứng dụng
  static const Color primaryColor = Color(0xFFA8D15D);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showFab = _selectedIndex != 1; // Ẩn nút Camera khi ở tab Chat (index 1)

    return Scaffold(
      // Hiển thị màn hình được chọn từ danh sách
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      floatingActionButton: showFab ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.camera);
        },
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: showFab ? const CircularNotchedRectangle() : null,
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(
              index: 0,
              activeIcon: Icons.home,
              icon: Icons.home_outlined,
              label: 'Hôm nay',
            ),
            _buildTabItem(
              index: 1, 
              activeIcon: Icons.chat, 
              icon: Icons.chat_outlined, 
              label: 'Chat Box', 
            ),
            if (showFab) const SizedBox(width: 40), // Khoảng trống cho FAB
            _buildTabItem(
              index: 2,
              activeIcon: Icons.bar_chart,
              icon: Icons.bar_chart_outlined,
              label: 'Báo cáo',
            ),
            _buildTabItem(
              index: 3,
              activeIcon: Icons.settings,
              icon: Icons.settings_outlined,
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }

  // Widget helper để tạo mỗi mục trong thanh điều hướng
  Widget _buildTabItem({
    required int index,
    required IconData activeIcon,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
