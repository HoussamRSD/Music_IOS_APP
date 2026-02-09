import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../library/services/file_import_service.dart';
import '../settings/settings_screen.dart';
import 'tabs/playlists_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/songs_tab.dart';
import 'providers/library_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Scan on initial load
    _autoScanOnStartup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground, scan for new files
    if (state == AppLifecycleState.resumed) {
      _autoScan();
    }
  }

  Future<void> _autoScanOnStartup() async {
    // Small delay to let the UI settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _autoScan();
  }

  Future<void> _autoScan() async {
    try {
      final importService = ref.read(fileImportServiceProvider);
      final songs = await importService.scanMusicDirectory();
      if (!mounted) return;
      if (songs.isNotEmpty) {
        ref.invalidate(songsProvider);
        // Optionally show a subtle notification
        debugPrint('Auto-imported ${songs.length} new song(s)');
      }
    } catch (e) {
      debugPrint('Auto-scan error: $e');
    }
  }

  void _showImportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Music'),
        message: const Text('Choose how to add music to your library'),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder, size: 20),
                SizedBox(width: 8),
                Text('Import from Files'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _importFiles();
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_clockwise, size: 20),
                SizedBox(width: 8),
                Text('Scan Music Folder'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _scanMusicFolder();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _importFiles() async {
    try {
      final importService = ref.read(fileImportServiceProvider);
      final songs = await importService.importFiles();

      if (!mounted) return;

      if (songs.isEmpty) {
        return;
      }

      // Refresh the songs list
      ref.invalidate(songsProvider);

      // Show success message
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Import Complete'),
          content: Text('Successfully imported ${songs.length} song(s)'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Import Failed'),
          content: Text('An error occurred while importing files: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _scanMusicFolder() async {
    try {
      final scannerService = ref.read(libraryScannerServiceProvider);

      // Show loading indicator
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: CupertinoAlertDialog(
            title: const Text('Scanning Library'),
            content: const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Please wait...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final result = await scannerService.scanLibrary(forceRescan: true);

        if (!mounted) {
          return;
        }

        // Dismiss loading dialog
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Refresh the songs list and invalidate related providers
        ref.invalidate(songsProvider);
        // Force refresh of metadata/artwork cache
        ref.invalidate(fileImportServiceProvider);

        if (!mounted) {
          return;
        }

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Rescan Complete'),
            content: Text(
              'Added: ${result.added}\nUpdated: ${result.updated}\nRemoved: ${result.removed}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        // Dismiss loading dialog if still open
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (!mounted) {
          return;
        }

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Scan Failed'),
            content: Text('An error occurred during scan: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (!mounted) {
        return;
      }

      // Try to dismiss any open dialog
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}

      if (!mounted) {
        return;
      }

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('An unexpected error occurred: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGridView = ref.watch(isGridViewProvider);
    final selectedSegment = ref.watch(libraryTabProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            isGridView
                ? CupertinoIcons.list_bullet
                : CupertinoIcons.square_grid_2x2,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          onPressed: () {
            ref.read(isGridViewProvider.notifier).toggle();
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showImportOptions,
              child: const Icon(
                CupertinoIcons.arrow_down_doc,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _scanMusicFolder,
              child: const Icon(
                CupertinoIcons.arrow_clockwise,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.gear_alt,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: _buildTabContent(selectedSegment),
    );
  }

  Widget _buildTabContent(int selectedSegment) {
    switch (selectedSegment) {
      case 0:
        return const SongsTab();
      case 1:
        return const PlaylistsTab();
      case 2:
        return const ArtistsTab();
      case 3:
        return const FavoritesTab();
      default:
        return const SongsTab();
    }
  }
}
