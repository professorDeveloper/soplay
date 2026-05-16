class ReportTargetType {
  ReportTargetType._();
  static const String comment = 'comment';
  static const String short = 'short';
  static const String user = 'user';
  static const String content = 'content';
}

class ReportReason {
  ReportReason._();
  static const String spam = 'spam';
  static const String abuse = 'abuse';
  static const String sexual = 'sexual';
  static const String violence = 'violence';
  static const String copyright = 'copyright';
  static const String other = 'other';

  static const List<String> all = [
    spam,
    abuse,
    sexual,
    violence,
    copyright,
    other,
  ];

  static String label(String reason) {
    switch (reason) {
      case spam:
        return 'Spam';
      case abuse:
        return 'Haqorat';
      case sexual:
        return 'Sexual content';
      case violence:
        return 'Zo\'ravonlik';
      case copyright:
        return 'Mualliflik huquqi';
      default:
        return 'Boshqa';
    }
  }
}

class ReportPayload {
  final String targetType;
  final String? targetId;
  final String? provider;
  final String? contentUrl;
  final String reason;
  final String? message;

  const ReportPayload({
    required this.targetType,
    this.targetId,
    this.provider,
    this.contentUrl,
    required this.reason,
    this.message,
  });
}
