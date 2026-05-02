part of 'detail_bloc.dart';

abstract class DetailEvent {
  const DetailEvent();
}

class DetailLoad extends DetailEvent {
  final String contentUrl;
  const DetailLoad(this.contentUrl);
}
