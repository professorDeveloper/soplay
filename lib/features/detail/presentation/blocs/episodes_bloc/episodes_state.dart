part of 'episodes_bloc.dart';

abstract class EpisodesState {
  const EpisodesState();
}

class EpisodesInitial extends EpisodesState {
  const EpisodesInitial();
}

class EpisodesLoading extends EpisodesState {
  const EpisodesLoading();
}

class EpisodesLoaded extends EpisodesState {
  final PlaybackEntity playback;
  const EpisodesLoaded(this.playback);
}

class EpisodesError extends EpisodesState {
  final String message;
  const EpisodesError(this.message);
}
