import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';
import 'admob_config.dart';
import 'ads_consent_manager.dart';
import 'google_mobile_ads_rewarded_service.dart';

class MonetizationBootstrap extends StatefulWidget {
  const MonetizationBootstrap({required this.child, super.key});

  final Widget child;

  @override
  State<MonetizationBootstrap> createState() => _MonetizationBootstrapState();
}

class _MonetizationBootstrapState extends State<MonetizationBootstrap> {
  final AdsConsentManager _consentManager = AdsConsentManager();

  bool _privacyOptionsRequired = false;
  bool _bootstrapping = false;

  @override
  void initState() {
    super.initState();
    DebugAdRuntime.instance.addListener(_onAdRuntimeChanged);
    unawaited(_bootstrapDebugAds());
  }

  @override
  void dispose() {
    DebugAdRuntime.instance.removeListener(_onAdRuntimeChanged);
    if (kDebugMode) DebugAdRuntime.instance.reset();
    super.dispose();
  }

  void _onAdRuntimeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrapDebugAds() async {
    if (!kDebugMode || _bootstrapping) return;
    _bootstrapping = true;

    try {
      final AdsConsentState consent = await _consentManager.gather();
      if (!mounted) return;

      setState(() {
        _privacyOptionsRequired = consent.privacyOptionsRequired;
      });

      if (!consent.canRequestAds) {
        DebugAdRuntime.instance.reset();
        return;
      }

      await MobileAds.instance.initialize();
      if (!mounted) return;

      late final GoogleMobileAdsRewardedService rewardedService;
      rewardedService = GoogleMobileAdsRewardedService(
        adUnitId: AdMobConfig.rewardedTestUnitId,
        onAvailabilityChanged: DebugAdRuntime.instance.availabilityChanged,
      );
      DebugAdRuntime.instance.attach(
        delegate: rewardedService,
        disposeDelegate: rewardedService.dispose,
      );
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _showPrivacyOptions() async {
    await _consentManager.showPrivacyOptions();
    final bool canRequestAds =
        await ConsentInformation.instance.canRequestAds();
    if (!canRequestAds) {
      DebugAdRuntime.instance.reset();
      return;
    }
    if (!DebugAdRuntime.instance.rewardedReady) {
      await _bootstrapDebugAds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        if (kDebugMode && _privacyOptionsRequired)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 62,
            child: Material(
              color: Colors.white.withValues(alpha: .10),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Privacy options',
                onPressed: _showPrivacyOptions,
                icon: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
