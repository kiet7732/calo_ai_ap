import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các thành phần cần thiết từ đúng vị trí
import '../../providers/account_setup_provider.dart';
import '../../utils/app_routes.dart';
import '../account_setup/gender_step.dart';
import '../account_setup/dob_step.dart';
import '../account_setup/height_step.dart';
import '../account_setup/weight_step.dart';
import '../account_setup/activity_level_step.dart';
import '../account_setup/plan_ready_step.dart';

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
    _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _completeSetup() {
    // Điều hướng đến màn hình chính và xóa tất cả các route trước đó
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.main,
      (Route<dynamic> route) => false, // Điều kiện này xóa tất cả route
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AccountSetupProvider(),
      // Sử dụng Consumer để lắng nghe trạng thái isLoading
      child: Consumer<AccountSetupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            // Hiển thị màn hình tải
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 20),
                    Text("Đang tính toán kế hoạch...", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            );
          }

          // Hiển thị PageView bình thường
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: _currentPage > 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
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
            body: PageView(
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
            bottomNavigationBar: _buildBottomButton(),
          );
        },
      ),
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
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }

    // Nút đặc biệt cho trang 6 (Activity Level)
    if (_currentPage == 5) { // Index của ActivityLevelStep là 5
      return _buildCalculateButton();
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
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
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
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}