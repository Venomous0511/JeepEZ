import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get current build number
  static Future<String> getCurrentBuildNumber() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      return '0';
    }
  }

  /// Compare versions (returns true if newVersion > currentVersion)
  static bool isNewVersionAvailable(String currentVersion, String newVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final newVer = _parseVersion(newVersion);

      for (int i = 0; i < 3; i++) {
        if (newVer[i] > current[i]) return true;
        if (newVer[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Parse version string to list of integers
  static List<int> _parseVersion(String version) {
    try {
      // Remove 'v' prefix if present
      version = version.replaceFirst('v', '');
      // Remove pre-release tags
      version = version.split('-').first;

      final parts = version.split('.');
      while (parts.length < 3) {
        parts.add('0');
      }
      return parts.take(3).map((e) => int.tryParse(e) ?? 0).toList();
    } catch (e) {
      return [0, 0, 0];
    }
  }

  /// Open app store page for update
  static Future<bool> openAppStoreUpdate(
    String packageName, {
    String? releaseUrl,
  }) async {
    try {
      // Use GitHub release URL if provided, otherwise fall back to app stores
      if (releaseUrl != null && releaseUrl.isNotEmpty) {
        if (await canLaunchUrl(Uri.parse(releaseUrl))) {
          return await launchUrl(
            Uri.parse(releaseUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      }

      // For Android, try Google Play
      final playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';
      if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
        return await launchUrl(
          Uri.parse(playStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      }

      // For iOS, try App Store
      final appStoreUrl = 'https://apps.apple.com/app/$packageName';
      if (await canLaunchUrl(Uri.parse(appStoreUrl))) {
        return await launchUrl(
          Uri.parse(appStoreUrl),
          mode: LaunchMode.externalApplication,
        );
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Download APK from GitHub release
  static Future<bool> downloadAndInstallAPK(String downloadUrl) async {
    try {
      if (await canLaunchUrl(Uri.parse(downloadUrl))) {
        return await launchUrl(
          Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
