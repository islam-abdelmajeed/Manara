import 'package:manara/core/platform/browser_actions_stub.dart'
    if (dart.library.js_interop) 'package:manara/core/platform/browser_actions_web.dart'
    as impl;

/// File download, printing and notifications, which only the web build can
/// do without extra packages. Elsewhere [supported] is false and all are
/// no-ops.
abstract final class BrowserActions {
  static bool get supported => impl.supported;

  /// Saves [content] as [filename].
  static void download(String filename, String mimeType, String content) =>
      impl.download(filename, mimeType, content);

  /// Opens the print dialog for an HTML page.
  static void printHtml(String html) => impl.printHtml(html);

  /// The browser's notification permission: `granted`, `denied`,
  /// `default` (not asked yet) or `unsupported`.
  static String get notificationPermission => impl.notificationPermission();

  /// Asks the browser for permission; returns the new state.
  static Future<String> requestNotificationPermission() =>
      impl.requestNotificationPermission();

  /// Shows a system notification (when permission is granted).
  static void notify(String title, String body) => impl.notify(title, body);
}
