import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsConsentState {
  const AdsConsentState({
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  final bool canRequestAds;
  final bool privacyOptionsRequired;
}

class AdsConsentManager {
  Future<AdsConsentState> gather() async {
    final Completer<void> updateCompleter = Completer<void>();
    final ConsentRequestParameters parameters = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      parameters,
      () {
        if (!updateCompleter.isCompleted) updateCompleter.complete();
      },
      (FormError error) {
        // A previous valid consent decision can still allow ad requests even
        // if this network refresh fails, so continue to the authoritative
        // canRequestAds() check instead of blocking the game.
        if (!updateCompleter.isCompleted) updateCompleter.complete();
      },
    );

    await updateCompleter.future;

    final Completer<void> formCompleter = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
      if (!formCompleter.isCompleted) formCompleter.complete();
    });
    await formCompleter.future;

    final bool canRequestAds =
        await ConsentInformation.instance.canRequestAds();
    final bool privacyOptionsRequired =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;

    return AdsConsentState(
      canRequestAds: canRequestAds,
      privacyOptionsRequired: privacyOptionsRequired,
    );
  }

  Future<void> showPrivacyOptions() async {
    final Completer<void> completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }
}
