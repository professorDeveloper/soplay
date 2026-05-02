import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/features/detail/domain/entities/detail_entity.dart';
import 'package:soplay/features/detail/domain/usecases/get_detail_usecase.dart';

part 'detail_event.dart';
part 'detail_state.dart';

class DetailBloc extends Bloc<DetailEvent, DetailState> {
  final GetDetailUseCase useCase;

  DetailBloc({required this.useCase}) : super(const DetailInitial()) {
    on<DetailLoad>(_onLoad);
  }

  Future<void> _onLoad(DetailLoad event, Emitter<DetailState> emit) async {
    emit(const DetailLoading());
    final result = await useCase(event.contentUrl);
    switch (result) {
      case Success(:final value):
        emit(DetailLoaded(value));
      case Failure(:final error):
        emit(DetailError(error.toString().replaceFirst('Exception: ', '')));
    }
  }
}
