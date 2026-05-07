import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/detail/domain/entities/player_args.dart';
import 'package:soplay/features/download/data/download_service.dart';
import 'package:soplay/features/download/domain/entities/download_item.dart';
import 'package:soplay/features/home/presentation/widgets/home_shared_widgets.dart';

class DownloadsSection extends StatefulWidget {
  const DownloadsSection({super.key});

  @override
  State<DownloadsSection> createState() => _DownloadsSectionState();
}

class _DownloadsSectionState extends State<DownloadsSection> {
  final DownloadService _service = getIt<DownloadService>();
  List<DownloadItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _service.revision.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _service.revision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    final all = _service.getAll();
    setState(
      () => _items = all
          .where((i) => i.status == DownloadStatus.completed)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 16, 14),
            child: InkWell(
              onTap: () => context.push('/downloads'),
              borderRadius: BorderRadius.circular(8),
              child: const Row(
                children: [
                  Icon(
                    Icons.download_done_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Downloaded',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _items.length > 20 ? 20 : _items.length,
              itemBuilder: (_, i) => _DownloadCard(item: _items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.item});

  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/player',
          extra: PlayerArgs(
            title: item.isSerial && item.episodeNumber != null
                ? '${item.title} · EP ${item.episodeNumber}'
                : item.title,
            provider: item.provider,
            headers: const {},
            contentUrl: item.contentUrl,
            thumbnail: item.displayThumbnail,
            movieUrl: item.localPath.endsWith('.m3u8')
                ? Uri.file(item.localPath).toString()
                : item.localPath,
            type: item.localPath.endsWith('.m3u8') ? 'hls' : null,
            showDownloadAction: false,
          ),
        );
      },
      child: SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      HomeNetworkImage(
                        url: item.displayThumbnail,
                        borderRadius: BorderRadius.zero,
                        placeholderIcon: Icons.movie_outlined,
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.download_done_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      if (item.isSerial && item.episodeNumber != null)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'EP ${item.episodeNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
