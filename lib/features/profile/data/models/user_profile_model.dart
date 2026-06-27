import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.fullName,
    required super.email,
    required super.gender,
    required super.dateOfBirth,
    required super.height,
    required super.weight,
    required super.activityLevel,
    required super.goal,
    super.targetWeight,
    required super.bmi,
    required super.caloriesTarget,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      fullName: json['fullName'] ?? 'Người dùng',
      email: json['email'] ?? '',
      gender: json['gender'] ?? 'Male',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().subtract(const Duration(days: 365 * 25)).toIso8601String()),
      height: (json['height'] as num?)?.toDouble() ?? 170.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 70.0,
      activityLevel: json['activityLevel'] ?? 'ModeratelyActive',
      goal: json['goal'] ?? 'MaintainWeight',
      targetWeight: json['targetWeight'] != null ? (json['targetWeight'] as num).toDouble() : null,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      caloriesTarget: (json['caloriesTarget'] as num?)?.toInt() ?? 2000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'gender': gender,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'goal': goal,
      'targetWeight': targetWeight,
      'bmi': bmi,
      'caloriesTarget': caloriesTarget,
    };
  }
}
