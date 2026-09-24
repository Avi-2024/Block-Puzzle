import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:blockiva/core/audio/game_audio_service.dart';
import 'package:blockiva/core/audio/game_sound_player.dart';
import 'package:blockiva/features/game/presentation/unified_game_screen.dart';
import 'package:blockiva/features/game/presentation/piece_tray.dart';
import 'package:blockiva/features/progression/application/progression_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

class _SilentPlayer implements GameSoundPlayer {
  @override
  Future<void> prepare(Source source, double volume) async {}
  @override
  Future<void> restart() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

final class _MemoryAsyncPreferences extends SharedPreferencesAsyncPlatform {
  final values = <String, Object>{};
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async => values[key] as String?;
  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async => values[key] as int?;
  @override
  Future<void> setString(String key, String value, SharedPreferencesOptions options) async { values[key] = value; }
  @override
  Future<void> setInt(String key, int value, SharedPreferencesOptions options) async { values[key] = value; }
  @override
  Future<void> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) async { values.clear(); }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final size in [const Size(320, 568), const Size(360, 640), const Size(393, 852), const Size(412, 915)]) {
    testWidgets('mobile HUD, board, settings fit $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance = _MemoryAsyncPreferences();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = GameAudioService(playerFactory: _SilentPlayer.new);
      await tester.runAsync(() async {
        await ProgressionRuntime.instance.initialize();
        await audio.initialize();
      });
      final capture = GlobalKey();
      await tester.pumpWidget(MaterialApp(home: RepaintBoundary(
        key: capture,
        child: UnifiedGameScreen.endless(audio: audio),
      )));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('BLOCKIVA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['BLOCKIVA_CAPTURE_UI'] == '1') {
        await tester.runAsync(() async {
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/mobile-review')..createSync(recursive: true);
          File('${directory.path}/game-${size.width.toInt()}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.widget<PieceTray>(find.byType(PieceTray)).enabled, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.widget<PieceTray>(find.byType(PieceTray)).enabled, isTrue);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Haptics'), findsOneWidget);
      expect(find.text('Sound'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('KEEP PLAYING'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(audio.dispose);
    });
  }
}
