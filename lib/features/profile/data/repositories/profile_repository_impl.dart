import '../../domain/entities/user_profile.dart';
import '../../domain/entities/allergy.dart';
import '../../domain/entities/health_condition.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  const ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfile?> getHealthProfile() async {
    return await remoteDataSource.getHealthProfile();
  }

  @override
  Future<bool> updateHealthProfile(Map<String, dynamic> profileData) async {
    return await remoteDataSource.updateHealthProfile(profileData);
  }

  @override
  Future<List<Allergy>?> getAllergies() async {
    return await remoteDataSource.getAllergies();
  }

  @override
  Future<bool> addAllergy(String allergyName, String notes) async {
    return await remoteDataSource.addAllergy(allergyName, notes);
  }

  @override
  Future<bool> updateAllergy(int allergyId, String allergyName) async {
    return await remoteDataSource.updateAllergy(allergyId, allergyName);
  }

  @override
  Future<bool> deleteAllergy(int allergyId) async {
    return await remoteDataSource.deleteAllergy(allergyId);
  }

  @override
  Future<List<HealthCondition>?> getHealthConditions() async {
    return await remoteDataSource.getHealthConditions();
  }

  @override
  Future<bool> addHealthCondition(String conditionName, String notes) async {
    return await remoteDataSource.addHealthCondition(conditionName, notes);
  }

  @override
  Future<bool> updateHealthCondition(int conditionId, String conditionName, String notes) async {
    return await remoteDataSource.updateHealthCondition(conditionId, conditionName, notes);
  }

  @override
  Future<bool> deleteHealthCondition(int conditionId) async {
    return await remoteDataSource.deleteHealthCondition(conditionId);
  }

  @override
  Future<bool> logout() async {
    return await remoteDataSource.logout();
  }
}
