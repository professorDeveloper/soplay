import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:soplay/core/network/auth_interceptor.dart';
import 'package:soplay/core/network/dio_client.dart';
import 'package:soplay/core/network/logging_interceptor.dart';
import 'package:soplay/core/network/provider_interceptor.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/comments/data/datasources/comments_data_source.dart';
import 'package:soplay/features/comments/data/repositories/comments_repository_impl.dart';
import 'package:soplay/features/comments/domain/repositories/comments_repository.dart';
import 'package:soplay/features/comments/presentation/blocs/comments_bloc/comments_bloc.dart';
import 'package:soplay/features/detail/data/datasources/detail_data_source.dart';
import 'package:soplay/features/detail/data/repositories/detail_repository_impl.dart';
import 'package:soplay/features/detail/domain/repositories/detail_repository.dart';
import 'package:soplay/features/detail/domain/usecases/get_detail_usecase.dart';
import 'package:soplay/features/detail/domain/usecases/get_episodes_usecase.dart';
import 'package:soplay/features/detail/domain/usecases/resolve_media_usecase.dart';
import 'package:soplay/features/detail/presentation/blocs/detail_bloc/detail_bloc.dart';
import 'package:soplay/features/detail/presentation/blocs/episodes_bloc/episodes_bloc.dart';
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

  final dio = DioClient.instance;
  dio.interceptors.add(
    ProviderInterceptor(hiveService: getIt<HiveService>()),
  );
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(
    AuthInterceptor(hiveService: getIt<HiveService>(), dio: dio),
  );
  getIt.registerSingleton<Dio>(dio);



  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<HomeDataSource>(HomeDataSource(dio: getIt<Dio>()));
  getIt.registerSingleton<DetailDataSource>(DetailDataSource(dio: getIt<Dio>()));
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
  getIt.registerSingleton<DetailRepository>(
    DetailRepositoryImpl(getIt<DetailDataSource>()),
  );
  getIt.registerSingleton<ProviderDataSource>(
    ProviderDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<CommentsDataSource>(
    CommentsDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<CommentsRepository>(
    CommentsRepositoryImpl(getIt<CommentsDataSource>()),
  );
  getIt.registerSingleton<ProviderRepository>(
    ProviderRepositoryImpl(getIt<ProviderDataSource>()),
  );

  getIt.registerSingleton<GetDetailUseCase>(
    GetDetailUseCase(getIt<DetailRepository>()),
  );
  getIt.registerSingleton<GetEpisodesUseCase>(
    GetEpisodesUseCase(getIt<DetailRepository>()),
  );
  getIt.registerSingleton<ResolveMediaUseCase>(
    ResolveMediaUseCase(getIt<DetailRepository>()),
  );
  getIt.registerSingleton<ViewAllUseCase>(
    ViewAllUseCase(getIt<HomeRepository>()),
  );
  getIt.registerSingleton<LoginUseCase>(LoginUseCase(getIt<AuthRepository>()));
  getIt.registerSingleton<RegisterUseCase>(
    RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<VerifyOtpUseCase>(
    VerifyOtpUseCase(getIt<AuthRepository>()),
  );
  getIt.registerSingleton<ResendOtpUseCase>(
    ResendOtpUseCase(getIt<AuthRepository>()),
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
      verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
      resendOtpUseCase: getIt<ResendOtpUseCase>(),
      authRepository: getIt<AuthRepository>(),
      hiveService: getIt<HiveService>(),
    ),
  );
  getIt.registerFactory(() => DetailBloc(useCase: getIt<GetDetailUseCase>()));
  getIt.registerFactory(
    () => EpisodesBloc(useCase: getIt<GetEpisodesUseCase>()),
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
  getIt.registerFactory(
    () => CommentsBloc(
      repository: getIt<CommentsRepository>(),
      hiveService: getIt<HiveService>(),
    ),
  );

  getIt.registerLazySingleton<NavController>(() => NavController());
}
