import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/di/injection.dart';
import 'package:soplay/core/theme/app_colors.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_bloc.dart';
import 'package:soplay/features/home/presentation/bloc/home/home_event.dart';
import 'package:soplay/features/home/presentation/pages/home_page.dart';
import 'package:soplay/features/my_list/presentation/pages/my_list_page.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_bloc.dart';
import 'package:soplay/features/profile/presentation/bloc/provider_state.dart';
import 'package:soplay/features/search/presentation/blocs/search_bloc.dart';
import 'package:soplay/features/search/presentation/pages/search_page.dart';
import 'package:soplay/features/shorts/presentation/pages/shorts_page.dart';

import '../../../../core/navigation/nav_controller.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const int _shortsIndex = 2;

  int _index = 0;
  int _shortsRefreshTick = 0;
  late final NavController _navController;
  String? _lastProviderId;

  @override
  void initState() {
    super.initState();
    _navController = getIt<NavController>();
    _navController.index.addListener(_onNavChange);
  }

  void _onNavChange() => setState(() => _index = _navController.index.value);

  @override
  void dispose() {
    _navController.index.removeListener(_onNavChange);
    super.dispose();
  }

  void _onProviderStateChange(BuildContext context, ProviderState state) {
    if (state is! ProviderLoaded) return;
    final newId = state.currentProviderId;
    if (_lastProviderId == null) {
      _lastProviderId = newId;
      return;
    }
    if (_lastProviderId == newId) return;
    _lastProviderId = newId;
    context.read<HomeBloc>().add(HomeLoad(silent: true));
    context.read<SearchBloc>().add(const SearchLoad());
  }

  void _onTabTap(int index) {
    setState(() => _index = index);
    _navController.goTo(index);
  }

  void _refreshShorts() {
    if (_index != _shortsIndex) return;
    setState(() => _shortsRefreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const HomePage(),
      const SearchPage(),
      ShortsPage(
        active: _index == _shortsIndex,
        refreshTick: _shortsRefreshTick,
      ),
      const MyListPage(),
      const ProfilePage(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: BlocListener<ProviderBloc, ProviderState>(
        listener: _onProviderStateChange,
        child: PopScope(
          canPop: _index == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            setState(() => _index = 0);
            _navController.goTo(0);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            extendBody: true,
            body: IndexedStack(index: _index, children: tabs),
            bottomNavigationBar: _SoplayBottomNav(
              index: _index,
              onTap: _onTabTap,
              onShortsDoubleTap: _refreshShorts,
            ),
          ),
        ),
      ),
    );
  }
}

class _SoplayBottomNav extends StatelessWidget {
  const _SoplayBottomNav({
    required this.index,
    required this.onTap,
    required this.onShortsDoubleTap,
  });

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onShortsDoubleTap;

  static const _items = [
    _NavItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      labelKey: 'navigation.home',
    ),
    _NavItem(
      icon: CupertinoIcons.search,
      activeIcon: CupertinoIcons.search,
      labelKey: 'navigation.search',
    ),
    _NavItem(
      icon: CupertinoIcons.play_rectangle,
      activeIcon: CupertinoIcons.play_rectangle_fill,
      labelKey: 'navigation.shorts',
    ),
    _NavItem(
      icon: CupertinoIcons.bookmark,
      activeIcon: CupertinoIcons.bookmark_fill,
      labelKey: 'navigation.my_list',
    ),
    _NavItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      labelKey: 'navigation.profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 68 + bottomPad,
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E).withValues(alpha: 0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: 8,
              bottom: bottomPad == 0 ? 8 : bottomPad,
            ),
            child: Row(
              children: List.generate(
                _items.length,
                (i) => Expanded(
                  child: _BottomNavButton(
                    item: _items[i],
                    selected: index == i,
                    onTap: () => onTap(i),
                    onDoubleTap: i == _MainPageState._shortsIndex
                        ? onShortsDoubleTap
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });

  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
}

class _BottomNavButton extends StatefulWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  @override
  State<_BottomNavButton> createState() => _BottomNavButtonState();
}

class _BottomNavButtonState extends State<_BottomNavButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? Colors.white : const Color(0xFF7A7A7A);

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.labelKey.tr(),
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        onDoubleTap: widget.selected ? widget.onDoubleTap : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: _pressed ? 0.92 : 1,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: _pressed ? 0.68 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  scale: widget.selected ? 1.1 : 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      widget.selected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      key: ValueKey(
                        '${widget.item.labelKey}-${widget.selected}',
                      ),
                      size: 24,
                      color: color,
                      shadows: widget.selected
                          ? [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.28),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    height: 1,
                  ),
                  child: Text(
                    widget.item.labelKey.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
