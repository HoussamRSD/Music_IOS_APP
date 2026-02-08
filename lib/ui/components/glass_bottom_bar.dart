import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/navigation/providers/navigation_provider.dart';
import '../../features/navigation/models/navigation_tab.dart';
import '../../features/library/providers/library_providers.dart';

class GlassBottomBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const GlassBottomBar({super.key, required this.navigationShell});

  void _onTap(BuildContext context, WidgetRef ref, NavigationTab tab) {
    switch (tab) {
      case NavigationTab.home:
        navigationShell.goBranch(0);
        break;
      case NavigationTab.songs:
        ref.read(libraryTabProvider.notifier).setTab(0);
        navigationShell.goBranch(1);
        break;
      case NavigationTab.playlists:
        ref.read(libraryTabProvider.notifier).setTab(1);
        navigationShell.goBranch(1);
        break;
      case NavigationTab.artists:
        ref.read(libraryTabProvider.notifier).setTab(2);
        navigationShell.goBranch(1);
        break;
      case NavigationTab.favorites:
        ref.read(libraryTabProvider.notifier).setTab(3);
        navigationShell.goBranch(1);
        break;
    }
  }

  bool _isSelected(int currentBranch, int libraryTab, NavigationTab tab) {
    if (tab == NavigationTab.home) {
      return currentBranch == 0;
    }
    if (currentBranch != 1) return false;

    switch (tab) {
      case NavigationTab.songs:
        return libraryTab == 0;
      case NavigationTab.playlists:
        return libraryTab == 1;
      case NavigationTab.artists:
        return libraryTab == 2;
      case NavigationTab.favorites:
        return libraryTab == 3;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(navigationProvider);
    final visibleTabs = settings.visibleTabs;
    final libraryTab = ref.watch(libraryTabProvider);
    final currentBranch = navigationShell.currentIndex;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60 + bottomPadding,
          decoration: BoxDecoration(
            color: const Color(0xCC1C1C1E),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: visibleTabs.map((tab) {
                final isSelected = _isSelected(currentBranch, libraryTab, tab);
                return _buildNavItem(context, ref, tab, isSelected);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    NavigationTab tab,
    bool isSelected,
  ) {
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(context, ref, tab),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontFamily: 'Inter',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
