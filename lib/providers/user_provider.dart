import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../utils/calorie_calculator.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  UserProfile? get userProfile => _userProfile;
  bool get hasData => _userProfile != null;

  UserProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      //print ("[UserProvider] Auth state changed. User: ${user?.uid}");
      _userSubscription?.cancel();
      if (user != null) {
        _listenToUserData(user.uid);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  void _listenToUserData(String uid) {
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          // Map dữ liệu từ Firestore sang UserProfile model
          _userProfile = UserProfile.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
          notifyListeners();
        } catch (e) {
          if (kDebugMode) print(" [UserProvider] Error parsing UserProfile: $e");
        }
      }
    }, onError: (e) {
      if (kDebugMode) print(" [UserProvider] Firestore error: $e");
    });
  }

  /// Cập nhật thông tin người dùng lên Firestore
  Future<CaloriePlanResult?> updateUserProfile(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // Cần _userProfile hiện tại để lấy các trường không bị thay đổi (ví dụ: sửa cân nặng thì cần lấy chiều cao cũ để tính)
    if (user != null && _userProfile != null) {
      try {
        // 1. Cập nhật thông tin cơ bản (Profile)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(data);

        // 2. Kiểm tra xem các trường thay đổi có ảnh hưởng đến TDEE/BMR không
        final keysAffectingGoals = ['currentWeight', 'goalWeight', 'height', 'dateOfBirth', 'gender', 'activityLevel'];
        bool shouldRecalculate = data.keys.any((k) => keysAffectingGoals.contains(k));

        if (shouldRecalculate) {
          // Lấy dữ liệu mới nhất: Ưu tiên từ 'data' (mới sửa), nếu không có thì lấy từ '_userProfile' (cũ)
          final double currentWeight = (data['currentWeight'] ?? _userProfile!.currentWeight).toDouble();
          final double goalWeight = (data['goalWeight'] ?? _userProfile!.goalWeight).toDouble();
          final int height = (data['height'] ?? _userProfile!.height).toInt();
          
          // Xử lý Gender (nếu có thay đổi)
          Gender gender = _userProfile!.gender;
          if (data.containsKey('gender')) {
            final val = data['gender'];
            if (val is String) {
              gender = Gender.values.firstWhere((e) => e.name == val, orElse: () => gender);
            }
          }

          // Xử lý DateOfBirth (nếu có thay đổi)
          DateTime dateOfBirth = _userProfile!.dateOfBirth;
          if (data.containsKey('dateOfBirth')) {
            final val = data['dateOfBirth'];
            if (val is String) {
              dateOfBirth = DateTime.tryParse(val) ?? dateOfBirth;
            }
          }

          // Xử lý ActivityLevel (nếu có thay đổi trong data)
          ActivityLevel activityLevel = _userProfile!.activityLevel;
          if (data.containsKey('activityLevel')) {
            final val = data['activityLevel'];
            if (val is String) {
              activityLevel = ActivityLevel.values.firstWhere((e) => e.name == val, orElse: () => activityLevel);
            }
          }

          // Tính toán lại Plan
          final plan = CalorieCalculator.calculatePlan(
            gender: gender, 
            currentWeight: currentWeight,
            height: height,
            dateOfBirth: dateOfBirth,
            activityLevel: activityLevel,
            goalWeight: goalWeight,
          );

          // 3. Cập nhật Goals mới vào Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('goals')
              .doc('current')
              .set({
            'calorieGoal': plan.totalCalories,
            'proteinGoal': plan.proteinGrams,
            'carbGoal': plan.carbGrams,
            'fatGoal': plan.fatGrams,
          }, SetOptions(merge: true));

          if (kDebugMode) print("[UserProvider] Goals recalculated and updated.");
          return plan; // Trả về kế hoạch mới để UI hiển thị
        }
      } catch (e) {
        if (kDebugMode) print("❌ [UserProvider] Error updating profile: $e");
        rethrow;
      }
    }
    return null; // Không có tính toán lại hoặc user null
  }

  /// Cập nhật riêng Avatar (Không ảnh hưởng đến tính toán Calo)
  Future<void> updateAvatar(String photoUrl) async {
    // Tận dụng hàm update có sẵn, hàm này sẽ trả về null vì không có trường nào ảnh hưởng đến TDEE
    await updateUserProfile({'photoUrl': photoUrl});
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}