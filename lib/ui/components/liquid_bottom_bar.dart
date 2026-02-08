import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class LiquidBottomBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const LiquidBottomBar({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Standard iOS Tab Bar height is ~50-80 depending on safe area
    // We want it floating slightly or standard?
    // "Floating mini player above tab bar" implies standard tab bar at bottom or slightly floating.
    // "Glassmorphism" suggests blur.

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkTheme.barBackgroundColor,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 49,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    CupertinoIcons.play_circle_fill,
                    'Listen Now',
                    0,
                  ),
                  _buildNavItem(CupertinoIcons.music_albums_fill, 'Library', 1),
                  _buildNavItem(CupertinoIcons.search, 'Search', 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondary;

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
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
