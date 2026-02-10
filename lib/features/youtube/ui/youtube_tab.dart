import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../download/services/download_service.dart';
import '../../player/services/audio_player_service.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';

class YouTubeTab extends ConsumerStatefulWidget {
  const YouTubeTab({super.key});

  @override
  ConsumerState<YouTubeTab> createState() => _YouTubeTabState();
}

class _YouTubeTabState extends ConsumerState<YouTubeTab>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _canGoForward = false;

  static const String _homeUrl = 'https://m.youtube.com';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              final canGoBack = await _webViewController.canGoBack();
              final canGoForward = await _webViewController.canGoForward();
              setState(() {
                _isLoading = false;
                _canGoBack = canGoBack;
                _canGoForward = canGoForward;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_homeUrl));
  }

  Future<void> _downloadCurrentVideo() async {
    // Extract video ID from current URL
    final url = await _webViewController.currentUrl();
    if (url == null) {
      _showErrorDialog('Unable to get current video');
      return;
    }

    final videoId = _extractVideoId(url);
    if (videoId == null) {
      _showErrorDialog('No YouTube video detected. Please play a video first.');
      return;
    }

    _showDownloadModeDialog(videoId);
  }

  String? _extractVideoId(String url) {
    try {
      if (url.contains('youtube.com/watch')) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      } else if (url.contains('youtu.be/')) {
        return url.split('youtu.be/').last.split('?').first;
      }
    } catch (e) {
      debugPrint('Error extracting video ID: $e');
    }
    return null;
  }

  void _showDownloadModeDialog(String videoId) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Download Options'),
        message: const Text(
          'Choose how to download this video.\n\n'
          'Smart Mode: Identifies song, fetches metadata, lyrics & cover art\n'
          'Safe Mode: Download as-is without identification',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performDownload(videoId, safeMode: false);
            },
            child: const Text(
              '🧠 Smart Mode (Recommended)',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _performDownload(videoId, safeMode: true);
            },
            child: const Text(
              '🛡️ Safe Mode',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _performDownload(
    String videoId, {
    required bool safeMode,
  }) async {
    final downloadService = ref.read(downloadServiceProvider);

    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Downloading...'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 16),
              Text(
                safeMode ? '🛡️ Safe Mode' : '🧠 Smart Mode',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Processing video...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await downloadService.downloadVideo(
        videoId,
        safeMode: safeMode,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      if (success) {
        _showSuccessDialog(
          'Video downloaded successfully!',
          'The audio file has been added to your library.',
        );
      } else {
        _showErrorDialog('Failed to download video. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog('Download error: $e');
    }
  }

  void _showSuccessDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Extracts audio from current YouTube video and plays it in the background
  Future<void> _playCurrentVideoInBackground() async {
    final url = await _webViewController.currentUrl();
    if (url == null) {
      _showErrorDialog('Unable to get current page URL');
      return;
    }

    final videoId = _extractVideoId(url);
    if (videoId == null) {
      _showErrorDialog('No YouTube video detected. Navigate to a video first.');
      return;
    }

    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text('Loading Audio...'),
        content: Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );

    try {
      final youtubeService = ref.read(youtubeServiceProvider);

      // Get audio stream URL and video info in parallel
      final results = await Future.wait([
        youtubeService.getAudioStreamUrl(videoId),
        youtubeService.getVideoInfo(videoId),
      ]);

      final audioUrl = results[0] as String?;
      final videoInfo = results[1] as YouTubeVideo?;

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (audioUrl == null || videoInfo == null) {
        _showErrorDialog('Could not load audio stream. Please try again.');
        return;
      }

      // Play audio in background
      ref
          .read(audioPlayerServiceProvider.notifier)
          .playYouTubeVideo(
            audioUrl,
            videoInfo.title,
            videoInfo.author,
            videoInfo.thumbnailUrl,
          );

      // Show success feedback
      _showSuccessDialog(
        'Now Playing',
        'Audio is playing in the background. You can minimize the app.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Error loading audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: AppTheme.backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header with Browser Controls
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppTheme.backgroundColor,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title
                        const Text(
                          'YouTube Browser',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Action Buttons (Download & Background Play)
                        Row(
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              onPressed: _playCurrentVideoInBackground,
                              child: const Icon(
                                CupertinoIcons.play_circle_fill,
                                size: 26,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              onPressed: _downloadCurrentVideo,
                              child: const Icon(
                                CupertinoIcons.cloud_download,
                                size: 24,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Browser Navigation Bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Back
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _canGoBack
                                ? () async {
                                    if (await _webViewController.canGoBack()) {
                                      _webViewController.goBack();
                                    }
                                  }
                                : null,
                            child: Icon(
                              CupertinoIcons.chevron_back,
                              color: _canGoBack ? Colors.white : Colors.white24,
                            ),
                          ),
                          // Forward
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _canGoForward
                                ? () async {
                                    if (await _webViewController
                                        .canGoForward()) {
                                      _webViewController.goForward();
                                    }
                                  }
                                : null,
                            child: Icon(
                              CupertinoIcons.chevron_forward,
                              color: _canGoForward
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
                          // Spacer
                          const Spacer(),
                          // Home
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _webViewController.loadRequest(
                                Uri.parse(_homeUrl),
                              );
                            },
                            child: const Icon(
                              CupertinoIcons.house_fill,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Refresh
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _webViewController.reload();
                            },
                            child: const Icon(
                              CupertinoIcons.refresh,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              if (_isLoading)
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    AppTheme.primaryColor.withOpacity(0.8),
                  ),
                ),

              // WebView
              Expanded(child: WebViewWidget(controller: _webViewController)),
            ],
          ),
        ),
      ),
    );
  }
}
