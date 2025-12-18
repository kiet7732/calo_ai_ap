import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/seed_meals_service.dart';
import '../../services/seed_data_service.dart';
import '../../services/notification_service.dart';

class DeveloperSettingsSection extends StatelessWidget {
  const DeveloperSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 17),
        // --- KHU VỰC TEST TẠO DỮ LIỆU MẪU ---
        ElevatedButton(
          onPressed: () async {
            await SeedMealsService().seedMealsToFirestore();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tạo dữ liệu lịch sử món ăn!'),
                ),
              );
            }
          },
          child: const Text("Tạo Dữ Liệu Món Ăn Mẫu"),
        ),

        ElevatedButton(
          onPressed: () async {
            await SeedDataService().seedCurrentMeals();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã thêm dữ liệu hôm nay!')),
              );
            }
          },
          child: const Text("Tạo Dữ Liệu Hôm Nay"),
        ),
        const SizedBox(height: 20),
        // --- KHU VỰC TEST THÔNG BÁO ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Text(
                "--- Dành cho nhà phát triển ---",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  context.read<NotificationService>().scheduleRepeatedTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã bắt đầu gửi thông báo test mỗi 15 giây.')),
                  );
                },
                icon: const Icon(Icons.play_circle_fill),
                label: const Text("Bắt đầu Test thông báo liên tục"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  context.read<NotificationService>().cancelTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã dừng gửi thông báo test.')),
                  );
                },
                icon: const Icon(Icons.stop_circle),
                label: const Text("Dừng Test thông báo"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}