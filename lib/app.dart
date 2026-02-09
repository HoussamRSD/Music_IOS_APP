import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/search/search_screen.dart';
import 'features/navigation/providers/navigation_provider.dart';
import 'features/library/providers/library_providers.dart';
import 'features/settings/providers/font_provider.dart';
import 'ui/scaffold/main_scaffold.dart';
import 'features/artists/screens/artist_details_screen.dart';

class GlassApp extends ConsumerStatefulWidget {
  const GlassApp({super.key});

  @override
  ConsumerState<GlassApp> createState() => _GlassAppState();
}

class _GlassAppState extends ConsumerState<GlassApp> {
  late GoRouter _router;
  bool _initialNavigationDone = false;

  @override
  void initState() {
    super.initState();
    // Create router with initial location - will update after settings load
    _router = _createRouter('/home');
  }

  GoRouter _createRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (context, state) => const LibraryScreen(),
                  routes: [
                    GoRoute(
                      path: 'artist/:name',
                      builder: (context, state) {
                        final artistName = Uri.decodeComponent(
                          state.pathParameters['name']!,
                        );
                        return ArtistDetailsScreen(artistName: artistName);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (context, state) => const SearchScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Get the base TextStyle for the selected font
  TextStyle _getFontTextStyle(String fontFamily) {
    switch (fontFamily) {
      case 'Pacifico':
        return GoogleFonts.pacifico(color: Colors.white);
      case 'Inter':
        return GoogleFonts.inter(color: Colors.white);
      case 'Roboto':
        return GoogleFonts.roboto(color: Colors.white);
      case 'Outfit':
        return GoogleFonts.outfit(color: Colors.white);
      case 'Montserrat':
        return GoogleFonts.montserrat(color: Colors.white);
      default:
        return GoogleFonts.pacifico(color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(navigationProvider);
    final selectedFont = ref.watch(fontProvider);

    // Navigate to default tab after settings are loaded (only once)
    if (!_initialNavigationDone && settings.isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialNavigationDone && settings.isLoaded) {
          _initialNavigationDone = true;
          final defaultTab = settings.defaultTab;

          // Set library tab if needed
          if (defaultTab.libraryTabIndex != null) {
            ref
                .read(libraryTabProvider.notifier)
                .setTab(defaultTab.libraryTabIndex!);
          }

          // Navigate to the correct route
          _router.go(defaultTab.routePath);
        }
      });
    }

    return CupertinoApp.router(
      title: 'DOPLIN',
      theme: AppTheme.getDarkTheme(selectedFont.fontFamily),
      routerConfig: _router,
      // Apply font globally to all child widgets
      builder: (context, child) {
        return DefaultTextStyle.merge(
          style: _getFontTextStyle(selectedFont.fontFamily),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
