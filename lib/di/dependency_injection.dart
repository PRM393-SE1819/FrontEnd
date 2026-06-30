import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import '../features/admin/data/datasources/moderation_remote_data_source.dart';
import '../features/admin/data/repositories/moderation_repository_impl.dart';
import '../features/admin/domain/repositories/moderation_repository.dart';
import '../features/admin/data/datasources/user_registry_remote_data_source.dart';
import '../features/admin/data/repositories/user_registry_repository_impl.dart';
import '../features/admin/domain/repositories/user_registry_repository.dart';
import '../features/admin/data/datasources/analytics_remote_data_source.dart';
import '../features/admin/data/repositories/analytics_repository_impl.dart';
import '../features/admin/domain/repositories/analytics_repository.dart';
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

// UseCases
import '../features/auth/domain/usecases/login_use_case.dart';
import '../features/auth/domain/usecases/register_use_case.dart';
import '../features/auth/domain/usecases/verify_email_use_case.dart';
import '../features/auth/domain/usecases/resend_verification_email_use_case.dart';
import '../features/auth/domain/usecases/request_password_reset_use_case.dart';
import '../features/auth/domain/usecases/reset_password_use_case.dart';
import '../features/meal/domain/usecases/add_meal_use_case.dart';
import '../features/profile/domain/usecases/update_health_profile_use_case.dart';
import '../features/profile/domain/usecases/add_health_condition_use_case.dart';
import '../features/profile/domain/usecases/add_allergy_use_case.dart';
import '../features/food/domain/usecases/search_foods_use_case.dart';
import '../features/food/domain/usecases/create_custom_food_use_case.dart';
import '../features/ai_coach/domain/usecases/estimate_calories_use_case.dart';
import '../features/ai_coach/domain/usecases/delete_all_chat_history_use_case.dart';
import '../features/ai_coach/domain/usecases/ai_coach_search_foods_use_case.dart';
import '../features/admin/domain/usecases/get_users_use_case.dart';
import '../features/admin/domain/usecases/set_user_status_use_case.dart';
import '../features/admin/domain/usecases/change_user_role_use_case.dart';
import '../features/admin/domain/usecases/delete_user_use_case.dart';
import '../features/admin/domain/usecases/get_queue_use_case.dart';
import '../features/admin/domain/usecases/get_resolved_use_case.dart';
import '../features/admin/domain/usecases/update_moderation_status_use_case.dart';
import '../features/admin/domain/usecases/get_analytics_overview_use_case.dart';


final getIt = GetIt.instance;

void setupDependencyInjection() {
  // Core Services
  getIt.registerLazySingleton<http.Client>(() => http.Client());
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

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
  // Mỗi feature có remote data source tự gọi HTTP (inject http.Client +
  // FlutterSecureStorage), giống luồng user — dễ test/mock, không phụ thuộc
  // class tập trung.
  // =========================================================================

  // Admin - Moderation  (API: GET/PUT /api/admin/reports)
  getIt.registerLazySingleton<ModerationRemoteDataSource>(() => ModerationRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<ModerationRepository>(() => ModerationRepositoryImpl(getIt<ModerationRemoteDataSource>()));

  // Admin - User Registry  (API: GET /api/admin/users, PUT .../status)
  getIt.registerLazySingleton<UserRegistryRemoteDataSource>(() => UserRegistryRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<UserRegistryRepository>(() => UserRegistryRepositoryImpl(getIt<UserRegistryRemoteDataSource>()));

  // Admin - Analytics  (API: GET /api/admin/dashboard)
  getIt.registerLazySingleton<AnalyticsRemoteDataSource>(() => AnalyticsRemoteDataSource(
        client: getIt<http.Client>(),
        storage: getIt<FlutterSecureStorage>(),
      ));
  getIt.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepositoryImpl(getIt<AnalyticsRemoteDataSource>()));

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
        waterRepository: getIt<WaterRepository>(),
      ));
  getIt.registerLazySingleton<DashboardCubit>(() => DashboardCubit(
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

  // Register UseCases
  // Auth
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<VerifyEmailUseCase>(() => VerifyEmailUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<ResendVerificationEmailUseCase>(() => ResendVerificationEmailUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<RequestPasswordResetUseCase>(() => RequestPasswordResetUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton<ResetPasswordUseCase>(() => ResetPasswordUseCase(getIt<AuthRepository>()));

  // Meal
  getIt.registerLazySingleton<AddMealUseCase>(() => AddMealUseCase(getIt<MealRepository>()));

  // Profile
  getIt.registerLazySingleton<UpdateHealthProfileUseCase>(() => UpdateHealthProfileUseCase(getIt<ProfileRepository>()));
  getIt.registerLazySingleton<AddHealthConditionUseCase>(() => AddHealthConditionUseCase(getIt<ProfileRepository>()));
  getIt.registerLazySingleton<AddAllergyUseCase>(() => AddAllergyUseCase(getIt<ProfileRepository>()));

  // Food
  getIt.registerLazySingleton<SearchFoodsUseCase>(() => SearchFoodsUseCase(getIt<FoodRepository>()));
  getIt.registerLazySingleton<CreateCustomFoodUseCase>(() => CreateCustomFoodUseCase(getIt<FoodRepository>()));

  // AI Coach
  getIt.registerLazySingleton<EstimateCaloriesUseCase>(() => EstimateCaloriesUseCase(getIt<AiCoachRepository>()));
  getIt.registerLazySingleton<DeleteAllChatHistoryUseCase>(() => DeleteAllChatHistoryUseCase(getIt<AiCoachRepository>()));
  getIt.registerLazySingleton<AiCoachSearchFoodsUseCase>(() => AiCoachSearchFoodsUseCase(getIt<AiCoachRepository>()));

  // Admin
  getIt.registerLazySingleton<GetUsersUseCase>(() => GetUsersUseCase(getIt<UserRegistryRepository>()));
  getIt.registerLazySingleton<SetUserStatusUseCase>(() => SetUserStatusUseCase(getIt<UserRegistryRepository>()));
  getIt.registerLazySingleton<ChangeUserRoleUseCase>(() => ChangeUserRoleUseCase(getIt<UserRegistryRepository>()));
  getIt.registerLazySingleton<DeleteUserUseCase>(() => DeleteUserUseCase(getIt<UserRegistryRepository>()));
  getIt.registerLazySingleton<GetQueueUseCase>(() => GetQueueUseCase(getIt<ModerationRepository>()));
  getIt.registerLazySingleton<GetResolvedUseCase>(() => GetResolvedUseCase(getIt<ModerationRepository>()));
  getIt.registerLazySingleton<UpdateModerationStatusUseCase>(() => UpdateModerationStatusUseCase(getIt<ModerationRepository>()));
  getIt.registerLazySingleton<GetAnalyticsOverviewUseCase>(() => GetAnalyticsOverviewUseCase(getIt<AnalyticsRepository>()));
}
