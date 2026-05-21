import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Compares two semver strings like "1.2.3".
/// Returns true if [remote] is newer than [local].
bool _isNewer(String local, String remote) {
  List<int> parse(String value) {
    final match = RegExp(r'\d+(?:\.\d+)*').firstMatch(value);
    if (match == null) {
      return const [0];
    }
    return match
        .group(0)!
        .split('.')
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }

  final localParts = parse(local);
  final remoteParts = parse(remote);
  final length = localParts.length > remoteParts.length
      ? localParts.length
      : remoteParts.length;

  for (var i = 0; i < length; i++) {
    final localValue = i < localParts.length ? localParts[i] : 0;
    final remoteValue = i < remoteParts.length ? remoteParts[i] : 0;
    if (remoteValue > localValue) return true;
    if (remoteValue < localValue) return false;
  }
  return false;
}

String _readString(Map<String, dynamic> data, String key) {
  return data[key]?.toString().trim() ?? '';
}

String _cleanVersion(String value) {
  return RegExp(r'\d+(?:\.\d+)*').firstMatch(value)?.group(0) ?? value.trim();
}

String _readLocalizedText(Object? value, String languageCode) {
  if (value is String) {
    return value.trim();
  }
  if (value is Map<String, dynamic>) {
    final language = languageCode.toLowerCase().split('-').first;
    return (value[language] ?? value['en'] ?? value['tr'] ?? '')
        .toString()
        .trim();
  }
  return '';
}

String _resolveUrl(String rawUrl, String manifestUrl) {
  final value = rawUrl.trim();
  if (value.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    return uri.toString();
  }
  return Uri.parse(manifestUrl).resolve(value).toString();
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

  static const _manifestUrl = String.fromEnvironment(
    'CATUDY_UPDATE_MANIFEST_URL',
    defaultValue:
        'https://catudy.com/downloads/catudy-android-demo-latest.json',
  );
  static const _fallbackApkUrl =
      'https://catudy.com/downloads/catudy-android-demo-latest.apk';

  /// Current app version from pubspec, injected by the deploy script with
  /// --dart-define=APP_VERSION.
  static const currentVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '2.1.6',
  );

  /// Checks the Catudy site manifest for a newer APK.
  /// Returns null when the app is up-to-date, unsupported, or offline.
  Future<CatudyUpdateInfo?> checkForUpdate({String languageCode = 'en'}) async {
    if (kIsWeb) return null; // Web doesn't need APK updates
    if (!Platform.isAndroid) return null;

    try {
      final response = await http
          .get(
            Uri.parse(_manifestUrl),
            headers: const {
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final version = _cleanVersion(_readString(decoded, 'version'));
      if (version.isEmpty || !_isNewer(currentVersion, version)) return null;

      var apkUrl = _resolveUrl(_readString(decoded, 'apkUrl'), _manifestUrl);
      if (apkUrl.isEmpty) {
        apkUrl = _resolveUrl(
          _readString(decoded, 'latestApkUrl'),
          _manifestUrl,
        );
      }

      return CatudyUpdateInfo(
        version: version,
        apkUrl: apkUrl.isEmpty ? _fallbackApkUrl : apkUrl,
        releaseNotes: _readLocalizedText(decoded['releaseNotes'], languageCode),
      );
    } catch (e) {
      debugPrint('CatudyUpdateService: check failed - $e');
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
      final safeVersion = info.version.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final apkFile = File(
        '${dir.path}${Platform.pathSeparator}catudy_update_$safeVersion.apk',
      );

      final request = http.Request('GET', Uri.parse(info.apkUrl));
      final response = await request.send().timeout(const Duration(minutes: 5));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'APK download failed: HTTP ${response.statusCode}',
          uri: Uri.parse(info.apkUrl),
        );
      }

      final total = response.contentLength ?? 0;
      var received = 0;

      final sink = apkFile.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress?.call(received / total);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      onProgress?.call(1.0);

      await OpenFile.open(apkFile.path);
    } catch (e) {
      debugPrint('CatudyUpdateService: download failed - $e');
      rethrow;
    }
  }
}
