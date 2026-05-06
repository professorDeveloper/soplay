part of 'detail_bloc.dart';

abstract class DetailEvent {
  const DetailEvent();
}

class DetailLoad extends DetailEvent {
  final String contentUrl;
  final String? provider;
  const DetailLoad(this.contentUrl, {this.provider});
}
