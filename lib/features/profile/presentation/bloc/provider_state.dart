import 'package:equatable/equatable.dart';
import '../../domain/entities/provider_entity.dart';

abstract class ProviderState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProviderInitial extends ProviderState {}

class ProviderLoading extends ProviderState {}

class ProviderLoaded extends ProviderState {
  final List<ProviderEntity> providers;
  final String currentProviderId;

  ProviderLoaded({
    required this.providers,
    required this.currentProviderId,
  });

  ProviderEntity? get currentProvider =>
      providers.where((p) => p.id == currentProviderId).firstOrNull;

  @override
  List<Object?> get props => [providers, currentProviderId];
}

class ProviderError extends ProviderState {}
