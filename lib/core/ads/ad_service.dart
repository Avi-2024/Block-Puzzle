import 'package:flutter/foundation.dart';

enum RewardPlacement { revive, extraPiece, doubleCoins }

abstract interface class AdService {
  bool get rewardedReady;
  Future<bool> showRewarded(RewardPlacement placement);
}

/// Release-safe fallback used until production AdMob IDs are configured.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  bool get rewardedReady => false;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async => false;
}

/// Debug builds use this stable facade so the game controller can be created
/// immediately while consent + the Google test-ad provider initialize later.
class DebugRewardAdService implements AdService {
  const DebugRewardAdService();

  @override
  bool get rewardedReady => DebugAdRuntime.instance.rewardedReady;

  @override
  Future<bool> showRewarded(RewardPlacement placement) =>
      DebugAdRuntime.instance.showRewarded(placement);
}

class DebugAdRuntime extends ChangeNotifier implements AdService {
  DebugAdRuntime._();

  static final DebugAdRuntime instance = DebugAdRuntime._();

  AdService _delegate = const NoOpAdService();
  VoidCallback? _delegateDisposer;

  @override
  bool get rewardedReady => _delegate.rewardedReady;

  @override
  Future<bool> showRewarded(RewardPlacement placement) =>
      _delegate.showRewarded(placement);

  void attach({
    required AdService delegate,
    VoidCallback? disposeDelegate,
  }) {
    _delegateDisposer?.call();
    _delegate = delegate;
    _delegateDisposer = disposeDelegate;
    notifyListeners();
  }

  void availabilityChanged() => notifyListeners();

  void reset() {
    _delegateDisposer?.call();
    _delegateDisposer = null;
    _delegate = const NoOpAdService();
    notifyListeners();
  }
}
