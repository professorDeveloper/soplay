import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/constants/app_constants.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/profile/domain/entities/provider_entity.dart';
import 'package:soplay/features/profile/domain/usecases/get_providers_usecase.dart';
import 'provider_event.dart';
import 'provider_state.dart';

class ProviderBloc extends Bloc<ProviderEvent, ProviderState> {
  final GetProvidersUseCase useCase;
  final HiveService hiveService;

  ProviderBloc({required this.useCase, required this.hiveService})
    : super(ProviderInitial()) {
    on<ProviderLoad>(_onLoad);
    on<ProviderSelect>(_onSelect);
  }

  Future<void> _onLoad(ProviderLoad event, Emitter<ProviderState> emit) async {
    emit(ProviderLoading());
    final result = await useCase();
    switch (result) {
      case Success(:final value):
        final providers = _normalizeProviders(value);
        final currentProviderId = _resolveCurrentProviderId(providers);
        emit(
          ProviderLoaded(
            providers: providers,
            currentProviderId: currentProviderId,
          ),
        );
      case Failure():
        emit(
          ProviderLoaded(
            providers: const [_defaultProvider],
            currentProviderId: AppConstants.defaultProviderId,
          ),
        );
    }
  }

  Future<void> _onSelect(
    ProviderSelect event,
    Emitter<ProviderState> emit,
  ) async {
    await hiveService.saveCurrentProvider(event.providerId);
    if (state is ProviderLoaded) {
      final loaded = state as ProviderLoaded;
      emit(
        ProviderLoaded(
          providers: loaded.providers,
          currentProviderId: event.providerId,
        ),
      );
    }
  }

  List<ProviderEntity> _normalizeProviders(List<ProviderEntity> providers) {
    final byId = <String, ProviderEntity>{
      AppConstants.defaultProviderId: _defaultProvider,
    };

    for (final provider in providers) {
      if (provider.id.trim().isEmpty) continue;
      byId[provider.id] = provider;
    }

    return byId.values.toList();
  }

  String _resolveCurrentProviderId(List<ProviderEntity> providers) {
    final savedProviderId = hiveService.getCurrentProvider();
    final hasSavedProvider = providers.any((p) => p.id == savedProviderId);
    if (hasSavedProvider) return savedProviderId;
    return AppConstants.defaultProviderId;
  }

  static const _defaultProvider = ProviderEntity(
    id: AppConstants.defaultProviderId,
    name: 'Asilmedia',
    image: '',
    url: 'https://asilmedia.org',
    description: '',
    domains: ['asilmedia.org'],
  );
}
