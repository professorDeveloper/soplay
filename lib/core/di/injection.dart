import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:soplay/core/js/dart_fetch.dart';
import 'package:soplay/core/js/extractor_cache.dart';
import 'package:soplay/core/js/extractor_remote.dart';
import 'package:soplay/core/js/js_runtime_service.dart';
import 'package:soplay/core/js/provider_registry.dart';
import 'package:soplay/core/network/auth_interceptor.dart';
import 'package:soplay/core/network/dio_client.dart';
import 'package:soplay/core/network/logging_interceptor.dart';
import 'package:soplay/core/network/no_internet_interceptor.dart';
import 'package:soplay/core/network/provider_interceptor.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/download/data/download_service.dart';
import 'package:soplay/features/history/data/history_service.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_event.dart';
import 'package:soplay/features/app_updater/data/datasources/app_updater_data_source.dart';
import 'package:soplay/features/app_updater/data/repositories/app_updater_repository_impl.dart';
import 'package:soplay/features/app_updater/domain/repositories/app_updater_repository.dart';
import 'package:soplay/features/app_updater/presentation/services/update_checker.dart';
import 'package:soplay/features/banners/data/datasources/banners_data_source.dart';
import 'package:soplay/features/banners/data/repositories/banners_repository_impl.dart';
import 'package:soplay/features/banners/domain/repositories/banners_repository.dart';
import 'package:soplay/features/banners/presentation/bloc/banners_bloc.dart';
import 'package:soplay/features/comments/data/datasources/comments_data_source.dart';
import 'package:soplay/features/comments/data/repositories/comments_repository_impl.dart';
import 'package:soplay/features/comments/domain/repositories/comments_repository.dart';
import 'package:soplay/features/comments/presentation/blocs/comments_bloc/comments_bloc.dart';
import 'package:soplay/features/notifications/data/datasources/notifications_data_source.dart';
import 'package:soplay/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:soplay/features/notifications/data/services/notification_service.dart';
import 'package:soplay/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:soplay/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soplay/features/reports/data/datasources/reports_data_source.dart';
import 'package:soplay/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:soplay/features/reports/domain/repositories/reports_repository.dart';
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
import 'package:soplay/features/shorts/data/datasources/shorts_remote_data_source.dart';
import 'package:soplay/features/shorts/data/repositories/shorts_repository_impl.dart';
import 'package:soplay/features/shorts/domain/repositories/shorts_repository.dart';
import 'package:soplay/features/shorts/domain/usecases/get_short_usecase.dart';
import 'package:soplay/features/shorts/domain/usecases/get_shorts_usecase.dart';
import 'package:soplay/features/shorts/domain/usecases/increase_short_view_usecase.dart';
import 'package:soplay/features/shorts/domain/usecases/toggle_short_like_usecase.dart';
import 'package:soplay/features/shorts/presentation/bloc/shorts_bloc.dart';
import 'package:soplay/features/detail/presentation/blocs/favorite_bloc/favorite_bloc.dart';
import 'package:soplay/features/my_list/data/datasources/my_list_remote_data_source.dart';
import 'package:soplay/features/my_list/data/repositories/my_list_repository_impl.dart';
import 'package:soplay/features/my_list/domain/repositories/my_list_repository.dart';
import 'package:soplay/features/my_list/domain/usecases/add_favorite_usecase.dart';
import 'package:soplay/features/my_list/domain/usecases/get_favorites_usecase.dart';
import 'package:soplay/features/my_list/domain/usecases/remove_favorite_usecase.dart';
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
  getIt.registerSingleton<HistoryService>(HistoryService());
  getIt.registerSingleton<DownloadService>(DownloadService());

  final dio = DioClient.instance;
  dio.interceptors.add(ProviderInterceptor(hiveService: getIt<HiveService>()));
  dio.interceptors.add(LoggingInterceptor());
  dio.interceptors.add(NoInternetInterceptor());
  dio.interceptors.add(
    AuthInterceptor(
      hiveService: getIt<HiveService>(),
      dio: dio,
      onSessionExpired: () {
        if (getIt.isRegistered<AuthBloc>()) {
          getIt<AuthBloc>().add(AuthSessionExpired());
        }
      },
    ),
  );
  getIt.registerSingleton<Dio>(dio);

  getIt.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<HomeDataSource>(HomeDataSource(dio: getIt<Dio>()));
  getIt.registerSingleton<DetailDataSource>(
    DetailDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<SearchDataSource>(
    SearchDataSource(dio: getIt<Dio>()),
  );

  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<HiveService>()),
  );
  getIt.registerSingleton<ProviderDataSource>(
    ProviderDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<ProviderRegistry>(
    ProviderRegistry(source: getIt<ProviderDataSource>()),
  );
  getIt.registerSingleton<ExtractorRemote>(
    ExtractorRemote(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<ExtractorCache>(ExtractorCache());
  getIt.registerSingleton<DartFetch>(DartFetch.create());
  getIt.registerSingleton<JsRuntimeService>(
    JsRuntimeService(
      remote: getIt<ExtractorRemote>(),
      cache: getIt<ExtractorCache>(),
      dartFetch: getIt<DartFetch>(),
      providers: getIt<ProviderRegistry>(),
    ),
  );
  getIt.registerSingleton<HomeRepository>(
    HomeRepositoryImp(
      getIt<HomeDataSource>(),
      jsRuntime: getIt<JsRuntimeService>(),
      hive: getIt<HiveService>(),
    ),
  );
  getIt.registerSingleton<SearchRepository>(
    SearchRepositoryImp(
      dataSource: getIt<SearchDataSource>(),
      jsRuntime: getIt<JsRuntimeService>(),
      hive: getIt<HiveService>(),
    ),
  );
  getIt.registerSingleton<DetailRepository>(
    DetailRepositoryImpl(
      getIt<DetailDataSource>(),
      jsRuntime: getIt<JsRuntimeService>(),
      hive: getIt<HiveService>(),
    ),
  );
  getIt.registerSingleton<CommentsDataSource>(
    CommentsDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<ShortsRemoteDataSource>(
    ShortsRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<CommentsRepository>(
    CommentsRepositoryImpl(getIt<CommentsDataSource>()),
  );
  getIt.registerSingleton<ProviderRepository>(
    ProviderRepositoryImpl(getIt<ProviderDataSource>()),
  );
  getIt.registerSingleton<ShortsRepository>(
    ShortsRepositoryImpl(getIt<ShortsRemoteDataSource>()),
  );
  getIt.registerSingleton<NotificationsDataSource>(
    NotificationsDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<NotificationsRepository>(
    NotificationsRepositoryImpl(getIt<NotificationsDataSource>()),
  );
  getIt.registerSingleton<NotificationService>(
    NotificationService(repository: getIt<NotificationsRepository>()),
  );
  getIt.registerSingleton<BannersDataSource>(
    BannersDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<BannersRepository>(
    BannersRepositoryImpl(getIt<BannersDataSource>()),
  );
  getIt.registerSingleton<ReportsDataSource>(
    ReportsDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<ReportsRepository>(
    ReportsRepositoryImpl(getIt<ReportsDataSource>()),
  );
  getIt.registerSingleton<AppUpdaterDataSource>(
    AppUpdaterDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<AppUpdaterRepository>(
    AppUpdaterRepositoryImpl(getIt<AppUpdaterDataSource>()),
  );
  getIt.registerSingleton<UpdateChecker>(
    UpdateChecker(repository: getIt<AppUpdaterRepository>()),
  );

  getIt.registerSingleton<MyListRemoteDataSource>(
    MyListRemoteDataSource(dio: getIt<Dio>()),
  );
  getIt.registerSingleton<MyListRepository>(
    MyListRepositoryImpl(getIt<MyListRemoteDataSource>()),
  );
  getIt.registerSingleton<GetFavoritesUseCase>(
    GetFavoritesUseCase(getIt<MyListRepository>()),
  );
  getIt.registerSingleton<AddFavoriteUseCase>(
    AddFavoriteUseCase(getIt<MyListRepository>()),
  );
  getIt.registerSingleton<RemoveFavoriteUseCase>(
    RemoveFavoriteUseCase(getIt<MyListRepository>()),
  );
  getIt.registerSingleton<GetShortsUseCase>(
    GetShortsUseCase(getIt<ShortsRepository>()),
  );
  getIt.registerSingleton<GetShortUseCase>(
    GetShortUseCase(getIt<ShortsRepository>()),
  );
  getIt.registerSingleton<IncreaseShortViewUseCase>(
    IncreaseShortViewUseCase(getIt<ShortsRepository>()),
  );
  getIt.registerSingleton<ToggleShortLikeUseCase>(
    ToggleShortLikeUseCase(getIt<ShortsRepository>()),
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

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
      resendOtpUseCase: getIt<ResendOtpUseCase>(),
      authRepository: getIt<AuthRepository>(),
      hiveService: getIt<HiveService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
  getIt.registerFactory(
    () => NotificationsBloc(repository: getIt<NotificationsRepository>()),
  );
  getIt.registerFactory(
    () => BannersBloc(repository: getIt<BannersRepository>()),
  );
  getIt.registerFactory(() => DetailBloc(useCase: getIt<GetDetailUseCase>()));
  getIt.registerFactory(
    () => FavoriteBloc(
      addFavorite: getIt<AddFavoriteUseCase>(),
      removeFavorite: getIt<RemoveFavoriteUseCase>(),
      hiveService: getIt<HiveService>(),
    ),
  );
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
    () => ShortsBloc(
      getShorts: getIt<GetShortsUseCase>(),
      increaseView: getIt<IncreaseShortViewUseCase>(),
      toggleLike: getIt<ToggleShortLikeUseCase>(),
      hiveService: getIt<HiveService>(),
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
