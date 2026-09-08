import 'package:flutter/foundation.dart';

import '../../../core/storage/shared_preferences_progression_repository.dart';
import 'progression_controller.dart';

class ProgressionRuntime extends ChangeNotifier {
  ProgressionRuntime._()
      : controller = ProgressionController(
          repository: SharedPreferencesProgressionRepository(),
        ) {
    controller.addListener(_relay);
  }

  static final ProgressionRuntime instance = ProgressionRuntime._();

  final ProgressionController controller;
  bool _initializing = false;

  bool get initialized => controller.initialized;

  Future<void> initialize() async {
    if (controller.initialized || _initializing) return;
    _initializing = true;
    try {
      await controller.initialize();
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  void _relay() => notifyListeners();
}
