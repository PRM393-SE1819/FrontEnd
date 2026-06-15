import 'package:get_it/get_it.dart';
import '../core/network/api_service.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
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

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Core Network Service
  getIt.registerLazySingleton<ApiService>(() => const ApiService());

  // Auth Feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => const AuthRemoteDataSource());
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()));

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
}
