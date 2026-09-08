import '../../features/progression/domain/progression_state.dart';

abstract interface class ProgressionRepository {
  Future<ProgressionState?> load();
  Future<void> save(ProgressionState state);
}
