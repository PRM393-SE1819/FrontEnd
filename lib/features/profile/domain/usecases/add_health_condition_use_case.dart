import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class AddHealthConditionParams {
  final String conditionName;
  final String notes;

  const AddHealthConditionParams({required this.conditionName, required this.notes});
}

class AddHealthConditionUseCase implements UseCase<bool, AddHealthConditionParams> {
  final ProfileRepository repository;

  const AddHealthConditionUseCase(this.repository);

  @override
  Future<bool> call(AddHealthConditionParams params) {
    return repository.addHealthCondition(params.conditionName, params.notes);
  }
}
