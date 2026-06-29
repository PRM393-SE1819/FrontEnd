import '../../../../core/usecases/usecase.dart';
import '../entities/meal.dart';
import '../repositories/meal_repository.dart';

class AddMealUseCase implements UseCase<Meal?, Map<String, dynamic>> {
  final MealRepository repository;

  const AddMealUseCase(this.repository);

  @override
  Future<Meal?> call(Map<String, dynamic> mealData) {
    return repository.addMeal(mealData);
  }
}
