import 'dart:io';

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

  static String get rewardedTestUnitId {
    if (Platform.isAndroid) return androidRewardedTestUnitId;
    if (Platform.isIOS) return iosRewardedTestUnitId;
    throw UnsupportedError('Google Mobile Ads is only configured for mobile.');
  }

  static String get interstitialTestUnitId {
    if (Platform.isAndroid) return androidInterstitialTestUnitId;
    if (Platform.isIOS) return iosInterstitialTestUnitId;
    throw UnsupportedError('Google Mobile Ads is only configured for mobile.');
  }
}
