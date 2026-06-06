import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

/// Holds the version info returned from the backend.
class VersionInfo {
  final String minimumVersion;
  final String latestVersion;
  final bool isForceUpdate;
  final String? updateMessage;

  const VersionInfo({
    required this.minimumVersion,
    required this.latestVersion,
    required this.isForceUpdate,
    this.updateMessage,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      minimumVersion: json['minimum_version'] ?? '1.0.0',
      latestVersion: json['latest_version'] ?? '1.0.0',
      isForceUpdate: json['is_force_update'] == true ||
          json['is_force_update'] == 'true' ||
          json['is_force_update'] == 1,
      updateMessage: json['update_message'],
    );
  }
}

class UpdateService {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.betebrana.app';

  /// Entry point — call this on every app startup.
  /// Runs both Option 1 (Google In-App Update API) and Option 2 (backend check).
  static Future<void> checkForUpdates(BuildContext context) async {
    // Option 1: Google Play In-App Update API (Android only, silent & official)
    if (Platform.isAndroid) {
      await _checkGooglePlayUpdate(context);
    }

    // Option 2: Backend version check (works on both Android & iOS)
    if (context.mounted) {
      await _checkBackendVersion(context);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION 1: Google Play In-App Update API
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _checkGooglePlayUpdate(BuildContext context) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          // Force immediate full-screen update (non-dismissible)
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Download in background, prompt user to restart
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (_) {
      // In-App Update API may not be available in all regions/emulators — ignore silently
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTION 2: Backend version check (Play Store redirect fallback)
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _checkBackendVersion(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseApiUrl}/version'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final versionInfo = VersionInfo.fromJson(data);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isUpdateRequired(currentVersion, versionInfo.minimumVersion)) {
        if (context.mounted) {
          _showForceUpdateDialog(
            context,
            versionInfo.updateMessage ??
                'A new version of Betebrana is available. Please update to continue.',
            isForce: versionInfo.isForceUpdate,
          );
        }
      }
    } catch (_) {
      // Network errors are fine — don't block the user if the server is unreachable
    }
  }

  /// Compares semantic versions. Returns true if currentVersion < minimumVersion.
  static bool _isUpdateRequired(String current, String minimum) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final m = minimum.split('.').map(int.parse).toList();
      for (int i = 0; i < m.length; i++) {
        final cv = i < c.length ? c[i] : 0;
        final mv = m[i];
        if (cv < mv) return true;
        if (cv > mv) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Shows a force update dialog. If [isForce] is true, the dialog cannot be dismissed.
  static void _showForceUpdateDialog(
    BuildContext context,
    String message, {
    required bool isForce,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (ctx) => PopScope(
        canPop: !isForce,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8C7362).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded,
                      color: Color(0xFF8C7362), size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  isForce ? 'Update Required' : 'Update Available',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B2F2F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B5A4E),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openPlayStore(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C7362),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!isForce) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Later',
                        style: TextStyle(color: Color(0xFF8C7362))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
