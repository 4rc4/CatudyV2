import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/ads/catudy_ads.dart';

class CatudyTestAdBanner extends StatefulWidget {
  const CatudyTestAdBanner({required this.show, super.key});

  final bool show;

  @override
  State<CatudyTestAdBanner> createState() => _CatudyTestAdBannerState();
}

class _CatudyTestAdBannerState extends State<CatudyTestAdBanner> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  int? _requestedWidth;
  int? _loadingWidth;

  static String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/9214589741';
    }
    return 'ca-app-pub-3940256099942544/2435281174';
  }

  @override
  void didUpdateWidget(covariant CatudyTestAdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show && !widget.show) {
      _disposeAd();
    }
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || !catudyAdsEnabled) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _availableWidth(context, constraints);
        if (width > 0) {
          _loadForWidth(width);
        }

        final bannerAd = _bannerAd;
        final adSize = _adSize;
        if (bannerAd == null || adSize == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Center(
            child: SizedBox(
              width: adSize.width.toDouble(),
              height: adSize.height.toDouble(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AdWidget(ad: bannerAd),
              ),
            ),
          ),
        );
      },
    );
  }

  int _availableWidth(BuildContext context, BoxConstraints constraints) {
    if (constraints.maxWidth.isFinite) {
      return constraints.maxWidth.truncate();
    }
    return MediaQuery.sizeOf(context).width.truncate();
  }

  void _loadForWidth(int width) {
    if (_requestedWidth == width || _loadingWidth == width) {
      return;
    }

    _loadingWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          !widget.show ||
          !catudyAdsEnabled ||
          _loadingWidth != width) {
        return;
      }

      await initializeCatudyAds();
      if (!mounted ||
          !widget.show ||
          !catudyAdsEnabled ||
          _loadingWidth != width) {
        return;
      }

      final adSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || !widget.show || _loadingWidth != width) {
        return;
      }
      if (adSize == null) {
        setState(() => _loadingWidth = null);
        return;
      }

      final ad = BannerAd(
        adUnitId: _adUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || !widget.show || _loadingWidth != width) {
              ad.dispose();
              return;
            }

            final previousAd = _bannerAd;
            setState(() {
              _bannerAd = ad as BannerAd;
              _adSize = adSize;
              _requestedWidth = width;
              _loadingWidth = null;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              previousAd?.dispose();
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Catudy test banner failed to load: $error');
            ad.dispose();
            if (mounted && _loadingWidth == width) {
              setState(() => _loadingWidth = null);
            }
          },
          onAdImpression: (ad) {
            debugPrint('Catudy test banner impression.');
          },
          onAdClicked: (ad) {
            debugPrint('Catudy test banner clicked.');
          },
        ),
      );

      try {
        await ad.load();
      } catch (error) {
        debugPrint('Catudy test banner load call failed: $error');
        ad.dispose();
        if (mounted && _loadingWidth == width) {
          setState(() => _loadingWidth = null);
        }
      }
    });
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _adSize = null;
    _requestedWidth = null;
    _loadingWidth = null;
  }
}
