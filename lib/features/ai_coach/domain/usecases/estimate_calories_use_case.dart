import '../../../../core/usecases/usecase.dart';
import '../repositories/ai_coach_repository.dart';

class EstimateCaloriesUseCase implements UseCase<Map<String, dynamic>?, String> {
  final AiCoachRepository repository;

  const EstimateCaloriesUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(String foodDescription) {
    return repository.estimateCalories(foodDescription);
  }
}
