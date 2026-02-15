import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up MethodChannel for cookie persistence
    let controller = window?.rootViewController as! FlutterViewController
    let cookieChannel = FlutterMethodChannel(
      name: "com.doplin/cookie_manager",
      binaryMessenger: controller.binaryMessenger
    )

    cookieChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "saveCookies":
        self?.saveCookies(result: result)
      case "restoreCookies":
        self?.restoreCookies(result: result)
      case "clearSavedCookies":
        UserDefaults.standard.removeObject(forKey: "youtube_cookies")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Restore cookies early on app launch
    restoreCookiesSilently()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveCookies(result: @escaping FlutterResult) {
    let dataStore = WKWebsiteDataStore.default()
    dataStore.httpCookieStore.getAllCookies { cookies in
      // Filter for YouTube/Google cookies only
      let relevantCookies = cookies.filter { cookie in
        let domain = cookie.domain.lowercased()
        return domain.contains("youtube.com") ||
               domain.contains("google.com") ||
               domain.contains("googlevideo.com") ||
               domain.contains("gstatic.com")
      }

      var cookieDataArray: [[String: Any]] = []
      for cookie in relevantCookies {
        var cookieDict: [String: Any] = [
          "name": cookie.name,
          "value": cookie.value,
          "domain": cookie.domain,
          "path": cookie.path,
          "isSecure": cookie.isSecure,
          "isHTTPOnly": cookie.isHTTPOnly,
        ]
        if let expiresDate = cookie.expiresDate {
          cookieDict["expiresDate"] = expiresDate.timeIntervalSince1970
        }
        cookieDataArray.append(cookieDict)
      }

      if let jsonData = try? JSONSerialization.data(withJSONObject: cookieDataArray),
         let jsonString = String(data: jsonData, encoding: .utf8) {
        UserDefaults.standard.set(jsonString, forKey: "youtube_cookies")
        UserDefaults.standard.synchronize()
        result(relevantCookies.count)
      } else {
        result(0)
      }
    }
  }

  private func restoreCookies(result: @escaping FlutterResult) {
    restoreCookiesSilently()
    result(nil)
  }

  private func restoreCookiesSilently() {
    guard let jsonString = UserDefaults.standard.string(forKey: "youtube_cookies"),
          let jsonData = jsonString.data(using: .utf8),
          let cookieDataArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
    else { return }

    let cookieStore = WKWebsiteDataStore.default().httpCookieStore

    for cookieDict in cookieDataArray {
      var properties: [HTTPCookiePropertyKey: Any] = [
        .name: cookieDict["name"] as? String ?? "",
        .value: cookieDict["value"] as? String ?? "",
        .domain: cookieDict["domain"] as? String ?? "",
        .path: cookieDict["path"] as? String ?? "/",
      ]

      if let isSecure = cookieDict["isSecure"] as? Bool, isSecure {
        properties[.secure] = "TRUE"
      }

      if let expiresTimestamp = cookieDict["expiresDate"] as? Double {
        properties[.expires] = Date(timeIntervalSince1970: expiresTimestamp)
      }

      if let cookie = HTTPCookie(properties: properties) {
        cookieStore.setCookie(cookie)
      }
    }
  }
}
