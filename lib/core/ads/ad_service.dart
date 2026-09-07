enum RewardPlacement { revive, extraPiece, doubleCoins }

abstract interface class AdService {
  bool get rewardedReady;
  Future<bool> showRewarded(RewardPlacement placement);
}

/// Release-safe fallback used until a real ad network implementation is added.
class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  bool get rewardedReady => false;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async => false;
}

/// Lets developers exercise rewarded flows without generating ad traffic.
/// Never use this implementation in release builds.
class DebugRewardAdService implements AdService {
  const DebugRewardAdService();

  @override
  bool get rewardedReady => true;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async => true;
}
