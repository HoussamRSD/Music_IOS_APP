import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../../core/theme/app_theme.dart';
import '../../download/services/download_service.dart'; // Keep for future generic download
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
  bool _isMenuOpen = false;

  static const String _homeUrl = 'https://m.youtube.com';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1',
      )
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _isMenuOpen = false; // Auto-close menu on navigation
              });
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              // INJECT JS TO PREVENT BACKGROUND PAUSE
              // This overrides the Page Visibility API to always return 'visible'
              await _webViewController.runJavaScript('''
                Object.defineProperty(document, 'hidden', { get: function() { return false; } });
                Object.defineProperty(document, 'visibilityState', { get: function() { return 'visible'; } });
                
                var video = document.querySelector('video');
                if (video) {
                   video.pause = function() { console.log('Pause prevented!'); };
                   // Optional: video.play(); 
                }
              ''');

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
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_homeUrl));
  }

  void _toggleMenu() {
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  Future<void> _handleDownload() async {
    final url = await _webViewController.currentUrl();
    if (url == null) return;

    final videoId = _extractVideoId(url);
    if (videoId == null) {
      _showErrorDialog('No video detected. Please play a video first.');
      return;
    }

    setState(() => _isMenuOpen = false);

    // 1. Fetch Video Metadata & Qualities
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Column(
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 10),
            Text('Fetching video info...'),
          ],
        ),
      ),
    );

    try {
      final downloadService = ref.read(downloadServiceProvider);
      final youtubeService = ref.read(youtubeServiceProvider);

      // 1. Fetch Video Info first (Lightweight)
      debugPrint('Fetching Video Info for $videoId...');
      final videoInfo = await youtubeService
          .getVideoInfo(videoId)
          .timeout(const Duration(seconds: 5));
      debugPrint('Video Info fetched: ${videoInfo?.title}');

      // 2. Fetch Qualities (Heavier, involves manifest)
      debugPrint('Fetching Video Qualities...');
      final qualities = await downloadService
          .getVideoQualities(videoId)
          .timeout(const Duration(seconds: 10));
      debugPrint('Qualities fetched: ${qualities.length}');

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // 3. Show Options Sheet
      _showDownloadOptionsSheet(videoId, qualities, videoInfo);
    } catch (e, stack) {
      debugPrint('Error in _handleDownload: $e\n$stack');
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Failed to load video info: $e');
    }
  }

  Future<void> _handleClearData() async {
    setState(() => _isMenuOpen = false); // Close menu

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear YouTube Data'),
        content: const Text(
          'This will sign you out and clear all local YouTube data (cookies, cache). Are you sure?',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context); // Close confirmation

              // Show loading
              showCupertinoDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const CupertinoAlertDialog(
                  content: Column(
                    children: [
                      CupertinoActivityIndicator(),
                      SizedBox(height: 10),
                      Text('Clearing data...'),
                    ],
                  ),
                ),
              );

              try {
                // Clear Cookies & Cache
                await WebViewCookieManager().clearCookies();
                await _webViewController.clearCache();
                await _webViewController.clearLocalStorage();

                // Reload Home
                _webViewController.loadRequest(Uri.parse(_homeUrl));

                if (!mounted) return;
                Navigator.pop(context); // Close loading
                _showSuccessDialog(
                  'Data Cleared',
                  'You have been signed out and all YouTube data has been cleared.',
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                _showErrorDialog('Failed to clear data: $e');
              }
            },
            child: const Text('Clear Data'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDownloadOptionsSheet(
    String videoId,
    List<dynamic> qualities,
    YouTubeVideo? videoInfo,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(videoInfo?.title ?? 'Download Options'),
        message: const Text('Select format and quality'),
        actions: [
          // Section 1: Audio Options
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _startDownload(videoId, isAudio: true, safeMode: false);
            },
            child: const Text('🎵 Audio - Smart Mode (Metadata + Lyrics)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _startDownload(videoId, isAudio: true, safeMode: true);
            },
            child: const Text('🛡️ Audio - Safe Mode (As-is)'),
          ),

          // Section 2: Video Options (Filtered Unique by Quality Label)
          ...qualities
              .map((q) {
                final qualityLabel = q.videoQuality
                    .toString(); // or custom getter if added
                // Clean up label if needed, e.g. "VideoQuality.high720" -> "720p"
                final label =
                    qualityLabel.split('.').last.replaceAll('high', '') + 'p';

                return CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _startDownload(
                      videoId,
                      isAudio: false,
                      qualityLabel: qualityLabel,
                    );
                  },
                  child: Text('🎬 Video - $label'),
                );
              })
              .toSet()
              .toList(), // Basic dedup logic might be needed
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _startDownload(
    String videoId, {
    required bool isAudio,
    bool safeMode = false,
    String? qualityLabel,
  }) async {
    // Show Progress
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Column(
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(height: 10),
            Text(isAudio ? 'Downloading Audio...' : 'Downloading Video...'),
            if (safeMode)
              const Text(
                '(Safe Mode)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );

    final success = await ref
        .read(downloadServiceProvider)
        .downloadVideo(
          videoId,
          isAudioOnly: isAudio,
          safeMode: safeMode,
          qualityLabel: qualityLabel,
        );

    if (!mounted) return;
    Navigator.pop(context); // Close progress

    if (success) {
      _showSuccessDialog('Success', 'Download completed successfully!');
    } else {
      _showErrorDialog('Download failed. Please try again.');
    }
  }

  Future<void> _playCurrentVideoInBackground() async {
    final url = await _webViewController.currentUrl();
    if (url == null) return;

    final videoId = _extractVideoId(url);
    if (videoId == null) {
      _showErrorDialog('No YouTube video detected. Navigate to a video first.');
      return;
    }

    setState(() => _isMenuOpen = false);

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

  String? _extractVideoId(String url) {
    try {
      if (url.contains('youtube.com/watch')) {
        final uri = Uri.parse(url);
        return uri.queryParameters['v'];
      } else if (url.contains('youtu.be/')) {
        return url.split('youtu.be/').last.split('?').first;
      }
    } catch (e) {}
    return null;
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
        title: const Text('Notice'),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Edge-to-Edge WebView
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                bottom:
                    kBottomNavigationBarHeight +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: WebViewWidget(controller: _webViewController),
            ),

            // 2. Loading Indicator (Top)
            if (_isLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    AppTheme.primaryColor.withOpacity(0.8),
                  ),
                ),
              ),

            // 3. Floating Control Menu (Bottom Right)
            Positioned(
              // Position above App Bottom Bar + YouTube Bottom Bar (~50px) + Buffer
              bottom:
                  kBottomNavigationBarHeight +
                  MediaQuery.of(context).padding.bottom +
                  60,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isMenuOpen) ...[
                    _FloatingMenuItem(
                      icon: CupertinoIcons.cloud_download,
                      label: 'Download',
                      onTap: _handleDownload,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(height: 12),
                    _FloatingMenuItem(
                      icon: CupertinoIcons.play_circle_fill,
                      label: 'Background Audio',
                      onTap: _playCurrentVideoInBackground,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _FloatingMenuItem(
                      icon: CupertinoIcons.refresh,
                      label: 'Refresh',
                      onTap: () {
                        _webViewController.reload();
                        _toggleMenu();
                      },
                    ),
                    const SizedBox(height: 12),
                    _FloatingMenuItem(
                      icon: CupertinoIcons.house_fill,
                      label: 'Home',
                      onTap: () {
                        _webViewController.loadRequest(Uri.parse(_homeUrl));
                        _toggleMenu();
                      },
                    ),
                    const SizedBox(height: 12),
                    _FloatingMenuItem(
                      icon: CupertinoIcons.trash,
                      label: 'Clear Data',
                      onTap: _handleClearData,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FloatingMenuItem(
                          icon: CupertinoIcons.chevron_back,
                          label: '',
                          onTap: _canGoBack
                              ? () {
                                  _webViewController.goBack();
                                }
                              : null,
                          isMini: true,
                        ),
                        const SizedBox(width: 12),
                        _FloatingMenuItem(
                          icon: CupertinoIcons.chevron_forward,
                          label: '',
                          onTap: _canGoForward
                              ? () {
                                  _webViewController.goForward();
                                }
                              : null,
                          isMini: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Main Toggle Button
                  FloatingActionButton(
                    onPressed: _toggleMenu,
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(
                      _isMenuOpen ? CupertinoIcons.xmark : CupertinoIcons.add,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool isMini;

  const _FloatingMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
    this.isMini = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isMini ? 40 : 56,
            height: isMini ? 40 : 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: isMini ? 20 : 28),
          ),
        ),
      ],
    );
  }
}
