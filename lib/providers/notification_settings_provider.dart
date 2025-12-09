import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Quản lý trạng thái và logic cho các cài đặt thông báo.
/// Tự động lưu và tải cài đặt từ SharedPreferences.
class NotificationSettingsProvider with ChangeNotifier {
  final NotificationService _notificationService;

  // --- State ---
  bool _mealReminders = false;
  bool _waterReminders = false;
  TimeOfDay _mealReminderTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _waterReminderTime = const TimeOfDay(hour: 9, minute: 0);

  // --- Getters ---
  bool get mealReminders => _mealReminders;
  bool get waterReminders => _waterReminders;
  TimeOfDay get mealReminderTime => _mealReminderTime;
  TimeOfDay get waterReminderTime => _waterReminderTime;

  // --- Keys for SharedPreferences ---
  static const String _mealReminderKey = 'meal_reminder_enabled';
  static const String _waterReminderKey = 'water_reminder_enabled';
  static const String _mealTimeHourKey = 'meal_time_hour';
  static const String _mealTimeMinuteKey = 'meal_time_minute';
  static const String _waterTimeHourKey = 'water_time_hour';
  static const String _waterTimeMinuteKey = 'water_time_minute';

  NotificationSettingsProvider(this._notificationService) { 
    _loadSettings();
  }

  /// Tải cài đặt từ bộ nhớ cục bộ khi provider được khởi tạo.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _mealReminders = prefs.getBool(_mealReminderKey) ?? false;
    _waterReminders = prefs.getBool(_waterReminderKey) ?? false;

    final mealHour = prefs.getInt(_mealTimeHourKey) ?? 12;
    final mealMinute = prefs.getInt(_mealTimeMinuteKey) ?? 0;
    _mealReminderTime = TimeOfDay(hour: mealHour, minute: mealMinute);

    final waterHour = prefs.getInt(_waterTimeHourKey) ?? 9;
    final waterMinute = prefs.getInt(_waterTimeMinuteKey) ?? 0;
    _waterReminderTime = TimeOfDay(hour: waterHour, minute: waterMinute);

    debugPrint("✅ Notification settings loaded.");
    notifyListeners();

    // TỐI ƯU: Sau khi tải cài đặt, tự động lên lịch lại các thông báo đã bật.
    // Điều này đảm bảo thông báo không bị mất sau khi khởi động lại ứng dụng.
    if (_mealReminders) {
      _scheduleMealReminder();
    }
    if (_waterReminders) {
      _scheduleWaterReminder();
    }
  }

  /// Bật/tắt và lưu trạng thái nhắc nhở bữa ăn.
  Future<void> toggleMealReminder(bool isEnabled) async {
    _mealReminders = isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mealReminderKey, isEnabled);

    if (isEnabled) {
      await _scheduleMealReminder();
    } else {
      await _notificationService.cancelNotification(1);
    }
    notifyListeners();
  }

  /// Cập nhật và lưu giờ nhắc nhở bữa ăn.
  Future<void> updateMealReminderTime(TimeOfDay newTime) async {
    _mealReminderTime = newTime;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mealTimeHourKey, newTime.hour);
    await prefs.setInt(_mealTimeMinuteKey, newTime.minute);

    // Nếu đang bật, lên lịch lại với giờ mới
    if (_mealReminders) { 
      await _scheduleMealReminder();
    }
    notifyListeners();
  }

  /// Bật/tắt và lưu trạng thái nhắc nhở uống nước.
  Future<void> toggleWaterReminder(bool isEnabled) async {
    _waterReminders = isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_waterReminderKey, isEnabled);

    if (isEnabled) {
      await _scheduleWaterReminder();
    } else {
      await _notificationService.cancelNotification(2);
    }
    notifyListeners();
  }

  /// Cập nhật và lưu giờ nhắc nhở uống nước.
  Future<void> updateWaterReminderTime(TimeOfDay newTime) async {
    _waterReminderTime = newTime;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_waterTimeHourKey, newTime.hour);
    await prefs.setInt(_waterTimeMinuteKey, newTime.minute);

    // Nếu đang bật, lên lịch lại với giờ mới
    if (_waterReminders) { 
      await _scheduleWaterReminder();
    }
    notifyListeners();
  }

  // --- Private Helper Methods ---

  Future<void> _scheduleMealReminder() async {
    await _notificationService.scheduleDailyNotification(
      id: 1,
      title: 'Đến giờ ăn rồi!',
      body: 'Đừng quên ghi lại bữa ăn của bạn để theo dõi tiến độ nhé.',
      time: _mealReminderTime,
    );
    debugPrint("Provider: Đã yêu cầu lên lịch nhắc nhở bữa ăn lúc $_mealReminderTime.");
  }

  Future<void> _scheduleWaterReminder() async {
    await _notificationService.scheduleDailyNotification(
      id: 2,
      title: 'Uống nước thôi!',
      body: 'Giữ đủ nước là chìa khóa cho sức khỏe.',
      time: _waterReminderTime,
    );
    debugPrint("Provider: Đã yêu cầu lên lịch nhắc nhở uống nước lúc $_waterReminderTime.");
  }
}