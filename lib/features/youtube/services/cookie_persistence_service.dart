import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Native iOS cookie persistence service.
/// Uses a MethodChannel to call native iOS WKHTTPCookieStore APIs
/// to save and restore YouTube/Google cookies across app restarts.
class CookiePersistenceService {
  static const _channel = MethodChannel('com.doplin/cookie_manager');

  /// Saves all YouTube/Google cookies from WKWebsiteDataStore to UserDefaults.
  /// Returns the number of cookies saved.
  static Future<int> saveCookies() async {
    try {
      final count = await _channel.invokeMethod<int>('saveCookies');
      debugPrint('Saved $count YouTube cookies');
      return count ?? 0;
    } catch (e) {
      debugPrint('Error saving cookies: $e');
      return 0;
    }
  }

  /// Restores previously saved cookies back into WKWebsiteDataStore.
  static Future<void> restoreCookies() async {
    try {
      await _channel.invokeMethod('restoreCookies');
      debugPrint('Cookies restored');
    } catch (e) {
      debugPrint('Error restoring cookies: $e');
    }
  }

  /// Clears all saved cookies from UserDefaults.
  static Future<void> clearSavedCookies() async {
    try {
      await _channel.invokeMethod('clearSavedCookies');
      debugPrint('Saved cookies cleared');
    } catch (e) {
      debugPrint('Error clearing saved cookies: $e');
    }
  }
}
