import '../entities/user_profile.dart';
import '../entities/allergy.dart';
import '../entities/health_condition.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getHealthProfile();
  Future<bool> updateHealthProfile(Map<String, dynamic> profileData);
  Future<List<Allergy>?> getAllergies();
  Future<bool> addAllergy(String allergyName, String notes);
  Future<bool> updateAllergy(int allergyId, String allergyName);
  Future<bool> deleteAllergy(int allergyId);
  Future<List<HealthCondition>?> getHealthConditions();
  Future<bool> addHealthCondition(String conditionName, String notes);
  Future<bool> updateHealthCondition(int conditionId, String conditionName, String notes);
  Future<bool> deleteHealthCondition(int conditionId);
  Future<bool> logout();
}
