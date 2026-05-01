abstract class ProviderEvent {
  const ProviderEvent();
}

class ProviderLoad extends ProviderEvent {
  const ProviderLoad();
}

class ProviderSelect extends ProviderEvent {
  final String providerId;
  const ProviderSelect(this.providerId);
}
