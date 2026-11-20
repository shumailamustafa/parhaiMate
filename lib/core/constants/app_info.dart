import 'package:package_info_plus/package_info_plus.dart';

/// Build metadata read once at startup so the UI never shows a stale,
/// hard-coded version after an update.
abstract final class AppInfo {
  /// Fallback used in tests or if the platform call fails.
  static String version = '1.0.0';
  static String buildNumber = '1';

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        version = info.version;
      }
      if (info.buildNumber.isNotEmpty) {
        buildNumber = info.buildNumber;
      }
    } catch (_) {
      // Keep fallback values.
    }
  }
}
