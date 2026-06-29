import '../../../../core/usecases/usecase.dart';
import '../../data/models/moderation_item.dart';
import '../repositories/moderation_repository.dart';

class GetResolvedUseCase implements UseCase<List<ModerationItem>, NoParams> {
  final ModerationRepository repository;

  const GetResolvedUseCase(this.repository);

  @override
  Future<List<ModerationItem>> call(NoParams params) {
    return repository.getResolved();
  }
}
