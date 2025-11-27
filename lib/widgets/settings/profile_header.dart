// lib/widgets/settings/profile_header.dart
import 'package:flutter/material.dart';

/// Widget hiển thị phần đầu trang cá nhân trong màn hình Cài đặt.
/// Được thiết kế lại với bố cục tập trung vào người dùng và các nút hành động rõ ràng.
class ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? imageUrl; // Thêm imageUrl để hiển thị ảnh đại diện thật
  final VoidCallback? onEdit;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.imageUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      width: double.infinity, // Đảm bảo Column có thể căn giữa nội dung
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- 1. AVATAR VỚI NÚT CHỈNH SỬA ---
          Stack(
            clipBehavior: Clip.none, // Cho phép nút nhỏ tràn ra ngoài
            children: [
              // Lớp dưới: Avatar lớn
              CircleAvatar(
                radius: 52, // Lớn hơn một chút để chứa viền
                backgroundColor: const Color(0xFFA8D15D),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                  child: imageUrl == null
                      ? const Icon(
                          Icons.person_outline,
                          size: 50,
                          color: Color(0xFFA8D15D),
                        )
                      : null,
                ),
              ),
              // Lớp trên: Nút chỉnh sửa nhỏ
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFA8D15D),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // --- 2. THÔNG TIN NGƯỜI DÙNG ---
          Text(
            name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),

          // --- 3. NÚT HÀNH ĐỘNG ---
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_square, size: 20),
            label: const Text('Chỉnh sửa hồ sơ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA8D15D),
              side: const BorderSide(color: Color(0xFFA8D15D), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }
}