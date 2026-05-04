class CommentAuthor {
  final String id;
  final String username;
  final String? displayName;
  final String? photoURL;

  const CommentAuthor({
    required this.id,
    required this.username,
    this.displayName,
    this.photoURL,
  });

  String get nameOrUsername =>
      (displayName?.trim().isNotEmpty ?? false) ? displayName! : username;
}
