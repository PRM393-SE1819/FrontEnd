import '../../../../core/usecases/usecase.dart';
import '../../data/models/moderation_item.dart';
import '../repositories/moderation_repository.dart';

class GetQueueUseCase implements UseCase<List<ModerationItem>, NoParams> {
  final ModerationRepository repository;

  const GetQueueUseCase(this.repository);

  @override
  Future<List<ModerationItem>> call(NoParams params) {
    return repository.getQueue();
  }
}
