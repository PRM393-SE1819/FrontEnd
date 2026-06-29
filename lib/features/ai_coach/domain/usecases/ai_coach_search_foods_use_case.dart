import '../../../../core/usecases/usecase.dart';
import '../repositories/ai_coach_repository.dart';

class AiCoachSearchFoodsUseCase implements UseCase<Map<String, dynamic>?, String> {
  final AiCoachRepository repository;

  const AiCoachSearchFoodsUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(String query) {
    return repository.searchFoods(query);
  }
}
