import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LokalColors {
  static const forest = Color(0xFF2F5D50);
  static const forestDark = Color(0xFF1F3F36);
  static const forestSoft = Color(0xFF3F7A68);
  static const beige = Color(0xFFF3EBE0);
  static const beigeDeep = Color(0xFFE6D8C6);
  static const cream = Color(0xFFFAF7F2);
  static const ink = Color(0xFF2A2A2A);
  static const muted = Color(0xFF6B6B6B);
  static const border = Color(0xFFE2D6C6);
  static const danger = Color(0xFFB44A3C);
  static const warning = Color(0xFFC47B2D);
}

ThemeData buildLokalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LokalColors.forest,
      primary: LokalColors.forest,
      secondary: LokalColors.warning,
      surface: LokalColors.cream,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: LokalColors.cream,
  );

  return base.copyWith(
    textTheme: GoogleFonts.sourceSans3TextTheme(base.textTheme).apply(
      bodyColor: LokalColors.ink,
      displayColor: LokalColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: LokalColors.cream.withValues(alpha: 0.94),
      foregroundColor: LokalColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: LokalColors.forestDark,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: LokalColors.forest,
      backgroundColor: Colors.white.withValues(alpha: 0.75),
      side: const BorderSide(color: LokalColors.border),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LokalColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LokalColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: LokalColors.border),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.85),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LokalColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LokalColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LokalColors.forest, width: 1.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: LokalColors.forest,
      unselectedItemColor: LokalColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LokalColors.border),
      ),
    ),
  );
}

TextStyle brandTitle({double size = 32}) => GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: LokalColors.forestDark,
      letterSpacing: -0.4,
    );
