import 'package:flutter/material.dart';
import 'package:soplay/features/comments/presentation/widgets/comments_panel.dart';

class DetailCommentsTab extends StatelessWidget {
  const DetailCommentsTab({
    super.key,
    required this.provider,
    required this.contentUrl,
  });

  final String provider;
  final String contentUrl;

  @override
  Widget build(BuildContext context) {
    return CommentsPanel(provider: provider, contentUrl: contentUrl);
  }
}
