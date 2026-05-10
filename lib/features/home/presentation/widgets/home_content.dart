import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/history/data/history_service.dart';
import 'package:soplay/features/history/domain/entities/history_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_event.dart';
import 'package:soplay/features/home/presentation/widgets/home_banner.dart';
import 'package:soplay/features/home/presentation/widgets/home_history_section.dart';
import 'package:soplay/features/home/presentation/widgets/home_movie_section.dart';
import 'package:soplay/features/home/presentation/widgets/home_top_bar.dart';
import 'package:soplay/features/search/domain/entities/genre_entity.dart';

import '../bloc/home/home_state.dart';
import 'genre_card.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, required this.state});

  final HomeLoaded state;

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late final ScrollController _scrollController;
  final HistoryService _historyService = getIt<HistoryService>();
  List<HistoryItem> _historyItems = const [];

  final _blurProgress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _historyService.revision.addListener(_loadHistory);
    _loadHistory();
    _maybeShowTelegramPromo();
  }

  void _maybeShowTelegramPromo() {
    final hive = getIt<HiveService>();
    if (hive.hasTelegramPromoSeen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _TelegramPromoSheet(
          onJoin: () {
            Navigator.of(ctx).pop();
            launchUrl(
              Uri.parse('https://t.me/sozoApp'),
              mode: LaunchMode.externalApplication,
            );
          },
          onDismiss: (dontShowAgain) {
            if (dontShowAgain) hive.markTelegramPromoSeen();
            Navigator.of(ctx).pop();
          },
          onDontShowAgain: hive.markTelegramPromoSeen,
        ),
      );
    });
  }

  void _loadHistory() {
    final items = _historyService.getAll();
    if (!mounted) return;
    setState(() => _historyItems = items);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    // Blur starts after banner area (~250px) and completes by ~400px
    final next = ((_scrollController.offset - 250) / 150).clamp(0.0, 1.0);
    if ((next - _blurProgress.value).abs() < 0.02) return;
    _blurProgress.value = next;
  }

  @override
  void dispose() {
    _historyService.revision.removeListener(_loadHistory);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _blurProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          edgeOffset: topPad + 10,
          displacement: topPad + 10,
          strokeWidth: 2.6,
          onRefresh: () async {
            context.read<HomeBloc>().add(HomeLoad(silent: true));
            await Future.wait([
              context.read<HomeBloc>().stream.firstWhere(
                (state) => state is HomeLoaded || state is HomeError,
              ),
              Future<void>.delayed(const Duration(milliseconds: 850)),
            ]);
            _loadHistory();
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeBanner(
                  banners: widget.state.homeData.banner,
                  topPadding: topPad,
                ),
              ),
              if (_historyItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: HistorySection(items: _historyItems),
                  ),
                ),
              if (widget.state.genres.isNotEmpty)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: _GenreSection(genres: widget.state.genres),
                  ),
                ),
              if (widget.state.collectionLoading)
                const SliverToBoxAdapter(child: CollectionLoadingRow()),
              for (final section in widget.state.homeData.sections)
                if (section.items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: MovieSection(
                        title: section.label,
                        movies: section.items,
                        type: section.viewAll.type,
                        slug: section.viewAll.slug,
                      ),
                    ),
                  ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 16,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _blurProgress,
            builder: (_, progress, _) => HomeTopBar(blurProgress: progress),
          ),
        ),
      ],
    );
  }
}

class _GenreSection extends StatelessWidget {
  const _GenreSection({required this.genres});

  final List<GenreEntity> genres;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 18, 16, 12),
            child: Text(
              "home.genres".tr(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: genres.length,
              itemBuilder: (_, i) => GenreCard(genre: genres[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelegramPromoSheet extends StatefulWidget {
  const _TelegramPromoSheet({
    required this.onJoin,
    required this.onDismiss,
    required this.onDontShowAgain,
  });

  final VoidCallback onJoin;
  final void Function(bool dontShowAgain) onDismiss;
  final VoidCallback onDontShowAgain;

  @override
  State<_TelegramPromoSheet> createState() => _TelegramPromoSheetState();
}

class _TelegramPromoSheetState extends State<_TelegramPromoSheet> {
  bool _dontShow = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2AABEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.telegram, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 14),
          const Text(
            'Join Sozo on Telegram',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Get updates, new features, and content notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2AABEE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.telegram, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Join Channel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              setState(() => _dontShow = !_dontShow);
              if (_dontShow) widget.onDontShowAgain();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _dontShow
                        ? const Color(0xFF2AABEE)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _dontShow
                          ? const Color(0xFF2AABEE)
                          : AppColors.textHint,
                      width: 1.5,
                    ),
                  ),
                  child: _dontShow
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Don't show again",
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
