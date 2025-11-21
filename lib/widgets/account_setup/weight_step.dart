// lib/providers/accout_setup/weight_step.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/account_setup_provider.dart';
import '../account_setup/step_container.dart';

enum WeightUnit { kg, lbs }

class WeightStep extends StatefulWidget {
  final bool isGoalWeight;
  const WeightStep({super.key, required this.isGoalWeight});

  @override
  State<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends State<WeightStep> {
  static const Color primaryColor = Color(0xFFA8D15D);
  static const double minWeightKg = 30.0;
  static const double maxWeightKg = 250.0;
 static const double itemWidth = 16.0; 
  static const double rulerHeight = 180.0;

  late ScrollController _scrollController;
  WeightUnit _selectedUnit = WeightUnit.kg;
  double _currentWeightKg = 70.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AccountSetupProvider>();
    _currentWeightKg = (widget.isGoalWeight
            ? provider.userProfile.goalWeight
            : provider.userProfile.currentWeight) ??
        70.0;

    // Mỗi 0.1kg là một item.
    final initialOffset = (_currentWeightKg - minWeightKg) * 10 * itemWidth;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatWeight() {
    if (_selectedUnit == WeightUnit.lbs) {
      final double weightInLbs = _currentWeightKg * 2.20462;
      return "${weightInLbs.toStringAsFixed(1)} lbs";
    }
    return "${_currentWeightKg.toStringAsFixed(1)} kg";
  }

  void _handleScrollNotification(ScrollNotification notification) {
    // Mỗi 0.1kg là một index.
    final centerIndex = (_scrollController.offset / itemWidth).round();
    final newWeight = minWeightKg + (centerIndex / 10.0);

    if (notification is ScrollUpdateNotification) {
      if ((_currentWeightKg - newWeight).abs() > 0.01) {
        setState(() {
          _currentWeightKg = newWeight;
        });
      }
    }

    if (notification is ScrollEndNotification) {
      final snapOffset = centerIndex * itemWidth;
      if ((_scrollController.offset - snapOffset).abs() > 0.1) {
        _scrollController.animateTo(
          snapOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      final finalWeight = minWeightKg + (centerIndex / 10.0);
      if (widget.isGoalWeight) {
        context.read<AccountSetupProvider>().updateWeight(goal: finalWeight);
      } else {
        context.read<AccountSetupProvider>().updateWeight(current: finalWeight);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return StepContainer(
      title: widget.isGoalWeight ? "Cân nặng mong muốn?" : "Cân nặng hiện tại?",
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Nút chuyển đổi đơn vị
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
              ButtonSegment(value: WeightUnit.lbs, label: Text('lbs')),
            ],
            selected: {_selectedUnit},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedUnit = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              selectedBackgroundColor: primaryColor,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          // Hiển thị giá trị
          Text(
            _formatWeight(),
            style: const TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const Spacer(flex: 2),
          // Thước đo ngang
          SizedBox(
            height: rulerHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _handleScrollNotification(notification);
                return true;
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth / 2),
                itemCount: ((maxWeightKg - minWeightKg) * 10).toInt() + 1,
                itemBuilder: (context, index) {
                  final weightValue = minWeightKg + (index / 10.0);
                  // Vạch chính cho mỗi 1kg
                  final isMajorTick = index % 10 == 0;
                  // Vạch vừa cho mỗi 0.5kg
                  final isMediumTick = index % 5 == 0;

                  final bool isSelected = (_currentWeightKg - weightValue).abs() < 0.05;

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
                            width: isSelected ? 4.0 : 2.0, // SỬA: Tăng độ dày vạch kẻ
                            color: isSelected ? primaryColor : Colors.grey.shade300,
                            height: isSelected ? 140 : (isMajorTick ? 110 : (isMediumTick ? 95 : 85)), // SỬA: Tăng độ dài vạch kẻ thêm 20
                          ),
                        ),
                        // Nhãn số (nằm trong Stack)
                        Positioned(
                          bottom: 0,
                          child: Text(
                            isMajorTick ? weightValue.toString() : '',
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