import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../ui/components/tab_header.dart';
import '../../download/services/download_service.dart';
import '../../player/services/audio_player_service.dart';
import '../services/youtube_service.dart';

class YouTubeWebViewScreen extends ConsumerStatefulWidget {
  const YouTubeWebViewScreen({super.key});

  @override
  ConsumerState<YouTubeWebViewScreen> createState() =>
      _YouTubeWebViewScreenState();
}

class _YouTubeWebViewScreenState extends ConsumerState<YouTubeWebViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _showDownloadOptions = false;

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
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.youtube.com'));
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
      print('Error extracting video ID: $e');
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
      final videoInfo = results[1];

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
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TabHeader(
                  title: 'YouTube',
                  icon: CupertinoIcons.play_rectangle_fill,
                  actionButton: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play in Background button
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: _playCurrentVideoInBackground,
                        child: const Icon(
                          CupertinoIcons.play_circle_fill,
                          size: 26,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      // Download button
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: _downloadCurrentVideo,
                        child: const Icon(
                          CupertinoIcons.cloud_download,
                          size: 24,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: WebViewWidget(controller: _webViewController)),
              ],
            ),
            if (_isLoading)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    AppTheme.accentColor.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
