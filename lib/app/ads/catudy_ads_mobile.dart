import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _testAdsEnabled = bool.fromEnvironment('CATUDY_TEST_ADS');

Future<void>? _initializeFuture;

bool get catudyAdsEnabled {
  return (kDebugMode || _testAdsEnabled) &&
      (Platform.isAndroid || Platform.isIOS);
}

Future<void> initializeCatudyAds() {
  if (!catudyAdsEnabled) {
    return Future.value();
  }
  return _initializeFuture ??= _initializeMobileAds();
}

Future<void> _initializeMobileAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (error) {
    debugPrint('Catudy test ads init failed: $error');
  }
}
