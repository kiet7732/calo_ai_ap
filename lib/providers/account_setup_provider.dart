// lib/providers/account_setup_provider.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    height: 170,
    currentWeight: 70,
    goalWeight: 50,
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

  /// Cập nhật chiều cao mà không thông báo cho các listener.
  /// Dùng cho sự kiện `onChanged` của Slider để tránh lag.
  void updateHeightSilently(int height) {
    _userProfile = _userProfile.copyWith(height: height);
    // Không gọi notifyListeners() ở đây
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

  /// Cập nhật cân nặng mà không thông báo cho các listener.
  /// Dùng cho sự kiện `onChanged` của Slider để tránh lag.
  void updateWeightSilently({double? current, double? goal}) {
    _userProfile = _userProfile.copyWith(currentWeight: current, goalWeight: goal);
    // Không gọi notifyListeners() ở đây
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

    // BỎ TODO: Việc lưu sẽ được thực hiện ở hàm riêng
  }

  // --- 5. HÀM LƯU DỮ LIỆU LÊN FIRESTORE ---.
  Future<bool> saveUserProfileToFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Người dùng chưa đăng nhập. Không thể lưu dữ liệu.");
      }

      // Cập nhật _userProfile với thông tin từ Auth
      _userProfile = _userProfile.copyWith(
        uid: currentUser.uid,
        email: currentUser.email,
        displayName: currentUser.displayName,
      );

      // 1. Chuẩn bị WriteBatch
      final batch = FirebaseFirestore.instance.batch();

      // 2. Chuẩn bị dữ liệu và vị trí lưu cho PHẦN HỒ SƠ
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final profileData = {
        'uid': _userProfile.uid,
        'email': _userProfile.email,
        'displayName': _userProfile.displayName,
        'photoUrl': currentUser.photoURL,
        'height': _userProfile.height,
        'currentWeight': _userProfile.currentWeight,
        'goalWeight': _userProfile.goalWeight,
        'dateOfBirth': Timestamp.fromDate(_userProfile.dateOfBirth),
        'gender': _userProfile.gender.name,
        'activityLevel': _userProfile.activityLevel.name,
        'setupComplete': true, // Đánh dấu đã hoàn tất thiết lập
        'createdAt': FieldValue.serverTimestamp(), // Thêm thời gian tạo
      };
      batch.set(userDocRef, profileData, SetOptions(merge: true)); // Dùng merge để an toàn

      // 3. Chuẩn bị dữ liệu và vị trí lưu cho PHẦN MỤC TIÊU
      final goalDocRef = userDocRef.collection('goals').doc('current');
      final goalData = {
        'calorieGoal': _userProfile.calorieGoal,
        'proteinGoal': _userProfile.proteinGoal,
        'carbGoal': _userProfile.carbGoal,
        'fatGoal': _userProfile.fatGoal,
      };
      batch.set(goalDocRef, goalData);

      // 4. Thực thi batch
      await batch.commit();

      print("✅ SUCCESS: User profile and goals saved atomically for UID: ${currentUser.uid}");
      return true; // Trả về true nếu thành công
    } catch (e) {
      print("❌ ERROR saving user profile and goals to Firestore: $e");
      return false; // Trả về false nếu có lỗi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}