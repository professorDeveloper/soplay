class ProviderEntity {
  final String id;
  final String name;
  final String image;
  final String url;
  final String description;
  final List<String> domains;

  const ProviderEntity({
    required this.id,
    required this.name,
    required this.image,
    required this.url,
    required this.description,
    required this.domains,
  });
}
