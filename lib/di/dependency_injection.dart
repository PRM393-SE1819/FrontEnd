import 'package:get_it/get_it.dart';
import '../core/network/api_service.dart';
import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Core Network Service
  getIt.registerLazySingleton<ApiService>(() => const ApiService());

  // Auth Feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(() => const AuthRemoteDataSource());
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<AuthRemoteDataSource>()));
}
