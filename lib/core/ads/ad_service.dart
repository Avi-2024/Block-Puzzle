import 'package:flutter/foundation.dart';

enum RewardPlacement { revive, extraPiece, doubleCoins }

abstract interface class AdService {
  bool get rewardedReady;
  Future<bool> showRewarded(RewardPlacement placement);
}

/// Safe fallback when ads are unavailable, consent is not granted, or
/// production ad identifiers have not been configured.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  bool get rewardedReady => false;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async => false;
}

/// Stable facade used by the game controller in both debug and release builds.
/// The concrete Google Mobile Ads provider is attached asynchronously after
/// consent and SDK initialization complete.
class RuntimeRewardAdService implements AdService {
  const RuntimeRewardAdService();

  @override
  bool get rewardedReady => AdRuntime.instance.rewardedReady;

  @override
  Future<bool> showRewarded(RewardPlacement placement) =>
      AdRuntime.instance.showRewarded(placement);
}

class AdRuntime extends ChangeNotifier implements AdService {
  AdRuntime._();

  static final AdRuntime instance = AdRuntime._();

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

/// Backward-compatible aliases retained for older tests/callers while the
/// runtime naming is migrated across the codebase.
class DebugRewardAdService extends RuntimeRewardAdService {
  const DebugRewardAdService();
}

abstract final class DebugAdRuntime {
  static AdRuntime get instance => AdRuntime.instance;
}
