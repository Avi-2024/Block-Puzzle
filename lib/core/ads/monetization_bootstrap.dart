import 'dart:async';

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
    AdRuntime.instance.addListener(_onAdRuntimeChanged);
    unawaited(_bootstrapAds());
  }

  @override
  void dispose() {
    AdRuntime.instance
      ..removeListener(_onAdRuntimeChanged)
      ..reset();
    super.dispose();
  }

  void _onAdRuntimeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrapAds() async {
    if (_bootstrapping) return;
    final String? rewardedUnitId = AdMobConfig.rewardedUnitId;
    if (rewardedUnitId == null) {
      AdRuntime.instance.reset();
      return;
    }

    _bootstrapping = true;
    try {
      final AdsConsentState consent = await _consentManager.gather();
      if (!mounted) return;

      setState(() {
        _privacyOptionsRequired = consent.privacyOptionsRequired;
      });

      if (!consent.canRequestAds) {
        AdRuntime.instance.reset();
        return;
      }

      await MobileAds.instance.initialize();
      if (!mounted) return;

      late final GoogleMobileAdsRewardedService rewardedService;
      rewardedService = GoogleMobileAdsRewardedService(
        adUnitId: rewardedUnitId,
        onAvailabilityChanged: AdRuntime.instance.availabilityChanged,
      );
      AdRuntime.instance.attach(
        delegate: rewardedService,
        disposeDelegate: rewardedService.dispose,
      );
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _showPrivacyOptions() async {
    await _consentManager.showPrivacyOptions();
    final bool canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!canRequestAds) {
      AdRuntime.instance.reset();
      return;
    }
    if (!AdRuntime.instance.rewardedReady) {
      await _bootstrapAds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        if (_privacyOptionsRequired)
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
