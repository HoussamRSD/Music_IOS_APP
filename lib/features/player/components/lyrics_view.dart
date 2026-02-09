import 'dart:async';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../../core/data/models/lyrics.dart';

class LyricsView extends StatefulWidget {
  final Lyrics lyrics;
  final Duration position;
  final Function(Duration) onSeek;

  const LyricsView({
    super.key,
    required this.lyrics,
    required this.position,
    required this.onSeek,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int _currentIndex = 0;
  bool _isUserScrolling = false;
  Timer? _scrollResetTimer;

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.lyrics.syncedLyrics != null) {
      _updateCurrentIndex();
    }
  }

  void _updateCurrentIndex() {
    final newIndex = widget.lyrics.syncedLyrics!.lastIndexWhere(
      (line) => line.timeMs <= widget.position.inMilliseconds,
    );

    if (newIndex != _currentIndex && newIndex >= 0) {
      setState(() {
        _currentIndex = newIndex;
      });

      if (!_isUserScrolling) {
        _scrollToCenter(newIndex);
      }
    }
  }

  void _scrollToCenter(int index) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the item
      );
    }
  }

  void _onUserScroll() {
    _isUserScrolling = true;
    _scrollResetTimer?.cancel();
    _scrollResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
        _scrollToCenter(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _scrollResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.syncedLyrics == null ||
        widget.lyrics.syncedLyrics!.isEmpty) {
      // Display plain lyrics on a single scrollable page
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: SelectableText(
          widget.lyrics.plainLyrics ?? 'No lyrics available',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.8,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _onUserScroll(),
      child: ScrollablePositionedList.builder(
        itemCount: widget.lyrics.syncedLyrics!.length,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.symmetric(
          vertical: 200,
        ), // Large padding for center focus
        itemBuilder: (context, index) {
          final line = widget.lyrics.syncedLyrics![index];
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
