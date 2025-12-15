// lib/widgets/account_setup/height_step.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/account_setup_provider.dart';
import '../account_setup/step_container.dart';

enum HeightUnit { cm, ft }

class HeightStep extends StatefulWidget {
  const HeightStep({super.key});

  @override
  State<HeightStep> createState() => _HeightStepState();
}

class _HeightStepState extends State<HeightStep> {
  static const Color primaryColor = Color(0xFFA8D15D);
  static const int minHeightCm = 100;
  static const int maxHeightCm = 230;
  
  //Tăng chiều rộng item để có khoảng cách (giống Figma)
  static const double itemWidth = 16.0; 
  static const double rulerHeight = 180.0; //Tăng chiều cao của thước đo

  late ScrollController _scrollController;
  HeightUnit _selectedUnit = HeightUnit.cm;
  int _currentHeightCm = 170;

  @override
  void initState() {
    super.initState();
    // Lấy giá trị ban đầu từ Provider
    _currentHeightCm =
        context.read<AccountSetupProvider>().userProfile.height ?? 170;

    // Tính toán vị trí cuộn ban đầu
    final initialOffset = (_currentHeightCm - minHeightCm) * itemWidth;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatHeight() {
    if (_selectedUnit == HeightUnit.ft) {
      final double totalInches = _currentHeightCm / 2.54;
      final int feet = totalInches ~/ 12;
      final int inches = (totalInches % 12).round();
      return "$feet' $inches\"";
    }
    // Hiển thị 1 số thập phân (giống Figma)
    return "${_currentHeightCm.toDouble()} cm"; 
  }

  // --- TỐI ƯU HIỆU NĂNG:ỖI LAG/CRASH ---
  bool _isUserScrolling = false;

  void _handleScrollNotification(ScrollNotification notification) {
    // 1. Xác định xem người dùng có đang chủ động kéo hay không
    if (notification is UserScrollNotification) {
      // Nếu người dùng bắt đầu hoặc kết thúc kéo, cập nhật cờ
      _isUserScrolling = true;
    }

    // 2. Cập nhật giá trị hiển thị (setState) khi đang cuộn
    if (notification is ScrollUpdateNotification) {
      final newHeight = minHeightCm + (_scrollController.offset / itemWidth).round();
      if (_currentHeightCm != newHeight) {
        setState(() {
          _currentHeightCm = newHeight;
        });
      }
    }

    // 3. Chỉ "Snap" và "Lưu" (Provider) khi người dùng đã dừng kéo
    if (notification is ScrollEndNotification) {
      // Chỉ thực hiện khi đây là kết thúc của một lần kéo từ người dùng
      if (_isUserScrolling) {
        _isUserScrolling = false; // Reset cờ

        final centerIndex = (_scrollController.offset / itemWidth).round();
        final finalHeight = minHeightCm + centerIndex;
        final snapOffset = centerIndex * itemWidth;

        // Gọi animateTo để "snap" vào vị trí gần nhất
        _scrollController.animateTo(
          snapOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );

        // Chỉ gọi provider để lưu dữ liệu 1 LẦN khi đã dừng
        context.read<AccountSetupProvider>().updateHeight(finalHeight);
      }
    }
  }
  // --- KẾT THÚCỖI ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StepContainer(
      title: "Chiều cao của bạn?",
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Nút chuyển đổi đơn vị
          //Thay thế hàm helper bằng một Widget độc lập để tối ưu hiệu năng
          UnitToggle(
            selectedUnit: _selectedUnit,
            onChanged: (newUnit) => setState(() => _selectedUnit = newUnit),
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 40),
          // Hiển thị giá trị (cập nhật theo thời gian thực)
          Text(
            _formatHeight(),
            style: const TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const Spacer(flex: 2),

          // ---IAO DIỆN THƯỚC ĐO (GIỐNG FIGMA) ---
          SizedBox(
            height: rulerHeight, // Chiều cao cố định
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _handleScrollNotification(notification);
                return true;
              },
              //Xóa Stack/Positioned (Không dùng con trỏ cố định)
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: (maxHeightCm - minHeightCm) + 1, 
                // Căn giữa thước đo
                padding: EdgeInsets.symmetric(
                  horizontal: (screenWidth / 2) - (itemWidth / 2),
                ),
                itemBuilder: (context, index) {
                  final heightValue = minHeightCm + index;
                  final isMajorTick = heightValue % 10 == 0;
                  final isMediumTick = heightValue % 5 == 0;
                  
                  //Kiểm tra mục đang chọn (để đổi màu)
                  final bool isSelected = (heightValue == _currentHeightCm);

                  //ỖI: Dùng Stack để Text không bị giới hạn chiều rộng
                  return Container(
                    width: itemWidth,
                    child: Stack(
                      clipBehavior: Clip.none, // Cho phép Text tràn ra ngoài
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Vạch kẻ (nằm trong Stack)
                        Positioned(
                          bottom: 23, // Đẩy vạch kẻ lên trên để chừa chỗ cho Text
                          child: Container(
                            width: isSelected ? 4.0 : 2.0, //Tăng độ dày vạch kẻ
                            color: isSelected ? primaryColor : Colors.grey.shade300,
                            height: isSelected ? 140 : (isMajorTick ? 110 : (isMediumTick ? 95 : 85)), //Tăng độ dài vạch kẻ thêm 20
                          ),
                        ),
                        // Nhãn số (nằm trong Stack)
                        Positioned(
                          bottom: 0,
                          child: Text(
                            isMajorTick ? heightValue.toString() : '',
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? primaryColor : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

}

/// Tối ưu hóa: Tách nút chuyển đổi ra một StatefulWidget riêng
/// để việc gọi setState chỉ build lại widget này, không ảnh hưởng đến thước đo.
class UnitToggle extends StatelessWidget {
  final HeightUnit selectedUnit;
  final ValueChanged<HeightUnit> onChanged;
  final Color primaryColor;

  const UnitToggle({
    super.key,
    required this.selectedUnit,
    required this.onChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // "Viên thuốc" trượt
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: selectedUnit == HeightUnit.cm ? 4 : 60,
            right: selectedUnit == HeightUnit.ft ? 4 : 60,
            top: 4,
            bottom: 4,
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          // Các mục văn bản
          Row(
            children: [
              _buildItem(HeightUnit.cm, 'cm'),
              _buildItem(HeightUnit.ft, 'ft'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildItem(HeightUnit unit, String text) {
    final bool isSelected = selectedUnit == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(unit),
        // Dùng Container với màu transparent để tăng vùng có thể nhấn
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}