part of 'detail_bloc.dart';

abstract class DetailState {
  const DetailState();
}

class DetailInitial extends DetailState {
  const DetailInitial();
}

class DetailLoading extends DetailState {
  const DetailLoading();
}

class DetailLoaded extends DetailState {
  final DetailEntity detail;
  const DetailLoaded(this.detail);
}

class DetailError extends DetailState {
  final String message;
  const DetailError(this.message);
}
