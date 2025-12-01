// lib/models/user_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Định nghĩa các Enum (Kiểu dữ liệu)
enum Gender { male, female, other }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class UserProfile {
  // Thêm trường setupComplete
  // Trường này sẽ được lưu vào Firestore để kiểm tra ở lần đăng nhập sau
  final bool setupComplete;

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl; //Để lưu ảnh đại diện từ Google
  final DateTime? createdAt; //Để lưu thời điểm tạo tài khoản
  
  // Dữ liệu sinh trắc học
  final int height; // (cm)
  final double currentWeight; // (kg)
  final double goalWeight; // (kg)
  final DateTime dateOfBirth;
  final Gender gender;
  final ActivityLevel activityLevel;

  // Mục tiêu (Kết quả tính toán)
  final int calorieGoal;
  final int proteinGoal;
  final int carbGoal;
  final int fatGoal;

  const UserProfile({
    this.setupComplete = false, // Giá trị mặc định
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
    required this.height,
    required this.currentWeight,
    required this.goalWeight,
    required this.dateOfBirth,
    required this.gender,
    required this.activityLevel,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
  });

  // 2. HÀM COPYWITH 
  // Hàm này cho phép bạn tạo một bản sao của UserProfile
  // nhưng thay đổi một vài giá trị (giúp code trong Provider sạch sẽ)
  UserProfile copyWith({
    String? uid,
    bool? setupComplete,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? height,
    double? currentWeight,
    double? goalWeight,
    DateTime? dateOfBirth,
    Gender? gender,
    ActivityLevel? activityLevel,
    int? calorieGoal,
    int? proteinGoal,
    int? carbGoal,
    int? fatGoal,
  }) {
    return UserProfile(
      setupComplete: setupComplete ?? this.setupComplete,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      goalWeight: goalWeight ?? this.goalWeight,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
    );
  }

  // 3. HÀM TOJSON
  // Chuyển đổi đối tượng UserProfile thành một Map để lưu lên Firestore.
  Map<String, dynamic> toJson() {
    return {
      'setupComplete': setupComplete,
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'height': height,
      'currentWeight': currentWeight,
      'goalWeight': goalWeight,
      // Chuyển đổi DateTime thành chuỗi ISO 8601 (chuẩn để lưu trữ)
      'dateOfBirth': dateOfBirth.toIso8601String(),
      // Chuyển đổi Enum thành String (dùng .name)
      'gender': gender.name,
      'activityLevel': activityLevel.name,
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbGoal': carbGoal,
      'fatGoal': fatGoal,
    };
  }

  // 4. FACTORY FROMFIRESTORE 
  // Tạo một đối tượng UserProfile từ một DocumentSnapshot của Firestore.
  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      setupComplete: data['setupComplete'] ?? false,
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      height: data['height'] ?? 0,
      currentWeight: (data['currentWeight'] ?? 0.0).toDouble(),
      goalWeight: (data['goalWeight'] ?? 0.0).toDouble(),
      // Chuyển đổi chuỗi ISO 8601 về lại DateTime
      dateOfBirth: DateTime.parse(data['dateOfBirth']),
      // Chuyển đổi String về lại Enum
      gender: Gender.values.byName(data['gender'] ?? 'other'),
      activityLevel: ActivityLevel.values.byName(data['activityLevel'] ?? 'sedentary'),
      calorieGoal: data['calorieGoal'] ?? 0,
      proteinGoal: data['proteinGoal'] ?? 0,
      carbGoal: data['carbGoal'] ?? 0,
      fatGoal: data['fatGoal'] ?? 0,
    );
  }
}