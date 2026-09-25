import 'package:blockiva/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score stages have distinct dark backgrounds and deterministic resume', () {
    final start = AppTheme.gameplayGradientForScore(0);
    final dusk = AppTheme.gameplayGradientForScore(1000);
    final lagoon = AppTheme.gameplayGradientForScore(2000);
    expect(AppTheme.gameplayGradientForScore(999).colors, start.colors);
    expect(dusk.colors, isNot(start.colors));
    expect(lagoon.colors, isNot(dusk.colors));
    expect(AppTheme.gameplayGradientForScore(3000).colors, start.colors);
    expect(AppTheme.gameplayGradientForScore(1510).colors, dusk.colors);
  });
}
