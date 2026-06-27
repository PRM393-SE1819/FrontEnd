class UserProfile {
  final String fullName;
  final String email;
  final String gender;
  final DateTime dateOfBirth;
  final double height;
  final double weight;
  final String activityLevel;
  final String goal;
  final double? targetWeight;
  final double bmi;
  final int caloriesTarget;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
    this.targetWeight,
    required this.bmi,
    required this.caloriesTarget,
  });
}
