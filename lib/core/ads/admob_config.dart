import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class AdMobConfig {
  // Google's dedicated sample application IDs. These are safe for development
  // and CI test builds. Never replace these with production IDs in source.
  static const String androidTestAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String iosTestAppId =
      'ca-app-pub-3940256099942544~1458002511';

  static const String androidRewardedTestUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedTestUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  static const String androidInterstitialTestUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String iosInterstitialTestUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  // Production IDs are injected at build time. They are intentionally absent
  // from source control so public repository code never exposes live units.
  static const String _androidRewardedProductionUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
  );
  static const String _iosRewardedProductionUnitId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
  );

  static String? get rewardedUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) return androidRewardedTestUnitId;
      return _androidRewardedProductionUnitId.isEmpty
          ? null
          : _androidRewardedProductionUnitId;
    }
    if (Platform.isIOS) {
      if (kDebugMode) return iosRewardedTestUnitId;
      return _iosRewardedProductionUnitId.isEmpty
          ? null
          : _iosRewardedProductionUnitId;
    }
    return null;
  }

  static String get interstitialTestUnitId {
    if (Platform.isAndroid) return androidInterstitialTestUnitId;
    if (Platform.isIOS) return iosInterstitialTestUnitId;
    throw UnsupportedError('Google Mobile Ads is only configured for mobile.');
  }
}
