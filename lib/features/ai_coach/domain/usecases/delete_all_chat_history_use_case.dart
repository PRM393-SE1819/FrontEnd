import '../../../../core/usecases/usecase.dart';
import '../repositories/ai_coach_repository.dart';

class DeleteAllChatHistoryUseCase implements UseCase<bool, NoParams> {
  final AiCoachRepository repository;

  const DeleteAllChatHistoryUseCase(this.repository);

  @override
  Future<bool> call(NoParams params) {
    return repository.deleteAllChatHistory();
  }
}
