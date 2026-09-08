import 'package:flutter/foundation.dart';

import 'ad_service.dart';

/// Keeps the game fully playable while consent and an ad SDK initialize in the
/// background. A real provider can be attached later without recreating the
/// current game session.
class DeferredAdService extends ChangeNotifier implements AdService {
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

  @override
  void dispose() {
    _delegateDisposer?.call();
    _delegateDisposer = null;
    super.dispose();
  }
}
