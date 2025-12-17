import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_profile.dart';

class UserProfileDisplay extends StatelessWidget {
  // Các callback để xử lý sự kiện từ bên ngoài (giúp Widget tái sử dụng tốt hơn)
  final VoidCallback? onEditAvatar;
  final VoidCallback? onEditName;
  final VoidCallback? onEditHeight;
  final VoidCallback? onEditWeight;
  final VoidCallback? onEditGoal;
  final VoidCallback? onEditActivity; // Callback mới
  final String weightUnit; // (kg/lbs)
  final String heightUnit; // (cm/ft)
  final bool isUploading; // Trạng thái đang upload ảnh

  const UserProfileDisplay({
    super.key,
    this.onEditAvatar,
    this.onEditName,
    this.onEditHeight,
    this.onEditWeight,
    this.onEditGoal,
    this.onEditActivity,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.isUploading = false,
  });

  // Màu chủ đạo (Lấy từ theme hoặc định nghĩa cứng)
  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final profile = userProvider.userProfile;

        // 1. Xử lý trạng thái Loading (khi profile null)
        if (profile == null) {
          return Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        // 2. Hiển thị dữ liệu khi đã có
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // --- PHẦN 1: AVATAR & TÊN ---
              _buildHeader(context, profile),

              const SizedBox(height: 15),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 20),

              // --- PHẦN 2: CHỈ SỐ CƠ THỂ ---
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: "Chiều cao",
                      // Nếu là ft thì quy đổi (1 cm = 0.0328 ft), ngược lại giữ nguyên
                      value: heightUnit == 'ft' 
                          ? (profile.height * 0.0328084).toStringAsFixed(1) 
                          : "${profile.height}",
                      unit: heightUnit,
                      icon: Icons.height,
                      color: Colors.blueAccent,
                      onTap: onEditHeight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: "Cân nặng",
                      // Nếu là lbs thì quy đổi (1 kg = 2.20462 lbs)
                      value: weightUnit == 'lbs'
                          ? (profile.currentWeight * 2.20462).toStringAsFixed(1)
                          : "${profile.currentWeight}",
                      unit: weightUnit,
                      icon: Icons.monitor_weight_outlined,
                      color: Colors.orange,
                      onTap: onEditWeight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      label: "Mục tiêu",
                      value: weightUnit == 'lbs'
                          ? (profile.goalWeight * 2.20462).toStringAsFixed(1)
                          : "${profile.goalWeight}",
                      unit: weightUnit,
                      icon: Icons.flag_outlined,
                      color: Colors.purpleAccent,
                      onTap: onEditGoal,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              // --- PHẦN 3: MỨC ĐỘ HOẠT ĐỘNG (Mới) ---
              _buildActivityCard(context, profile),
            ],
          ),
        );
      },
    );
  }

  // Widget con: Thẻ Activity Level nằm ngang
  Widget _buildActivityCard(BuildContext context, UserProfile profile) {
    final info = _getActivityInfo(profile.activityLevel);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEditActivity,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mức độ hoạt động",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // Helper để lấy thông tin hiển thị từ Enum
  ({String label, IconData icon, Color color}) _getActivityInfo(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return (label: "Ít vận động", icon: Icons.airline_seat_recline_normal_rounded, color: Colors.blue);
      case ActivityLevel.light:
        return (label: "Vận động nhẹ", icon: Icons.directions_walk_rounded, color: const Color.fromARGB(255, 102, 0, 197));
      case ActivityLevel.moderate:
        return (label: "Vận động vừa", icon: Icons.directions_run_rounded, color: Colors.orange);
      case ActivityLevel.veryActive:
        return (label: "Vận động nhiều", icon: Icons.fitness_center_rounded, color: Colors.red);
      default:
        return (label: "Không xác định", icon: Icons.help_outline, color: Colors.grey);
    }
  }

  // Widget con: Header (Avatar + Tên)
  Widget _buildHeader(BuildContext context, UserProfile profile) {
    return Column(
      children: [
        // Avatar Stack
        Stack(
          children: [
            Container(
              width: 120,
              height:120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color.fromARGB(255, 52, 182, 0), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(strokeWidth: 3, color: primaryColor),
                        )
                      : (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: profile.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.person, size: 40, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.person, size: 40, color: Colors.grey),
                            ),
                ),
              ),
            ),
            // Nút Edit Avatar (Camera Icon)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onEditAvatar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Tên hiển thị + Nút sửa tên
        GestureDetector(
          onTap: onEditName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  profile.displayName.isNotEmpty ? profile.displayName : "Chưa đặt tên",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.email,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // Widget con: Thẻ chỉ số (Stat Card)
  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), // Màu nền nhạt theo tông màu chính
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}