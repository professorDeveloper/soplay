import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:soplay/core/network/dio_client.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/home/data/datasources/home_data_source.dart';
import 'package:soplay/features/home/data/repositories/home_repository_imp.dart';
import 'package:soplay/features/home/domain/repositories/home_repository.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_bloc.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/home/domain/usecase/home_usecase.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingleton<HiveService>(HiveService());

  getIt.registerSingleton<Dio>(DioClient.instance);

  // Token interceptor: injects Bearer token into every request
  getIt<Dio>().interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getIt<HiveService>().getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  // Data sources
  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<HomeDataSource>(HomeDataSource(dio: getIt<Dio>()));

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<HiveService>()),
  );
  getIt.registerSingleton<HomeRepository>(
    HomeRepositoryImp(getIt<HomeDataSource>()),
  );

  // Use cases
  getIt.registerSingleton<LoginUseCase>(LoginUseCase(getIt<AuthRepository>()));
  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<HomeUseCase>(HomeUseCase(getIt<HomeRepository>()));

  // Blocs
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => HomeBloc(useCase: getIt<HomeUseCase>()),
  );
}
