import '../../../../core/usecases/usecase.dart';
import '../../../meal/domain/entities/food.dart';
import '../repositories/food_repository.dart';

class CreateCustomFoodUseCase implements UseCase<Food?, Map<String, dynamic>> {
  final FoodRepository repository;

  const CreateCustomFoodUseCase(this.repository);

  @override
  Future<Food?> call(Map<String, dynamic> foodData) {
    return repository.createCustomFood(foodData);
  }
}
