// lib/services/notification_service.dart
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

/// Service để quản lý thông báo cục bộ bằng awesome_notifications.
/// Class này được triển khai theo mẫu Singleton.
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  /// Khởi tạo plugin thông báo.
  /// Phải được gọi trong main() trước khi runApp().
  Future<void> initialize() async {

    await AwesomeNotifications().initialize(
      
      'resource://drawable/icon_app', // Đường dẫn đến icon thông báo
      [ // Định nghĩa các kênh thông báo
        NotificationChannel(
          channelKey: 'daily_reminder_channel_id',
          channelName: 'Daily Reminders',
          channelDescription: 'Kênh cho các thông báo nhắc nhở hàng ngày',
          importance: NotificationImportance.Max,
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
      ],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );

    log("✅ Notification Service Initialized (awesome_notifications).");
  }

  Future<void> requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Nếu chưa có quyền cơ bản, yêu cầu nó trước.
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }


    isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isAllowed) {
      // Kiểm tra xem quyền PreciseAlarms có bị thiếu không
      List<NotificationPermission> missingPermissions =
          await AwesomeNotifications().checkPermissionList(
              permissions: [NotificationPermission.PreciseAlarms]);

      if (missingPermissions.isNotEmpty) {
        // Yêu cầu các quyền còn thiếu
        await AwesomeNotifications().requestPermissionToSendNotifications(permissions: missingPermissions);
      }
    }
  }

  /// Lên lịch thông báo lặp lại hàng ngày vào một giờ cụ thể.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    
    await cancelNotification(id);

    final schedule = NotificationCalendar(
      hour: time.hour,
      minute: time.minute,
      second: 0,
      millisecond: 0,
      repeats: true,
      allowWhileIdle: true,
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'daily_reminder_channel_id',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: schedule,
    );

    final String timeString = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    log("✅ SUCCESS: Notification ID $id scheduled daily at $timeString.");
  }

  /// Hủy một thông báo đã lên lịch theo ID.
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancelSchedule(id);
    
    log("❌ Canceled notification ID $id.");
  }

  /// Hủy tất cả các thông báo đã lên lịch.
  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAllSchedules();
    // Tương tự, không cần gọi cancelAll() ở đây trừ khi bạn muốn xóa tất cả thông báo đang hiển thị.
    log("❌ Canceled all notifications.");
  }

  /// DEBUG: Lên lịch một thông báo test lặp lại mỗi 15 giây.
  /// Dùng để kiểm tra nhanh hệ thống thông báo có hoạt động khi app bị đóng không.
  Future<void> scheduleRepeatedTestNotification() async {
    const int testId = 99;
    const String channelKey = 'daily_reminder_channel_id';

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: testId,
        channelKey: channelKey,
        title: '🔔 Test thông báo liên tục 🔔',
        // Tự định dạng thời gian vì không có BuildContext ở đây
        body: 'Hiển thị lúc: ${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationInterval(
        
        interval: const Duration(seconds: 60),
        repeats: true,
        allowWhileIdle: true, // Rất quan trọng để test khi app bị đóng
        preciseAlarm: true, // Đảm bảo tính chính xác về thời gian
      ),
    );
    log("✅ TEST: Đã lên lịch thông báo lặp lại với ID $testId.");
  }

  /// DEBUG: Hủy thông báo test.
  Future<void> cancelTestNotification() async {
    await cancelNotification(99);
  }
  // --- Private Listeners ---

  @pragma("vm:entry-point")
  static Future<void> _onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    log('Notification action received: ${receivedAction.id}');
    // Xử lý khi người dùng nhấn vào thông báo
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    log('Notification created: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    log('Notification displayed: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    log('Notification dismissed: ${receivedAction.id}');
  }
}
