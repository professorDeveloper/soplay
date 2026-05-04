part of 'episodes_bloc.dart';

abstract class EpisodesEvent {
  const EpisodesEvent();
}

class EpisodesLoad extends EpisodesEvent {
  final String contentUrl;
  const EpisodesLoad(this.contentUrl);
}

class EpisodesReset extends EpisodesEvent {
  const EpisodesReset();
}
