import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:soplay/core/network/dio_client.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/home/data/datasources/home_data_source.dart';
import 'package:soplay/features/home/data/repositories/home_repository_imp.dart';
import 'package:soplay/features/home/domain/repositories/home_repository.dart';
import 'package:soplay/features/home/domain/usecase/view_all_usecase.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_bloc.dart';
import 'package:soplay/features/profile/data/datasources/provider_data_source.dart';
import 'package:soplay/features/profile/data/repositories/provider_repository_impl.dart';
import 'package:soplay/features/profile/domain/repositories/provider_repository.dart';
import 'package:soplay/features/profile/domain/usecases/get_providers_usecase.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_bloc.dart';
import 'package:soplay/features/search/data/datasources/search_data_source.dart';
import 'package:soplay/features/search/data/repositories/search_repository_imp.dart';
import 'package:soplay/features/search/domain/repositories/search_repository.dart';
import 'package:soplay/features/search/domain/usecases/genre_usecase.dart';
import 'package:soplay/features/search/domain/usecases/search_usecase.dart';
import 'package:soplay/features/search/presentation/blocs/search_bloc.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/home/domain/usecase/home_usecase.dart';
import '../navigation/nav_controller.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingleton<HiveService>(HiveService());

  getIt.registerSingleton<Dio>(DioClient.instance);

  getIt<Dio>().interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = getIt<HiveService>().getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final path = error.requestOptions.path;
        final isAuthEntryPoint =
            path.contains('/auth/login') || path.contains('/auth/register');
        final isRefreshRequest =
            path.contains('/auth/refresh') ||
            error.requestOptions.extra['skipAuthRefresh'] == true;

        if (statusCode != 401 || isAuthEntryPoint || isRefreshRequest) {
          handler.next(error);
          return;
        }

        final hive = getIt<HiveService>();
        final refreshToken = hive.getRefreshToken();
        final user = hive.getUser();
        if (refreshToken == null || refreshToken.isEmpty || user == null) {
          await hive.clearAuth();
          handler.next(error);
          return;
        }

        try {
          final dio = getIt<Dio>();
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: dio.options.baseUrl,
              connectTimeout: dio.options.connectTimeout,
              receiveTimeout: dio.options.receiveTimeout,
              headers: {'Content-Type': 'application/json'},
            ),
          );
          final response = await refreshDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(extra: {'skipAuthRefresh': true}),
          );
          final data = response.data ?? {};
          final accessToken = data['accessToken'] as String? ?? '';
          final nextRefreshToken =
              data['refreshToken'] as String? ?? refreshToken;

          if (accessToken.isEmpty) {
            throw DioException(
              requestOptions: error.requestOptions,
              message: 'Token refresh failed',
            );
          }

          await hive.saveTokens(
            accessToken: accessToken,
            refreshToken: nextRefreshToken,
          );

          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $accessToken';
          final retryResponse = await dio.fetch<dynamic>(retryOptions);
          handler.resolve(retryResponse);
        } catch (_) {
          await hive.clearAuth();
          handler.next(error);
        }
      },
    ),
  );

  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<HomeDataSource>(HomeDataSource(dio: getIt<Dio>()));
  getIt.registerSingleton<SearchDataSource>(
    SearchDataSource(dio: getIt<Dio>()),
  );

  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<HiveService>()),
  );
  getIt.registerSingleton<HomeRepository>(
    HomeRepositoryImp(getIt<HomeDataSource>()),
  );
  getIt.registerSingleton<SearchRepository>(
    SearchRepositoryImp(dataSource: getIt<SearchDataSource>()),
  );
  getIt.registerSingleton<ProviderDataSource>(
    ProviderDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<ProviderRepository>(
    ProviderRepositoryImpl(getIt<ProviderDataSource>()),
  );

  getIt.registerSingleton<ViewAllUseCase>(
    ViewAllUseCase(getIt<HomeRepository>()),
  );
  getIt.registerSingleton<LoginUseCase>(LoginUseCase(getIt<AuthRepository>()));
  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<HomeUseCase>(HomeUseCase(getIt<HomeRepository>()));
  getIt.registerSingleton<SearchUseCase>(
    SearchUseCase(repository: getIt<SearchRepository>()),
  );
  getIt.registerSingleton<GenreUseCase>(
    GenreUseCase(repository: getIt<SearchRepository>()),
  );
  getIt.registerSingleton<GetProvidersUseCase>(
    GetProvidersUseCase(getIt<ProviderRepository>()),
  );

  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      authRepository: getIt<AuthRepository>(),
      hiveService: getIt<HiveService>(),
    ),
  );
  getIt.registerFactory(() => ViewAllBloc(useCase: getIt<ViewAllUseCase>()));
  getIt.registerFactory(() => HomeBloc(useCase: getIt<HomeUseCase>()));
  getIt.registerFactory(
    () => SearchBloc(
      searchUseCase: getIt<SearchUseCase>(),
      genreUseCase: getIt<GenreUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => ProviderBloc(
      useCase: getIt<GetProvidersUseCase>(),
      hiveService: getIt<HiveService>(),
    ),
  );

  getIt.registerLazySingleton<NavController>(() => NavController());
}
