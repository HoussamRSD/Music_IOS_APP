import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/lyrics.dart';
import '../../core/data/models/song.dart';
import '../../core/theme/app_theme.dart';
import '../player/services/audio_player_service.dart';
import 'services/lyrics_service.dart';

class LyricsEditorScreen extends ConsumerStatefulWidget {
  final Song song;
  final Lyrics? initialLyrics;

  const LyricsEditorScreen({super.key, required this.song, this.initialLyrics});

  @override
  ConsumerState<LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends ConsumerState<LyricsEditorScreen> {
  late TextEditingController _plainTextController;
  late int _selectedSegment;
  List<LyricLine> _syncedLines = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSegment = (widget.initialLyrics?.syncedLyrics?.isNotEmpty ?? false)
        ? 1
        : 0;

    _plainTextController = TextEditingController(
      text: widget.initialLyrics?.plainLyrics ?? '',
    );

    if (widget.initialLyrics?.syncedLyrics != null) {
      _syncedLines = List.from(widget.initialLyrics!.syncedLyrics!);
    }
  }

  @override
  void dispose() {
    _plainTextController.dispose();
    super.dispose();
  }

  String _formatTimestamp(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final millis = (duration.inMilliseconds.remainder(1000) / 10).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final writer = ref.read(lyricsWriterServiceProvider);
      final success;

      if (_selectedSegment == 0) {
        // Save Plain Text
        success = await writer.writePlainLyrics(
          widget.song.filePath,
          _plainTextController.text,
        );
      } else {
        // Save Synced (Convert to LRC format)
        final lrcContent = _generateLrcContent();
        success = await writer.writeSyncedLyrics(
          widget.song.filePath,
          lrcContent,
        );
      }

      if (success) {
        // Invalidate cache
        if (widget.song.id != null) {
          await ref
              .read(lyricsServiceProvider)
              .invalidateCache(widget.song.id!);
        }

        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate update
        }
      } else {
        _showError('Failed to save lyrics to file.');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _generateLrcContent() {
    final buffer = StringBuffer();
    // Sort lines by time
    _syncedLines.sort((a, b) => a.timeMs.compareTo(b.timeMs));

    for (final line in _syncedLines) {
      buffer.writeln('[${_formatTimestamp(line.timeMs)}]${line.text}');
    }
    return buffer.toString();
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Edit Lyrics',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: _isSaving
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _save,
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.2),
                thumbColor: AppTheme.surfaceColor,
                groupValue: _selectedSegment,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Plain Text',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Synced',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSegment = value);
                  }
                },
              ),
            ),
            Expanded(
              child: _selectedSegment == 0
                  ? _buildPlainEditor()
                  : _buildSyncedEditor(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CupertinoTextField(
        controller: _plainTextController,
        style: const TextStyle(color: Colors.white),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        placeholder: 'Enter lyrics here...',
        placeholderStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSyncedEditor() {
    return Column(
      children: [
        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_syncedLines.length} lines',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.add),
                onPressed: () {
                  setState(() {
                    _syncedLines.add(LyricLine(timeMs: 0, text: ''));
                  });
                },
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _syncedLines.isEmpty
              ? Center(
                  child: Text(
                    'No synced lyrics',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: _syncedLines.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final line = _syncedLines[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Timestamp Button
                        GestureDetector(
                          onTap: () => _updateTimestamp(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTimestamp(line.timeMs),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text Field
                        Expanded(
                          child: CupertinoTextField(
                            controller: TextEditingController(text: line.text)
                              ..selection = TextSelection.collapsed(
                                offset: line.text.length,
                              ),
                            style: const TextStyle(color: Colors.white),
                            placeholder: 'Lyrics line...',
                            placeholderStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onChanged: (value) {
                              _syncedLines[index] = _syncedLines[index]
                                  .copyWith(text: value);
                            },
                          ),
                        ),
                        // Delete Button
                        CupertinoButton(
                          padding: EdgeInsets.only(left: 8),
                          minSize: 0,
                          child: Icon(
                            CupertinoIcons.minus_circle,
                            color: Colors.red.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _syncedLines.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _updateTimestamp(int index) {
    // Get current player position
    final position = ref
        .read(audioPlayerServiceProvider)
        .position
        .inMilliseconds;

    setState(() {
      _syncedLines[index] = _syncedLines[index].copyWith(timeMs: position);
      // Sort lines to keep order? Maybe not automatically to avoid jumping UI
      // But usually timestamps should be ordered.
      // Let's keep manual order for now, user can drag? (Drag not implemented)
    });
  }
}
