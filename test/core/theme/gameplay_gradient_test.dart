import 'package:blockiva/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gameplay background stays static while score changes', () {
    final start = AppTheme.gameplayGradientForScore(0);
    for (final score in <int>[15, 999, 1000, 2000, 3000, 100000]) {
      expect(AppTheme.gameplayGradientForScore(score).colors, start.colors);
    }
  });
}
