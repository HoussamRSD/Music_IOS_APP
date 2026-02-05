import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../components/liquid_bottom_bar.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBody: true, // Important for glass effect
      body: navigationShell,
      bottomNavigationBar: LiquidBottomBar(navigationShell: navigationShell),
    );
  }
}
