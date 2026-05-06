part of 'episodes_bloc.dart';

abstract class EpisodesEvent {
  const EpisodesEvent();
}

class EpisodesLoad extends EpisodesEvent {
  final String contentUrl;
  final String? provider;
  const EpisodesLoad(this.contentUrl, {this.provider});
}

class EpisodesReset extends EpisodesEvent {
  const EpisodesReset();
}
