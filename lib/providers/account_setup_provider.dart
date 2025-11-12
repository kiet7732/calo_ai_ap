// lib/providers/account_setup_provider.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart'; // Import model đã sửa
import 'dart:async';

class AccountSetupProvider extends ChangeNotifier {
  
  // 1. BIẾN ISLOADING (ĐÃ THÊM)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 2. DỮ LIỆU USERPROFILE (Giống của bạn)
  UserProfile _userProfile = UserProfile(
    uid: '', 
    email: '',
    displayName: '',
    height: 170,
    currentWeight: 70.0,
    goalWeight: 65.0,
    dateOfBirth: DateTime(2000, 1, 1),
    gender: Gender.male,
    activityLevel: ActivityLevel.sedentary,
    // Mục tiêu ban đầu = 0
    calorieGoal: 0,
    proteinGoal: 0,
    carbGoal: 0,
    fatGoal: 0,
  );

  UserProfile get userProfile => _userProfile;

  // --- 3. CÁC HÀM UPDATE (Giống của bạn) ---
  void updateGender(Gender gender) {
    _userProfile = _userProfile.copyWith(gender: gender);
    notifyListeners();
  }

  void updateDob(DateTime dob) {
    _userProfile = _userProfile.copyWith(dateOfBirth: dob);
    notifyListeners();
  }

  void updateHeight(int height) {
    _userProfile = _userProfile.copyWith(height: height);
    notifyListeners();
  }

  void updateWeight({double? current, double? goal}) {
    _userProfile = _userProfile.copyWith(currentWeight: current, goalWeight: goal);
    notifyListeners();
  }

  void updateActivityLevel(ActivityLevel level) {
    _userProfile = _userProfile.copyWith(activityLevel: level);
    notifyListeners();
  }

  // --- 4. HÀM TÍNH TOÁN (ĐÃ THÊM ĐỂ SỬA LỖI) ---
  Future<void> calculateCaloriePlan() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // Lấy dữ liệu từ _userProfile
    int age = DateTime.now().year - _userProfile.dateOfBirth.year;
    double bmr;

    if (_userProfile.gender == Gender.male) {
      bmr = (10 * _userProfile.currentWeight) + (6.25 * _userProfile.height) - (5 * age) + 5;
    } else { // Nữ
      bmr = (10 * _userProfile.currentWeight) + (6.25 * _userProfile.height) - (5 * age) - 161;
    }

    double activityMultiplier;
    switch (_userProfile.activityLevel) {
      case ActivityLevel.light:
        activityMultiplier = 1.375;
        break;
      case ActivityLevel.moderate:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.active:
        activityMultiplier = 1.725;
        break;
      default: // Sedentary (Ít vận động)
        activityMultiplier = 1.2;
    }
    double tdee = bmr * activityMultiplier;

    int totalCalories;
    if (_userProfile.goalWeight > _userProfile.currentWeight) {
      totalCalories = (tdee + 500).round(); // Tăng cân
    } else if (_userProfile.goalWeight < _userProfile.currentWeight) {
      totalCalories = (tdee - 500).round(); // Giảm cân
    } else {
      totalCalories = tdee.round(); // Duy trì
    }

    int carbsGrams = ((totalCalories * 0.40) / 4).round();
    int proteinGrams = ((totalCalories * 0.30) / 4).round();
    int fatGrams = ((totalCalories * 0.30) / 9).round();

    // Cập nhật UserProfile với kết quả
    _userProfile = _userProfile.copyWith(
      calorieGoal: totalCalories,
      proteinGoal: proteinGrams,
      carbGoal: carbsGrams,
      fatGoal: fatGrams,
    );

    _isLoading = false;
    notifyListeners();
    
    // TODO: Lưu _userProfile lên Firebase
  }
}