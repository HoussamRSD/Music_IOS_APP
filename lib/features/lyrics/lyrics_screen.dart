import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/lyrics.dart';
import '../../core/data/models/song.dart';
import '../../core/theme/app_theme.dart';
import '../player/services/audio_player_service.dart';
import '../settings/providers/font_provider.dart';
import 'lyrics_editor_screen.dart';
import 'lyrics_search_screen.dart';
import 'services/lyrics_service.dart';

/// Doppi-style full-page lyrics screen
class LyricsScreen extends ConsumerStatefulWidget {
  final Song song;

  const LyricsScreen({super.key, required this.song});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  Lyrics? _lyrics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lyricsService = ref.read(lyricsServiceProvider);
      final lyrics = await lyricsService.getLyrics(widget.song);
      if (mounted) {
        setState(() {
          _lyrics = lyrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openEditor() async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) =>
            LyricsEditorScreen(song: widget.song, initialLyrics: _lyrics),
      ),
    );
    if (result == true) {
      _loadLyrics();
    }
  }

  void _searchLyrics() async {
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => LyricsSearchScreen(song: widget.song),
      ),
    );
    if (result == true) {
      _loadLyrics();
    }
  }

  void _pasteLyrics() {
    _openEditor();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerServiceProvider);
    final selectedFont = ref.watch(fontProvider).fontFamily;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: Stack(
        children: [
          // Gradient background
          _buildGradientBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(selectedFont),

                // Lyrics content
                Expanded(child: _buildLyricsContent(playerState, selectedFont)),

                // Bottom bar with actions
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.backgroundColor,
            AppTheme.backgroundColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildHeader(String selectedFont) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Song thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: widget.song.artworkPath != null
                  ? Image.file(
                      File(widget.song.artworkPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultThumbnail(),
                    )
                  : _defaultThumbnail(),
            ),
          ),
          const SizedBox(width: 12),

          // Song info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.song.artists.isNotEmpty
                      ? '${widget.song.artists.join(", ")} — ${widget.song.album ?? ""}'
                      : widget.song.album ?? 'Unknown Artist',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Playback controls
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              ref.read(audioPlayerServiceProvider.notifier).togglePlayPause();
            },
            child: Icon(
              ref.watch(audioPlayerServiceProvider).isPlaying
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // Skip to next
            },
            child: const Icon(
              CupertinoIcons.forward_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultThumbnail() {
    return Container(
      color: AppTheme.surfaceColor,
      child: Icon(
        CupertinoIcons.music_note_2,
        color: AppTheme.primaryColor,
        size: 24,
      ),
    );
  }

  Widget _buildLyricsContent(PlayerState playerState, String selectedFont) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error loading lyrics',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
      );
    }

    if (_lyrics == null) {
      return _buildNoLyricsView();
    }

    // Has lyrics - show them
    return _buildLyricsView(playerState);
  }

  Widget _buildNoLyricsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.text_quote,
              color: Colors.white.withValues(alpha: 0.3),
              size: 64,
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Lyrics to This Song',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search the web for lyrics. Then select, copy, and paste them here.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  onPressed: _searchLyrics,
                  child: const Text(
                    'Search for Lyrics',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  onPressed: _pasteLyrics,
                  child: const Text(
                    'Paste Lyrics',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsView(PlayerState playerState) {
    final hasSynced =
        _lyrics!.syncedLyrics != null && _lyrics!.syncedLyrics!.isNotEmpty;

    if (hasSynced) {
      return _SyncedLyricsView(
        lyrics: _lyrics!,
        position: playerState.position,
        onSeek: (position) {
          ref.read(audioPlayerServiceProvider.notifier).seek(position);
        },
      );
    } else {
      // Plain lyrics
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Text(
          _lyrics!.plainLyrics ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Queue button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // Show queue
            },
            child: Icon(
              CupertinoIcons.list_bullet,
              color: Colors.white.withValues(alpha: 0.8),
              size: 24,
            ),
          ),

          // Close button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white.withValues(alpha: 0.8),
              size: 28,
            ),
          ),

          // Edit lyrics button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _openEditor,
            child: const Text(
              'Edit',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Synced lyrics view with auto-scroll
class _SyncedLyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Duration position;
  final Function(Duration) onSeek;

  const _SyncedLyricsView({
    required this.lyrics,
    required this.position,
    required this.onSeek,
  });

  @override
  State<_SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<_SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  bool _isUserScrolling = false;

  @override
  void didUpdateWidget(_SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final lines = widget.lyrics.syncedLyrics!;
    final newIndex = lines.lastIndexWhere(
      (line) => line.timeMs <= widget.position.inMilliseconds,
    );

    if (newIndex != _currentIndex && newIndex >= 0) {
      setState(() {
        _currentIndex = newIndex;
      });

      if (!_isUserScrolling) {
        _scrollToLine(newIndex);
      }
    }
  }

  void _scrollToLine(int index) {
    // Approximate item height
    const itemHeight = 60.0;
    final targetOffset = index * itemHeight - 200; // Center offset

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lyrics.syncedLyrics!;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _isUserScrolling = true;
        } else if (notification is ScrollEndNotification) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _isUserScrolling = false;
            }
          });
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 200),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          final isCurrent = index == _currentIndex;

          return GestureDetector(
            onTap: () {
              widget.onSeek(Duration(milliseconds: line.timeMs));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              child: Text(
                line.text,
                style: TextStyle(
                  color: isCurrent
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  fontSize: isCurrent ? 24 : 18,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
