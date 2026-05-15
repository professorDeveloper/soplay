class ExtractorRef {
  final String name;
  final int version;
  final String scope;
  final String url;

  const ExtractorRef({
    required this.name,
    required this.version,
    required this.scope,
    required this.url,
  });
}

class ProviderEntity {
  final String id;
  final String name;
  final String image;
  final String url;
  final String description;
  final List<String> domains;
  final String mode;
  final ExtractorRef? extractor;

  const ProviderEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.url,
    required this.description,
    required this.domains,
    this.mode = 'server',
    this.extractor,
  });

  bool get scopesResolveMedia =>
      extractor != null &&
      (extractor!.scope == 'all' || extractor!.scope == 'resolveMedia');

  bool get scopesAll => extractor != null && extractor!.scope == 'all';
}
