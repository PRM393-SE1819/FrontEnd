import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/network/api_service.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/water/data/datasources/water_remote_data_source.dart';
import '../features/water/data/repositories/water_repository_impl.dart';
import '../features/water/domain/repositories/water_repository.dart';
import '../features/water/presentation/cubit/water_cubit.dart';
import '../features/weight/data/datasources/weight_remote_datasource.dart';
import '../features/weight/data/repositories/weight_repository_impl.dart';
import '../features/weight/domain/repositories/weight_repository.dart';
import '../features/weight/presentation/cubit/weight_cubit.dart';
import '../features/meal/data/datasources/meal_remote_datasource.dart';
import '../features/meal/data/repositories/meal_repository_impl.dart';
import '../features/meal/domain/repositories/meal_repository.dart';
import '../features/profile/data/datasources/profile_remote_datasource.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/admin/data/datasources/moderation_mock_data_source.dart';
import '../features/admin/data/datasources/moderation_remote_data_source.dart';
import '../features/admin/data/repositories/moderation_repository_impl.dart';
import '../features/admin/domain/repositories/moderation_repository.dart';
import '../features/admin/data/datasources/user_registry_mock_data_source.dart';
import '../features/admin/data/datasources/user_registry_remote_data_source.dart';
import '../features/admin/data/repositories/user_registry_repository_impl.dart';
import '../features/admin/domain/repositories/user_registry_repository.dart';
import '../features/admin/data/datasources/analytics_mock_data_source.dart';
import '../features/admin/data/datasources/analytics_remote_data_source.dart';
import '../features/admin/data/repositories/analytics_repository_impl.dart';
import '../features/admin/domain/repositories/analytics_repository.dart';
import '../features/admin/data/datasources/alerts_mock_data_source.dart';
import '../features/admin/data/repositories/alerts_repository_impl.dart';
import '../features/admin/domain/repositories/alerts_repository.dart';
import '../features/ai_coach/data/datasources/ai_coach_remote_datasource.dart';
import '../features/ai_coach/data/repositories/ai_coach_repository_impl.dart';
import '../features/ai_coach/domain/repositories/ai_coach_repository.dart';
import '../features/ai_coach/presentation/cubit/ai_coach_cubit.dart';
import '../features/meal/presentation/cubit/meal_cubit.dart';
import '../features/profile/presentation/cubit/profile_cubit.dart';
import '../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../features/food/data/datasources/food_remote_datasource.dart';
import '../features/food/data/repositories/food_repository_impl.dart';
import '../features/food/domain/repositories/food_repository.dart';
import '../features/food/presentation/cubit/food_cubit.dart';


final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Core Services
  getIt.registerLazySingleton<http.Client>(() => http.Client());
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  getIt.registerLazySingleton<ApiService>(() => const ApiService());

  // Auth Feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => const AuthRemoteDataSource());
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()));

  // Water Feature
  getIt.registerLazySingleton<WaterRemoteDataSource>(() => WaterRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<WaterRepository>(() => WaterRepositoryImpl(
        remoteDataSource: getIt<WaterRemoteDataSource>(),
        storage: getIt<FlutterSecureStorage>(),
      ));

  // Weight Feature
  getIt.registerLazySingleton<WeightRemoteDataSource>(() => WeightRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<WeightRepository>(() => WeightRepositoryImpl(
        remoteDataSource: getIt<WeightRemoteDataSource>(),
      ));

  // Meal Feature
  getIt.registerLazySingleton<MealRemoteDataSource>(() => MealRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<MealRepository>(() => MealRepositoryImpl(
        remoteDataSource: getIt<MealRemoteDataSource>(),
      ));

  // Profile Feature
  getIt.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(
        remoteDataSource: getIt<ProfileRemoteDataSource>(),
      ));

  // =========================================================================
  // ADMIN FEATURES
  // Mỗi feature đăng ký theo interface DataSource. Để chuyển MOCK <-> API
  // thật, chỉ cần đổi đúng 1 dòng ("=> ...RemoteDataSource()" thành
  // "=> ...MockDataSource()"). Repository và UI không phải sửa.
  // =========================================================================

  // Admin - Moderation  (API: GET/PUT /api/admin/reports)
  getIt.registerLazySingleton<ModerationDataSource>(() => const ModerationRemoteDataSource());
  // Fallback mock: () => ModerationMockDataSource()
  getIt.registerLazySingleton<ModerationRepository>(() => ModerationRepositoryImpl(getIt<ModerationDataSource>()));

  // Admin - User Registry  (API: GET /api/admin/users, PUT .../status)
  getIt.registerLazySingleton<UserRegistryDataSource>(() => const UserRegistryRemoteDataSource());
  // Fallback mock: () => UserRegistryMockDataSource()
  getIt.registerLazySingleton<UserRegistryRepository>(() => UserRegistryRepositoryImpl(getIt<UserRegistryDataSource>()));

  // Admin - Analytics  (API: GET /api/admin/dashboard)
  getIt.registerLazySingleton<AnalyticsDataSource>(() => const AnalyticsRemoteDataSource());
  // Fallback mock: () => const AnalyticsMockDataSource()
  getIt.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepositoryImpl(getIt<AnalyticsDataSource>()));

  // Admin - System Alerts  (backend CHƯA có endpoint -> vẫn dùng mock)
  getIt.registerLazySingleton<AlertsMockDataSource>(() => AlertsMockDataSource());
  getIt.registerLazySingleton<AlertsRepository>(() => AlertsRepositoryImpl(getIt<AlertsMockDataSource>()));

  // AI Coach Feature
  getIt.registerLazySingleton<AiCoachRemoteDataSource>(() => AiCoachRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<AiCoachRepository>(() => AiCoachRepositoryImpl(
        remoteDataSource: getIt<AiCoachRemoteDataSource>(),
      ));
  getIt.registerFactory<AiCoachCubit>(() => AiCoachCubit(
        repository: getIt<AiCoachRepository>(),
        storage: getIt<FlutterSecureStorage>(),
      ));

  // Meal & Profile Cubits
  getIt.registerFactory<MealCubit>(() => MealCubit(
        repository: getIt<MealRepository>(),
      ));
  getIt.registerFactory<ProfileCubit>(() => ProfileCubit(
        repository: getIt<ProfileRepository>(),
      ));

  getIt.registerFactory<WeightCubit>(() => WeightCubit(
        repository: getIt<WeightRepository>(),
      ));

  getIt.registerFactory<WaterCubit>(() => WaterCubit(
        repository: getIt<WaterRepository>(),
      ));

  // Dashboard Feature
  getIt.registerLazySingleton<DashboardRemoteDataSource>(() => DashboardRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(
        remoteDataSource: getIt<DashboardRemoteDataSource>(),
      ));
  getIt.registerFactory<DashboardCubit>(() => DashboardCubit(
        repository: getIt<DashboardRepository>(),
      ));

  // Food Feature
  getIt.registerLazySingleton<FoodRemoteDataSource>(() => FoodRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<FoodRepository>(() => FoodRepositoryImpl(
        remoteDataSource: getIt<FoodRemoteDataSource>(),
      ));
  getIt.registerFactory<FoodCubit>(() => FoodCubit(
        repository: getIt<FoodRepository>(),
      ));
}
