import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_routes.dart';
//lib/screens/account_setup_screen.dart
import '../providers/account_setup_provider.dart';
import '../widgets/account_setup/gender_step.dart';
import '../widgets/account_setup/dob_step.dart';
import '../widgets/account_setup/height_step.dart';
import '../widgets/account_setup/weight_step.dart';
import '../widgets/account_setup/activity_level_step.dart';
import '../widgets/account_setup/plan_ready_step.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 7;

  // Màu chủ đạo
  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _calculateAndNextPage() async {
    // Lấy provider (không lắng nghe) để gọi hàm
    final provider = context.read<AccountSetupProvider>();
    await provider.calculateCaloriePlan();

    // Sau khi tính toán xong, chuyển đến trang cuối
    if (mounted) {
      // Kiểm tra widget còn tồn tại
      _pageController.animateToPage(
        _totalPages - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeSetup() {
    print("Account setup completed! Nextpage");
    // Điều hướng đến màn hình chính và xóa tất cả các route trước đó
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.main, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe AccountSetupProvider đã được cung cấp ở main.dart
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                ),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
        title: LinearProgressIndicator(
          value: (_currentPage + 1) / _totalPages,
          backgroundColor: Colors.grey[200],
          color: primaryColor,
          minHeight: 6,
        ),
      ),
      // Sử dụng Stack để hiển thị màn hình tải đè lên trên
      body: Consumer<AccountSetupProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Lớp 1: PageView luôn được build
              PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: const [
                  GenderStep(),
                  DobStep(),
                  HeightStep(),
                  WeightStep(isGoalWeight: false),
                  WeightStep(isGoalWeight: true),
                  ActivityLevelStep(),
                  PlanReadyStep(),
                ],
              ),
              // Lớp 2: Màn hình tải (chỉ hiển thị khi isLoading = true)
              if (provider.isLoading)
                Container(
                  color: Colors.white.withOpacity(0.8),
                  child: const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget? _buildBottomButton() {
    if (_currentPage == _totalPages - 1) {
      // Màn hình cuối cùng
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _completeSetup,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Start Your Plan Now",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Nút đặc biệt cho trang 6 (Activity Level), index là 5
    if (_currentPage == 5) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _calculateAndNextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Tiếp tục",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Các màn hình khác
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Tiếp tục",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
