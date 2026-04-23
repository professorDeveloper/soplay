import 'dart:async';
import 'dart:ffi';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/usecase/home_usecase.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent,HomeState> {
  final HomeUseCase useCase;
  HomeBloc({required this.useCase}): super(HomeInitial()){
    on<HomeLoad>(_onHomeLoad);
  }

  Future<void> _onHomeLoad(HomeLoad event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    var result = await useCase();
    if (result.isSuccess && result.value != null) {
      emit(HomeLoaded(result.value!));
    } else {
      emit(HomeError(result.error.toString()));
    }
  }
}