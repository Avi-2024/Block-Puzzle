import 'package:flutter/foundation.dart';

enum RewardPlacement { revive, extraPiece, doubleCoins }

abstract interface class AdService {
  bool get rewardedReady;
  Future<bool> showRewarded(RewardPlacement placement);
}

class _DisabledAdService implements AdService {
  const _DisabledAdService();

  @override
  bool get rewardedReady => false;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async => false;
}

/// Compatibility service used by existing GameScreen wiring.
///
/// In debug/test builds it remains a true no-op. In release builds it delegates
/// to the runtime provider once consent and Google Mobile Ads initialization
/// complete. This keeps current UI/controller code stable while allowing live
/// rewarded ads in signed production builds.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  bool get rewardedReady =>
      kReleaseMode ? AdRuntime.instance.rewardedReady : false;

  @override
  Future<bool> showRewarded(RewardPlacement placement) {
    if (!kReleaseMode) return Future<bool>.value(false);
    return AdRuntime.instance.showRewarded(placement);
  }
}

/// Stable runtime facade used by new callers in both debug and release builds.
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

  AdService _delegate = const _DisabledAdService();
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
    _delegate = const _DisabledAdService();
    notifyListeners();
  }
}

/// Backward-compatible aliases retained while callers migrate to runtime names.
class DebugRewardAdService extends RuntimeRewardAdService {
  const DebugRewardAdService();
}

abstract final class DebugAdRuntime {
  static AdRuntime get instance => AdRuntime.instance;
}
