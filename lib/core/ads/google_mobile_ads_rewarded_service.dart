import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

class GoogleMobileAdsRewardedService implements AdService {
  GoogleMobileAdsRewardedService({
    required this.adUnitId,
    this.onAvailabilityChanged,
  }) {
    _load();
  }

  final String adUnitId;
  final void Function()? onAvailabilityChanged;

  RewardedAd? _rewardedAd;
  bool _loading = false;
  bool _disposed = false;

  @override
  bool get rewardedReady => _rewardedAd != null;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async {
    final RewardedAd? ad = _rewardedAd;
    if (ad == null || _disposed) {
      _load();
      return false;
    }

    _rewardedAd = null;
    onAvailabilityChanged?.call();

    final Completer<bool> completer = Completer<bool>();
    var earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(earnedReward);
        _load();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete(false);
        _scheduleRetry();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        earnedReward = true;
      },
    );

    return completer.future;
  }

  void _load() {
    if (_disposed || _loading || _rewardedAd != null) return;
    _loading = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _loading = false;
          _rewardedAd = ad;
          onAvailabilityChanged?.call();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _loading = false;
          _scheduleRetry();
        },
      ),
    );
  }

  void _scheduleRetry() {
    if (_disposed) return;
    Future<void>.delayed(const Duration(seconds: 15), _load);
  }

  void dispose() {
    _disposed = true;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
