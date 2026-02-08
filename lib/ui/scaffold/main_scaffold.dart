import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/player/mini_player.dart';
import '../components/liquid_bottom_bar.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        extendBody: true, // Important for glass effect
        body: Stack(
          children: [
            navigationShell,
            Positioned(
              left: 0,
              right: 0,
              bottom: 49 + 10, // TabBar height + padding
              child: const MiniPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: LiquidBottomBar(navigationShell: navigationShell),
      ),
    );
  }
}
