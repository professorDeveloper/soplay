import 'package:equatable/equatable.dart';

import '../../../domain/entities/movie.dart';

class ViewAllState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ViewAllLoading extends ViewAllState {}

class ViewAllInitial extends ViewAllState {}

class ViewAllError extends ViewAllState {
  final String mesage;

  ViewAllError({required this.mesage});
}

class ViewAllLoaded extends ViewAllState {
  final List<MovieEntity> items;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;

  ViewAllLoaded({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = true,
  });
}
