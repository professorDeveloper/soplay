part of 'banners_bloc.dart';

class BannersState extends Equatable {
  final List<BannerItem> items;
  final bool loading;
  final String? error;
  final String placement;

  const BannersState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.placement = '',
  });

  BannersState copyWith({
    List<BannerItem>? items,
    bool? loading,
    String? error,
    String? placement,
  }) {
    return BannersState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
      placement: placement ?? this.placement,
    );
  }

  @override
  List<Object?> get props => [items, loading, error, placement];
}
