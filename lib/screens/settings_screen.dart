import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth/auth_provider.dart';
import '../utils/app_routes.dart';
import '../widgets/settings/user_profile_display.dart';
import '../widgets/settings/settings_group.dart';
import '../widgets/settings/settings_tile.dart';
import '../widgets/settings/notification_settings_section.dart';
import '../widgets/settings/developer_settings_section.dart';
import '../providers/user_provider.dart';
import '../widgets/settings/edit_value_bottom_sheet.dart';
import '../widgets/settings/new_goal_dialog.dart'; 
import '../widgets/settings/unit_picker_bottom_sheet.dart'; 
import '../widgets/settings/activity_level_bottom_sheet.dart';
import '../widgets/settings/edit_profile_bottom_sheet.dart'; // Import widget mới
import '../models/user_profile.dart'; // Import để dùng Gender
import '../services/CloudinaryService.dart'; // Import service upload

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Giữ nguyên state của màn hình
  bool _isDarkMode = false; // Thêm state cho giao diện tối
  String _weightUnit = 'kg'; // Mặc định hiển thị
  String _heightUnit = 'cm'; // Mặc định hiển thị
  bool _isUploadingAvatar = false; // State quản lý loading khi upload avatar

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

  /// Hàm helper để gọi BottomSheet widget mới
  void _showEditSheet({
    required BuildContext context,
    required String title,
    required double currentValue,
    required String unit,
    required double min,
    required double max,
    required bool isInt,
    required Function(double) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => EditValueBottomSheet(
        title: title,
        initialValue: currentValue,
        unit: unit,
        min: min,
        max: max,
        isInt: isInt,
        onSave: onSave,
      ),
    );
  }

  /// Xử lý chọn ảnh và upload
  Future<void> _handleAvatarEdit(UserProvider userProvider) async {
    final ImagePicker picker = ImagePicker();
    
    // 1. Hiển thị BottomSheet chọn nguồn ảnh
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Chụp ảnh mới'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return; // Người dùng hủy chọn

    try {
      // 2. Pick ảnh (Đưa vào try-catch để bắt lỗi quyền truy cập)
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image == null) return;

      // 3. Bắt đầu upload
      setState(() => _isUploadingAvatar = true);

      final String? secureUrl = await CloudinaryService().uploadImage(File(image.path));
      
      if (secureUrl != null && mounted) {
        await userProvider.updateAvatar(secureUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!")));
        }
      }
    } on PlatformException catch (e) {
      // Bắt lỗi PlatformException riêng (ví dụ lỗi channel, lỗi quyền hạn từ native)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Lỗi hệ thống ảnh: ${e.message}. Vui lòng khởi động lại ứng dụng."),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xảy ra lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy UserProvider để thực hiện hành động update
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Cài đặt'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        // elevation: 1,
      ),
      body: ListView(
        children: [
          
          UserProfileDisplay(
            weightUnit: _weightUnit, 
            heightUnit: _heightUnit,
            isUploading: _isUploadingAvatar,
            onEditAvatar: () {
              _handleAvatarEdit(userProvider);
            },
            onEditName: () {
              final currentProfile = userProvider.userProfile;
              if (currentProfile == null) return;

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                backgroundColor: Colors.white,
                builder: (context) => EditProfileBottomSheet(
                  initialDisplayName: currentProfile.displayName,
                  initialGender: currentProfile.gender,
                  initialDob: currentProfile.dateOfBirth,
                  onSave: (name, gender, dob) async {
                    // Kiểm tra xem có thay đổi gì không
                    if (name == currentProfile.displayName && gender == currentProfile.gender && dob == currentProfile.dateOfBirth) return;

                    final newPlan = await userProvider.updateUserProfile({
                      'displayName': name,
                      'gender': gender.name,
                      'dateOfBirth': dob.toIso8601String(),
                    });

                    if (newPlan != null && context.mounted) {
                      showNewGoalDialog(context, newPlan);
                    }
                  },
                ),
              );
            },
            //cac tham so ng dung
            onEditHeight: () {
              final currentProfile = userProvider
                  .userProfile; // Lấy dữ liệu mới nhất tại thời điểm bấm
              if (currentProfile == null) return;
              
              // Logic quy đổi hiển thị cho Chiều cao
              double valToShow = currentProfile.height.toDouble();
              double min = 100;
              double max = 250;
              bool isInt = true;

              if (_heightUnit == 'ft') {
                valToShow = valToShow * 0.0328084; // cm -> ft
                min = 3.0; max = 8.5; // Giới hạn slider theo ft
                isInt = false;
              }

              //dùng Sheet mới
              _showEditSheet(
                context: context,
                title: "Cập nhật Chiều cao",
                currentValue: valToShow,
                unit: _heightUnit,
                min: min,
                max: max,
                isInt: isInt,
                onSave: (val) async {
                  // Logic quy đổi ngược lại để lưu (ft -> cm)
                  int heightToSave = (_heightUnit == 'ft') ? (val / 0.0328084).round() : val.toInt();

                  if (heightToSave == currentProfile.height) return; // Không thay đổi thì thoát

                  final newPlan = await userProvider.updateUserProfile({
                    'height': heightToSave,
                  });
                  if (newPlan != null && context.mounted) {
                    showNewGoalDialog(context, newPlan);
                  }
                },
              );
            },
            onEditWeight: () {
              final currentProfile = userProvider.userProfile;
              if (currentProfile == null) return;

              // Logic quy đổi hiển thị cho Cân nặng
              double valToShow = currentProfile.currentWeight;
              double min = 30; double max = 200;

              if (_weightUnit == 'lbs') {
                valToShow = valToShow * 2.20462; // kg -> lbs
                min = 66; max = 440; // Giới hạn slider theo lbs
              }

              _showEditSheet(
                context: context,
                title: "Cập nhật Cân nặng",
                currentValue: valToShow,
                unit: _weightUnit,
                min: min,
                max: max,
                isInt: false,
                onSave: (val) async {
                  // Logic quy đổi ngược lại để lưu (lbs -> kg)
                  double weightToSave = (_weightUnit == 'lbs') ? (val / 2.20462) : val;
                  // Làm tròn 1 số thập phân để so sánh chính xác
                  weightToSave = double.parse(weightToSave.toStringAsFixed(1));

                  if (weightToSave == currentProfile.currentWeight) return; // Không thay đổi thì thoát

                  final newPlan = await userProvider.updateUserProfile({
                    'currentWeight': weightToSave,
                  });
                  if (newPlan != null && context.mounted) {
                    showNewGoalDialog(context, newPlan);
                  }
                },
              );
            },
            onEditGoal: () {
              final currentProfile = userProvider.userProfile;
              if (currentProfile == null) return;

              // Logic quy đổi hiển thị cho Mục tiêu
              double valToShow = currentProfile.goalWeight;
              double min = 30; double max = 200;

              if (_weightUnit == 'lbs') {
                valToShow = valToShow * 2.20462; // kg -> lbs
                min = 66; max = 440;
              }

              _showEditSheet(
                context: context,
                title: "Cập nhật Mục tiêu",
                currentValue: valToShow,
                unit: _weightUnit,
                min: min,
                max: max,
                isInt: false,
                onSave: (val) async {
                  // Logic quy đổi ngược lại để lưu (lbs -> kg)
                  double weightToSave = (_weightUnit == 'lbs') ? (val / 2.20462) : val;
                  // Làm tròn 1 số thập phân để so sánh chính xác
                  weightToSave = double.parse(weightToSave.toStringAsFixed(1));

                  if (weightToSave == currentProfile.goalWeight) return; // Không thay đổi thì thoát

                  final newPlan = await userProvider.updateUserProfile({
                    'goalWeight': weightToSave,
                  });
                  if (newPlan != null && context.mounted) {
                    showNewGoalDialog(context, newPlan);
                  }
                },
              );
            },
            onEditActivity: () {
              showActivityLevelBottomSheet(
                context,
                onSelect: (level) async {
                  final newPlan = await userProvider.updateUserProfile({'activityLevel': level.name});
                  if (newPlan != null && context.mounted) {
                    showNewGoalDialog(context, newPlan);
                  }
                },
              );
            },
          ),
        //end sheet
        
          // --- PHẦN THÔNG BÁO ) ---
          const NotificationSettingsSection(),

          SettingsGroup(
            title: 'Chung',
            children: [
              SettingsTile(
                icon: Icons.monitor_weight_outlined,
                iconColor: Colors.purple,
                title: 'Đơn vị cân nặng',
                trailing: Text(_weightUnit, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                onTap: () {
                  showUnitPicker(
                    context,
                    title: 'Chọn đơn vị cân nặng',
                    options: ['kg', 'lbs'],
                    currentValue: _weightUnit,
                    onSelected: (val) => setState(() => _weightUnit = val),
                  );
                },
              ),
              SettingsTile(
                icon: Icons.height,
                iconColor: Colors.teal,
                title: 'Đơn vị chiều cao',
                trailing: Text(_heightUnit, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                onTap: () {
                  showUnitPicker(
                    context,
                    title: 'Chọn đơn vị chiều cao',
                    options: ['cm', 'ft'],
                    currentValue: _heightUnit,
                    onSelected: (val) => setState(() => _heightUnit = val),
                  );
                },
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

          // --- PHẦN DEVELOPER test data user ---
          const DeveloperSettingsSection(),
          //end
        ],
      ),
    );
  }
}
