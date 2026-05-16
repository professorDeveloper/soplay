import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/banners/domain/entities/banner_item.dart';
import 'package:soplay/features/banners/domain/repositories/banners_repository.dart';

part 'banners_event.dart';
part 'banners_state.dart';

class BannersBloc extends Bloc<BannersEvent, BannersState> {
  final BannersRepository repository;

  BannersBloc({required this.repository}) : super(const BannersState()) {
    on<BannersLoad>(_onLoad);
    on<BannersView>(_onView);
    on<BannersClick>(_onClick);
  }

  Future<void> _onLoad(BannersLoad event, Emitter<BannersState> emit) async {
    emit(state.copyWith(loading: true, error: null));
    final result = await repository.list(event.placement);
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(
          loading: false,
          items: value,
          placement: event.placement,
        ));
      case Failure(:final error):
        emit(state.copyWith(
          loading: false,
          error: error.toString().replaceFirst('Exception: ', ''),
        ));
    }
  }

  Future<void> _onView(BannersView event, Emitter<BannersState> emit) async {
    await repository.trackView(event.id);
  }

  Future<void> _onClick(BannersClick event, Emitter<BannersState> emit) async {
    await repository.trackClick(event.id);
  }
}
