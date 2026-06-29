import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class UpdateHealthProfileUseCase implements UseCase<bool, Map<String, dynamic>> {
  final ProfileRepository repository;

  const UpdateHealthProfileUseCase(this.repository);

  @override
  Future<bool> call(Map<String, dynamic> profileData) {
    return repository.updateHealthProfile(profileData);
  }
}
