import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class PawketColors {
  static const canvas = Color(0xFFF7F2E8);
  static const surface = Color(0xFFFFFDF8);
  static const surfaceStrong = Color(0xFFEEE5D6);
  static const ink = Color(0xFF1F2925);
  static const inkMuted = Color(0xFF66716C);
  static const brand = Color(0xFFC45132);
  static const brandPressed = Color(0xFF963A25);
  static const leaf = Color(0xFF2E6B57);
  static const sun = Color(0xFFD99A2B);
  static const danger = Color(0xFFB53B35);
  static const outline = Color(0xFFD7CCBC);
}

abstract final class PawketTheme {
  static ThemeData light() {
    final bodyTheme = GoogleFonts.atkinsonHyperlegibleTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: PawketColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: PawketColors.brand,
        onPrimary: Colors.white,
        secondary: PawketColors.leaf,
        onSecondary: Colors.white,
        surface: PawketColors.surface,
        onSurface: PawketColors.ink,
        error: PawketColors.danger,
        outline: PawketColors.outline,
      ),
      textTheme: bodyTheme.copyWith(
        displayLarge: GoogleFonts.fraunces(
          fontSize: 36,
          height: 40 / 36,
          fontWeight: FontWeight.w600,
          color: PawketColors.ink,
        ),
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 28,
          height: 32 / 28,
          fontWeight: FontWeight.w600,
          color: PawketColors.ink,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
          color: PawketColors.ink,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PawketColors.canvas,
        foregroundColor: PawketColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: PawketColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: PawketColors.outline),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: PawketColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PawketColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PawketColors.outline),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: PawketColors.surface,
        indicatorColor: PawketColors.surfaceStrong,
        height: 72,
      ),
    );
  }
}
