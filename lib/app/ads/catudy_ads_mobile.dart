import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _testAdsEnabled = bool.fromEnvironment('CATUDY_TEST_ADS');

Future<void>? _initializeFuture;
bool _interstitialLoading = false;
final _shownInterstitialPlacements = <String>{};

bool get catudyAdsEnabled {
  return (kDebugMode || _testAdsEnabled) &&
      (Platform.isAndroid || Platform.isIOS);
}

String get _interstitialAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-3940256099942544/1033173712';
  }
  return 'ca-app-pub-3940256099942544/4411468910';
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

Future<void> showCatudyTestInterstitial({required String placementId}) async {
  if (!catudyAdsEnabled ||
      _interstitialLoading ||
      _shownInterstitialPlacements.contains(placementId)) {
    return;
  }

  _interstitialLoading = true;
  try {
    await initializeCatudyAds();
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _shownInterstitialPlacements.add(placementId);
          _interstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Catudy test interstitial failed to show: $error');
              ad.dispose();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Catudy test interstitial failed to load: $error');
          _interstitialLoading = false;
        },
      ),
    );
  } catch (error) {
    debugPrint('Catudy test interstitial load call failed: $error');
    _interstitialLoading = false;
  }
}
