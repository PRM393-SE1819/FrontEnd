import '../../../../core/usecases/usecase.dart';
import '../repositories/food_repository.dart';

class SearchFoodsParams {
  final String query;
  final int page;
  final int pageSize;

  const SearchFoodsParams({
    required this.query,
    this.page = 1,
    this.pageSize = 100,
  });
}

class SearchFoodsUseCase implements UseCase<Map<String, dynamic>?, SearchFoodsParams> {
  final FoodRepository repository;

  const SearchFoodsUseCase(this.repository);

  @override
  Future<Map<String, dynamic>?> call(SearchFoodsParams params) {
    return repository.searchFoods(params.query, page: params.page, pageSize: params.pageSize);
  }
}
