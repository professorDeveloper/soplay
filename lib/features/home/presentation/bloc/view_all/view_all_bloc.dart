import 'dart:async';
import 'package:bloc/bloc.dart' show Bloc, Emitter;
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/home/domain/entities/view_all_paging_entity.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_event.dart';
import 'package:soplay/features/home/presentation/bloc/view_all/view_all_state.dart';

import '../../../domain/usecase/view_all_usecase.dart';

class ViewAllBloc extends Bloc<ViewAllEvent, ViewAllState> {
  final ViewAllUseCase useCase;
  String _key = '';
  String _slug = '';

  ViewAllBloc({required this.useCase}) : super(ViewAllInitial()) {
    on<ViewAllLoad>(_onLoad);
    on<ViewAllLoadMore>(_onLoadMore);
  }

  Future<void> _onLoad(ViewAllLoad event, Emitter<ViewAllState> emit) async {
    _key = event.key;
    _slug = event.slug ?? '';
    emit(ViewAllLoading());

    final Result<ViewAllPagingEntity> result = await useCase(_key, _slug, 1);
    if (result.isSuccess) {
      final data = result.getOrNull()!;
      emit(ViewAllLoaded(
        items: data.items,
        currentPage: data.page,
        totalPages: data.totalPages,
      ));
    } else {
      emit(ViewAllError(mesage: result.getErrorOrNull()!.toString()));
    }
  }

  Future<void> _onLoadMore(ViewAllLoadMore event, Emitter<ViewAllState> emit) async {
    final current = state;
    if (current is! ViewAllLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(ViewAllLoaded(
      items: current.items,
      currentPage: current.currentPage,
      totalPages: current.totalPages,
      isLoadingMore: true,
    ));

    final result = await useCase(_key, _slug, current.currentPage + 1);
    if (result.isSuccess) {
      final data = result.getOrNull()!;
      emit(ViewAllLoaded(
        items: [...current.items, ...data.items],
        currentPage: data.page,
        totalPages: data.totalPages,
      ));
    } else {
      emit(ViewAllError(mesage: result.getErrorOrNull()!.toString()));
    }
  }
}
