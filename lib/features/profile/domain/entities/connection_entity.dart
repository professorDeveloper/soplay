enum ConnectionService { anilist, mal, simkl }

class ConnectionEntity {
  final ConnectionService service;
  final String name;
  final String? logoUrl;
  final String? connectedUsername;
  final bool isConnected;

  const ConnectionEntity({
    required this.service,
    required this.name,
    this.logoUrl,
    this.connectedUsername,
    required this.isConnected,
  });
}
