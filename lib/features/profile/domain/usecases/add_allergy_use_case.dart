import '../../../../core/usecases/usecase.dart';
import '../repositories/profile_repository.dart';

class AddAllergyParams {
  final String allergyName;
  final String notes;

  const AddAllergyParams({required this.allergyName, required this.notes});
}

class AddAllergyUseCase implements UseCase<bool, AddAllergyParams> {
  final ProfileRepository repository;

  const AddAllergyUseCase(this.repository);

  @override
  Future<bool> call(AddAllergyParams params) {
    return repository.addAllergy(params.allergyName, params.notes);
  }
}
