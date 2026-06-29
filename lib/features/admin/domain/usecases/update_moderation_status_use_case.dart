import '../../../../core/usecases/usecase.dart';
import '../../data/models/moderation_item.dart';
import '../repositories/moderation_repository.dart';

class UpdateModerationStatusParams {
  final String id;
  final ModerationStatus status;

  const UpdateModerationStatusParams({required this.id, required this.status});
}

class UpdateModerationStatusUseCase implements UseCase<void, UpdateModerationStatusParams> {
  final ModerationRepository repository;

  const UpdateModerationStatusUseCase(this.repository);

  @override
  Future<void> call(UpdateModerationStatusParams params) {
    return repository.updateStatus(params.id, params.status);
  }
}
