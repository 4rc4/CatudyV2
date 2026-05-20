import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Compares two semver strings like "1.2.3".
/// Returns true if [remote] is newer than [local].
bool _isNewer(String local, String remote) {
  List<int> parse(String v) =>
      v.replaceAll(RegExp(r'[^0-9.]'), '').split('.').map(int.tryParse).whereType<int>().toList();

  final l = parse(local);
  final r = parse(remote);
  for (var i = 0; i < r.length; i++) {
    final rv = i < r.length ? r[i] : 0;
    final lv = i < l.length ? l[i] : 0;
    if (rv > lv) return true;
    if (rv < lv) return false;
  }
  return false;
}

class CatudyUpdateInfo {
  const CatudyUpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
  });

  final String version;
  final String apkUrl;
  final String releaseNotes;
}

class CatudyUpdateService {
  CatudyUpdateService._();
  static final instance = CatudyUpdateService._();

  static const _owner = '4rc4';
  static const _repo = 'CatudyV2';
  static const _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Current app version from pubspec (injected at build time via --dart-define
  /// or read from the package_info_plus package). We keep a simple const here
  /// to avoid adding another dependency; update this when you bump pubspec.yaml.
  static const currentVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.3',
  );

  /// Checks GitHub for a newer release. Returns [CatudyUpdateInfo] when an
  /// update is available, or null when the app is up-to-date / on error.
  Future<CatudyUpdateInfo?> checkForUpdate() async {
    if (kIsWeb) return null; // Web doesn't need APK updates
    if (!Platform.isAndroid) return null;

    try {
      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').replaceAll('v', '');
      final body = data['body'] as String? ?? '';

      if (!_isNewer(currentVersion, tagName)) return null;

      // Find the APK asset
      final assets = data['assets'] as List<dynamic>? ?? [];
      final apkAsset = assets.firstWhere(
        (a) =>
            (a['name'] as String).toLowerCase().endsWith('.apk') &&
            (a['content_type'] as String?) == 'application/vnd.android.package-archive',
        orElse: () => null,
      );

      // Also try browser_download_url ending with .apk regardless of mime
      final apkUrl = apkAsset != null
          ? apkAsset['browser_download_url'] as String
          : (assets
                  .where(
                    (a) => (a['name'] as String).toLowerCase().endsWith('.apk'),
                  )
                  .map((a) => a['browser_download_url'] as String)
                  .firstOrNull ??
              '');

      if (apkUrl.isEmpty) return null;

      return CatudyUpdateInfo(
        version: tagName,
        apkUrl: apkUrl,
        releaseNotes: body,
      );
    } catch (e) {
      debugPrint('CatudyUpdateService: check failed — $e');
      return null;
    }
  }

  /// Downloads the APK and opens the system installer.
  /// Reports [progress] as a value between 0.0 and 1.0.
  Future<void> downloadAndInstall(
    CatudyUpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final externalDir = await getExternalStorageDirectory();
      final dir = externalDir ?? await getApplicationCacheDirectory();
      final apkFile = File('${dir.path}/catudy_update.apk');

      // Stream download so we can report progress
      final request = http.Request('GET', Uri.parse(info.apkUrl));
      final response = await request.send().timeout(const Duration(minutes: 5));

      final total = response.contentLength ?? 0;
      var received = 0;

      final sink = apkFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          onProgress?.call(received / total);
        }
      }
      await sink.flush();
      await sink.close();

      onProgress?.call(1.0);

      await OpenFile.open(apkFile.path);
    } catch (e) {
      debugPrint('CatudyUpdateService: download failed — $e');
      rethrow;
    }
  }
}
