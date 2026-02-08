import 'package:flutter/cupertino.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/search/search_screen.dart';
import 'ui/scaffold/main_scaffold.dart';

class GlassApp extends ConsumerWidget {
  const GlassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/home',
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

    return CupertinoApp.router(
      title: 'Glass Music',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
