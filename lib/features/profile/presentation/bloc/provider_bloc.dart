import 'package:flutter_bloc/flutter_bloc.dart';
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
    final previous = state;
    if (previous is! ProviderLoaded) {
      emit(ProviderLoading());
    }

    final result = await useCase();
    switch (result) {
      case Success(:final value):
        final providers = value
            .where((p) => p.id.trim().isNotEmpty)
            .toList(growable: false);

        if (providers.isEmpty) {
          if (previous is! ProviderLoaded) {
            emit(ProviderError());
          }
          return;
        }

        final resolvedId = _resolveCurrentProviderId(providers);
        if (resolvedId != hiveService.getCurrentProvider()) {
          await hiveService.saveCurrentProvider(resolvedId);
        }

        emit(
          ProviderLoaded(providers: providers, currentProviderId: resolvedId),
        );
      case Failure():
        if (previous is! ProviderLoaded) {
          emit(ProviderError());
        }
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

  String _resolveCurrentProviderId(List<ProviderEntity> providers) {
    final savedProviderId = hiveService.getCurrentProvider();
    final hasSavedProvider = providers.any((p) => p.id == savedProviderId);
    if (hasSavedProvider) return savedProviderId;
    return providers.first.id;
  }
}
