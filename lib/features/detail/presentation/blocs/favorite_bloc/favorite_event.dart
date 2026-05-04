import 'package:equatable/equatable.dart';

sealed class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

class FavoriteLoad extends FavoriteEvent {
  const FavoriteLoad(this.contentUrl);

  final String contentUrl;

  @override
  List<Object?> get props => [contentUrl];
}

class FavoriteToggle extends FavoriteEvent {
  const FavoriteToggle({
    required this.contentUrl,
    required this.provider,
    required this.title,
    required this.thumbnail,
  });

  final String contentUrl;
  final String provider;
  final String title;
  final String thumbnail;

  @override
  List<Object?> get props => [contentUrl, provider, title, thumbnail];
}
