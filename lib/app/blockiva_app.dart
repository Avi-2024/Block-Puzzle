import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/home_screen.dart';

class BlockivaApp extends StatelessWidget {
  const BlockivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blockiva',
      theme: AppTheme.bright,
      home: const HomeScreen(),
    );
  }
}
