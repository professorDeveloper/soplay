import 'package:equatable/equatable.dart';

class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeLoad extends HomeEvent {
  @override
  List<Object?> get props => [];
}

class HomeCollectionLoad extends HomeEvent {
  final String slug;
  final String title;
  final bool isGenre;

  HomeCollectionLoad({
    required this.slug,
    required this.title,
    required this.isGenre,
  });

  @override
  List<Object?> get props => [slug, title, isGenre];
}
