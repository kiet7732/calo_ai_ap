import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal_analysis_result.dart';
import 'package:provider/provider.dart';
import '../providers/today_stats_provider.dart';
import '../utils/app_routes.dart';

class MealResultScreen extends StatefulWidget {
  final MealAnalysisResult result;
  final XFile imageFile;
  final VoidCallback? onSave;

  const MealResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
    this.onSave,
  });

  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  // Màu sắc chủ đạo
  static const Color primaryOrange = Color(0xFFFF6B6B);
  static const Color secondaryOrange = Color(0xFFFF8E53);
  static const Color proteinColor = Color(0xFF4ECDC4);
  static const Color carbsColor = Color(0xFFFFD93D);
  static const Color fatColor = Color(0xFFA66CFF);

  bool _isSaving = false;

  /// Xóa ảnh tạm khỏi thiết bị để tiết kiệm bộ nhớ
  Future<void> _deleteImage() async {
    try {
      final file = File(widget.imageFile.path);
      if (await file.exists()) {
        await file.delete();
        print("🗑️ Đã xóa ảnh tạm: ${widget.imageFile.path}");
      }
    } catch (e) {
      print("⚠️ Lỗi khi xóa ảnh: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalNutrition = widget.result.totalNutrition;

    return Scaffold(
      backgroundColor: Colors.white,
      // Cho phép nội dung tràn lên status bar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. HEADER IMAGE (Chiếm 40% màn hình)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(widget.imageFile.path)),
                  fit: BoxFit.cover,
                ),
              ),
              // Lớp phủ gradient đen nhẹ để nút Close rõ hơn
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4],
                  ),
                ),
              ),
            ),
          ),

          // 2. NÚT CLOSE (Góc trái trên)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () async {
                await _deleteImage();
                if (mounted) Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),

          // 3. MAIN CONTENT (Card trượt lên đè ảnh)
          Positioned.fill(
            top: size.height * 0.35, // Bắt đầu đè lên ảnh từ vị trí 35%
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Thanh nắm kéo (Visual cue)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Nội dung cuộn
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100), // Padding bottom lớn để tránh nút Sticky
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Tên món ăn
                          Text(
                            widget.result.foodName ?? "Món ăn chưa rõ",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tổng Calo (Nổi bật)
                          _buildCaloriesBadge(totalNutrition.calories),

                          const SizedBox(height: 30),

                          // Grid Macros (Protein, Carbs, Fat)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMacroCard("Protein", totalNutrition.protein, "g", proteinColor, Icons.fitness_center),
                              _buildMacroCard("Carbs", totalNutrition.carbs, "g", carbsColor, Icons.grain),
                              _buildMacroCard("Fat", totalNutrition.fat, "g", fatColor, Icons.water_drop),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Thanh tỷ lệ dinh dưỡng
                          _buildNutritionRatioBar(totalNutrition),

                          const SizedBox(height: 30),

                          // Danh sách thành phần (Expandable)
                          _buildIngredientsList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. STICKY FOOTER (Nút hành động)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút Hủy
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: () async {
                        await _deleteImage();
                        if (mounted) Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        "Hủy",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Nút Lưu
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryOrange, secondaryOrange],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryOrange.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () async {
                          setState(() {
                            _isSaving = true;
                          });

                          // 1. Lưu vào Firestore thông qua Provider (Lệnh dùng chung)
                          try {
                            await context.read<TodayStatsProvider>().addAnalyzedMeal(widget.result);
                          } catch (e) {
                            print("Lỗi lưu món ăn: $e");
                            // Có thể hiện thông báo lỗi ở đây
                          }

                          // 2. Callback cũ (nếu có)
                          if (widget.onSave != null) widget.onSave!();
                          
                          // 3. Xóa ảnh tạm
                          await _deleteImage();
                          
                          // 4. Chuyển về màn hình chính (Home) và xóa lịch sử điều hướng
                          if (mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text(
                                "Xác nhận & Lưu",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesBadge(double calories) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 36, color: Colors.white),
              Text(
                calories.round().toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white, // Màu này sẽ bị ShaderMask ghi đè
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const Text(
          "Kcal",
          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, double value, String unit, Color color, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            "${value.round()}$unit",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRatioBar(NutritionInfo info) {
    double total = info.protein + info.carbs + info.fat;
    if (total == 0) total = 1; // Tránh chia cho 0

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Expanded(flex: (info.protein / total * 100).round(), child: Container(color: proteinColor)),
            Expanded(flex: (info.carbs / total * 100).round(), child: Container(color: carbsColor)),
            Expanded(flex: (info.fat / total * 100).round(), child: Container(color: fatColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text("Chi tiết nguyên liệu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          initiallyExpanded: true,
          children: widget.result.ingredients.map((ing) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8, color: Colors.grey),
              title: Text(ing.query, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              trailing: Text("${ing.nutrition.calories.round()} kcal", style: const TextStyle(color: Colors.grey)),
            );
          }).toList(),
        ),
      ),
    );
  }
}