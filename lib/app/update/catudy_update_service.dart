import 'package:flutter/foundation.dart';

class CatudyUpdateInfo {
  const CatudyUpdateInfo({
    required this.version,
    required this.storeUrl,
    required this.releaseNotes,
  });

  final String version;
  final String storeUrl;
  final String releaseNotes;
}

class CatudyUpdateService {
  CatudyUpdateService._();
  static final instance = CatudyUpdateService._();

  /// Play builds do not use in-app package download/update flows.
  Future<CatudyUpdateInfo?> checkForUpdate({String languageCode = 'en'}) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      return null;
    }
    return null;
  }

  Future<void> downloadAndInstall(
    CatudyUpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0);
    throw UnsupportedError('Direct APK updates are disabled for Play builds.');
  }
}
