// Run on a physical Android device:
// flutter run --profile -t tool/performance_profile.dart
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:blockiva/main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final samples = <FrameTiming>[];
  SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> frames) {
    samples.addAll(frames);
    if (samples.length < 120) return;
    final batch = samples.take(120).toList(growable: false);
    samples.removeRange(0, 120);
    final build = batch.map((f) => f.buildDuration.inMicroseconds).toList()..sort();
    final raster = batch.map((f) => f.rasterDuration.inMicroseconds).toList()..sort();
    final refreshRate = WidgetsBinding.instance.platformDispatcher.views.first.display.refreshRate;
    final budget = 1000000 / (refreshRate > 0 ? refreshRate : 60);
    final overBudget = batch.where((f) =>
      f.buildDuration.inMicroseconds > budget ||
      f.rasterDuration.inMicroseconds > budget).length;
    debugPrint('BLOCKIVA_FRAME_SAMPLE n=120 '
      'refreshHz=$refreshRate budgetUs=${budget.round()} '
      'buildP95Us=${build[113]} rasterP95Us=${raster[113]} '
      'overBudget=$overBudget');
  });
  await app.main();
}
