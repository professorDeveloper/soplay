import 'package:equatable/equatable.dart' show Equatable;

class ViewAllEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ViewAllLoadMore extends ViewAllEvent {}

class ViewAllLoad extends ViewAllEvent {
  final String? slug;
  final String key;

  ViewAllLoad({this.slug, required this.key});

  @override
  List<Object?> get props => [slug, key];
}
