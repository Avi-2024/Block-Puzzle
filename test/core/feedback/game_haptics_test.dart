import 'package:blockiva/core/feedback/game_haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('haptic preference survives a new instance and inactive app stays quiet', () async {
    SharedPreferences.setMockInitialValues({});
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async { calls.add(call); return null; });
    final first = GameHaptics();
    await first.initialize();
    await first.setEnabled(false);
    final restored = GameHaptics();
    await restored.initialize();
    await restored.reward();
    expect(calls, isEmpty);
    await restored.setEnabled(true);
    restored.active = false;
    await restored.selection();
    expect(calls, isEmpty);
    restored.active = true;
    await restored.impact();
    expect(calls.single.method, 'HapticFeedback.vibrate');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
}
