import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/usecase/home_usecase.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeUseCase useCase;

  HomeBloc({required this.useCase}) : super(HomeInitial()) {
    on<HomeLoad>(_onHomeLoad);
    on<HomeCollectionLoad>(_onHomeCollectionLoad);
  }

  Future<void> _onHomeLoad(HomeLoad event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    final result = await useCase();
    switch (result) {
      case Success(:final value):
        emit(HomeLoaded(value));
      case Failure(:final error):
        emit(HomeError(error.toString()));
    }
  }

  Future<void> _onHomeCollectionLoad(
    HomeCollectionLoad event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoaded) return;

    emit(
      current.copyWith(
        collectionTitle: event.title,
        collectionItems: const [],
        collectionLoading: true,
      ),
    );

    final result = event.isGenre
        ? await useCase.loadGenre(event.slug)
        : await useCase.loadCategory(event.slug);

    switch (result) {
      case Success(:final value):
        emit(
          current.copyWith(
            collectionTitle: event.title,
            collectionItems: value,
            collectionLoading: false,
          ),
        );
      case Failure():
        emit(
          current.copyWith(
            collectionTitle: event.title,
            collectionItems: const [],
            collectionLoading: false,
          ),
        );
    }
  }
}
