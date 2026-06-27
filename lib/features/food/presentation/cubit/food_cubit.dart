import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../meal/domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import 'food_state.dart';

class FoodCubit extends Cubit<FoodState> {
  final FoodRepository repository;

  List<Food> _searchResults = [];
  List<Food> _favoriteFoods = [];
  List<Food> _customFoods = [];
  String _currentQuery = "";

  FoodCubit({required this.repository}) : super(const FoodInitial());

  Future<void> loadFavorites() async {
    final currentState = state;
    if (currentState is FoodSearchSuccess) {
      emit(currentState.copyWith(isLoadingFavorites: true));
    }
    
    try {
      final favorites = await repository.getFavoriteFoods();
      _favoriteFoods = favorites;
      
      _emitSuccessState(isLoadingFavorites: false);
    } catch (_) {
      _emitSuccessState(isLoadingFavorites: false);
    }
  }

  Future<void> performSearch(String query) async {
    _currentQuery = query;
    emit(const FoodLoading());
    try {
      if (_favoriteFoods.isEmpty) {
        _favoriteFoods = await repository.getFavoriteFoods();
      }

      final result = await repository.searchFoods(query);
      if (result != null && result.containsKey('items')) {
        final List<Food> items = List<Food>.from(result['items']);
        
        items.sort((a, b) {
          final aCustom = (a.isCustom || a.foodType == 'Custom') ? 1 : 0;
          final bCustom = (b.isCustom || b.foodType == 'Custom') ? 1 : 0;
          if (aCustom != bCustom) {
            return bCustom.compareTo(aCustom);
          }
          final aFav = _favoriteFoods.any((f) => f.foodId == a.foodId) ? 1 : 0;
          final bFav = _favoriteFoods.any((f) => f.foodId == b.foodId) ? 1 : 0;
          return bFav.compareTo(aFav);
        });

        _searchResults = items;
        _customFoods = _searchResults.where((food) => food.isCustom || food.foodType == 'Custom').toList();
        
        _emitSuccessState();
      } else {
        emit(const FoodError(message: "Failed to search foods."));
      }
    } catch (e) {
      emit(FoodError(message: e.toString()));
    }
  }

  Future<bool> toggleFavorite(Food food) async {
    final isFav = _favoriteFoods.any((f) => f.foodId == food.foodId);
    bool success;
    try {
      if (isFav) {
        success = await repository.removeFavoriteFood(food.foodId);
        if (success) {
          _favoriteFoods.removeWhere((f) => f.foodId == food.foodId);
        }
      } else {
        success = await repository.addFavoriteFood(food.foodId);
        if (success) {
          _favoriteFoods = await repository.getFavoriteFoods();
        }
      }
      
      _emitSuccessState();
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<Food?> scanBarcode(String barcode) async {
    try {
      final result = await repository.scanBarcode(barcode);
      if (result != null && result['found'] == true) {
        return result['food'] as Food?;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> createCustomFood(Map<String, dynamic> foodData) async {
    try {
      final created = await repository.createCustomFood(foodData);
      if (created != null) {
        await performSearch(_currentQuery);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateCustomFood(int foodId, Map<String, dynamic> foodData) async {
    try {
      final updated = await repository.updateCustomFood(foodId, foodData);
      if (updated != null) {
        await performSearch(_currentQuery);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCustomFood(int foodId) async {
    try {
      final success = await repository.deleteCustomFood(foodId);
      if (success) {
        await performSearch(_currentQuery);
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _emitSuccessState({bool isLoadingFavorites = false}) {
    emit(FoodSearchSuccess(
      searchResults: _searchResults,
      customFoods: _customFoods,
      favoriteFoods: _favoriteFoods,
      isLoadingFavorites: isLoadingFavorites,
    ));
  }
}
