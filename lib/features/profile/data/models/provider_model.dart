import '../../domain/entities/provider_entity.dart';

class ProviderModel extends ProviderEntity {
  const ProviderModel({
    required super.id,
    required super.name,
    required super.image,
    required super.url,
    required super.description,
    required super.domains,
    super.mode,
    super.extractor,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    final id =
        json['id'] as String? ??
        json['_id'] as String? ??
        json['slug'] as String? ??
        '';
    final name = json['name'] as String? ?? id;

    return ProviderModel(
      id: id,
      name: name,
      image: json['image'] as String? ?? '',
      url: json['url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      domains: (json['domains'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      mode: json['mode'] as String? ?? 'server',
      extractor: _parseExtractor(json['extractor']),
    );
  }

  static ExtractorRef? _parseExtractor(dynamic raw) {
    if (raw is! Map) return null;
    final name = raw['name'] as String?;
    final url = raw['url'] as String?;
    if (name == null || name.isEmpty || url == null || url.isEmpty) return null;
    final version = (raw['version'] as num?)?.toInt() ?? 0;
    final scope = raw['scope'] as String? ?? 'resolveMedia';
    return ExtractorRef(name: name, version: version, scope: scope, url: url);
  }
}
