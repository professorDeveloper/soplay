part of 'banners_bloc.dart';

abstract class BannersEvent extends Equatable {
  const BannersEvent();
  @override
  List<Object?> get props => const [];
}

class BannersLoad extends BannersEvent {
  final String placement;
  const BannersLoad(this.placement);
  @override
  List<Object?> get props => [placement];
}

class BannersView extends BannersEvent {
  final String id;
  const BannersView(this.id);
  @override
  List<Object?> get props => [id];
}

class BannersClick extends BannersEvent {
  final String id;
  const BannersClick(this.id);
  @override
  List<Object?> get props => [id];
}
