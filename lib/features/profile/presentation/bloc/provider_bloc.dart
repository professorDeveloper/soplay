import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
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
        emit(ProviderLoaded(
          providers: value,
          currentProviderId: hiveService.getCurrentProvider(),
        ));
      case Failure():
        emit(ProviderError());
    }
  }

  Future<void> _onSelect(
    ProviderSelect event,
    Emitter<ProviderState> emit,
  ) async {
    await hiveService.saveCurrentProvider(event.providerId);
    if (state is ProviderLoaded) {
      final loaded = state as ProviderLoaded;
      emit(ProviderLoaded(
        providers: loaded.providers,
        currentProviderId: event.providerId,
      ));
    }
  }
}
