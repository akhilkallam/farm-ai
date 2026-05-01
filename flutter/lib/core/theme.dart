import 'package:flutter/material.dart';

class FarmAITheme {
  static const Color primaryGreen = Color(0xFF166534);
  static const Color lightGreen = Color(0xFFDCFCE7);
  static const Color accentAmber = Color(0xFFF59E0B);

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
          ),
        ),
      );
}
