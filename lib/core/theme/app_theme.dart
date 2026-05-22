import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const seed = Color(0xFF7C4DFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );
  }
}
