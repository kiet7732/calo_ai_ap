// lib/providers/account_setup_provider.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart'; 
import 'dart:async';
import '../utils/calorie_calculator.dart'; //Import lớp tiện ích tính toán

class AccountSetupProvider extends ChangeNotifier {
  
  // 1. BIẾN ISLOADING (ĐÃ THÊM)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 2. DỮ LIỆU USERPROFILE 
  UserProfile _userProfile = UserProfile(
    uid: '', 
    email: '',
    displayName: '',
    height: 0,
    currentWeight: 0,
    goalWeight: 0,
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

  // Thêm các trường để lưu kết quả dự đoán trực tiếp trong Provider
  int? _predictionWeeks;
  DateTime? _predictionDate;

  int? get predictionWeeks => _predictionWeeks;
  DateTime? get predictionDate => _predictionDate;

  // --- 3. CÁC HÀM UPDATE  ---
  void updateGender(Gender gender) {
    _userProfile = _userProfile.copyWith(gender: gender);
    print("DEBUG: Gender updated to $gender");
    notifyListeners();
  }

  void updateDob(DateTime dob) {
    _userProfile = _userProfile.copyWith(dateOfBirth: dob);
    print("DEBUG: DOB updated to $dob");
    notifyListeners();
  }

  void updateHeight(int height) {
    _userProfile = _userProfile.copyWith(height: height);
    print("DEBUG: Height updated to $height cm");
    notifyListeners();
  }

  void updateWeight({double? current, double? goal}) {
    _userProfile = _userProfile.copyWith(currentWeight: current, goalWeight: goal);
    if (current != null) {
      print("DEBUG: Current Weight updated to $current kg");
    }
    if (goal != null) {
      print("DEBUG: Goal Weight updated to $goal kg");
    }
    notifyListeners();
  }

  void updateActivityLevel(ActivityLevel level) {
    _userProfile = _userProfile.copyWith(activityLevel: level);
    print("DEBUG: Activity Level updated to $level");
    notifyListeners();
  }

  // --- 4. HÀM TÍNH TOÁN ---
  Future<void> calculateCaloriePlan() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // In ra tất cả các tham số đầu vào
    print("--- DEBUG: Calculating with Parameters ---");
    print("Gender: ${_userProfile.gender}");
    print("Height: ${_userProfile.height} cm");
    print("Current Weight: ${_userProfile.currentWeight} kg");
    print("Goal Weight: ${_userProfile.goalWeight} kg");
    print("Date of Birth: ${_userProfile.dateOfBirth}");
    print("Activity Level: ${_userProfile.activityLevel}");
    print("------------------------------------------");

    //Gọi hàm tính toán từ lớp tiện ích
    final CaloriePlanResult? planResult = CalorieCalculator.calculatePlan(
      gender: _userProfile.gender,
      currentWeight: _userProfile.currentWeight,
      height: _userProfile.height,
      dateOfBirth: _userProfile.dateOfBirth,
      activityLevel: _userProfile.activityLevel,
      goalWeight: _userProfile.goalWeight,
    );

    // Nếu kết quả plan là null (do đầu vào không hợp lệ), dừng lại.
    if (planResult == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    //Tính toán dự đoán ngay sau khi có kết quả plan
    final PredictionResult predictionResult = CalorieCalculator.calculatePrediction(
      currentWeight: _userProfile.currentWeight,
      goalWeight: _userProfile.goalWeight,
      dailyAdjustment: planResult.dailyAdjustment,
    );

    //Lưu kết quả dự đoán vào các biến của Provider
    _predictionWeeks = predictionResult.weeksToGoal;
    _predictionDate = predictionResult.targetDate;

    // Cập nhật UserProfile với kết quả
    _userProfile = _userProfile.copyWith(
      calorieGoal: planResult.totalCalories,
      proteinGoal: planResult.proteinGrams,
      carbGoal: planResult.carbGrams,
      fatGoal: planResult.fatGrams,
    );

    _isLoading = false;
    notifyListeners();
    
    // In kết quả cuối cùng
    print("--- DEBUG: Calculation Results ---");
    print("Total Calories: ${planResult.totalCalories} kcal");
    print("Protein: ${planResult.proteinGrams} g");
    print("Carbs: ${planResult.carbGrams} g");
    print("Fat: ${planResult.fatGrams} g");
    print("Prediction: ${predictionResult.weeksToGoal} weeks to reach goal on ${predictionResult.targetDate}");
    print("----------------------------------");

    // TODO: Lưu _userProfile lên Firebase
  }
}