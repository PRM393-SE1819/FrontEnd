import '../../../meal/domain/entities/food.dart';

abstract class FoodState {
  const FoodState();
}

class FoodInitial extends FoodState {
  const FoodInitial();
}

class FoodLoading extends FoodState {
  const FoodLoading();
}

class FoodSearchSuccess extends FoodState {
  final List<Food> searchResults;
  final List<Food> customFoods;
  final List<Food> favoriteFoods;
  final bool isLoadingFavorites;

  const FoodSearchSuccess({
    required this.searchResults,
    required this.customFoods,
    required this.favoriteFoods,
    this.isLoadingFavorites = false,
  });

  FoodSearchSuccess copyWith({
    List<Food>? searchResults,
    List<Food>? customFoods,
    List<Food>? favoriteFoods,
    bool? isLoadingFavorites,
  }) {
    return FoodSearchSuccess(
      searchResults: searchResults ?? this.searchResults,
      customFoods: customFoods ?? this.customFoods,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      isLoadingFavorites: isLoadingFavorites ?? this.isLoadingFavorites,
    );
  }
}

class FoodError extends FoodState {
  final String message;

  const FoodError({required this.message});
}
