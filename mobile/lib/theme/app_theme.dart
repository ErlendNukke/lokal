import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LokalColors {
  // Sampled from the app icon (low-poly pin on a green-to-blue background),
  // darkened where needed so text stays WCAG AA on light surfaces.
  static const forest = Color(0xFF0A6E62); // primary deep teal (white text 6.1:1)
  static const forestDark = Color(0xFF064A44); // headings (9.6:1 on surface)
  static const forestSoft = Color(0xFF1F8F80);
  static const ocean = Color(0xFF0B5FA0); // icon background blue, gradient end
  static const accent = Color(0xFFC2510A); // pin orange, AA with white text
  static const accentBright = Color(0xFFDE600B); // decorative only
  static const beige = Color(0xFFE6F0EE);
  static const beigeDeep = Color(0xFFD2E4E0);
  static const cream = Color(0xFFF5F9F8);
  static const ink = Color(0xFF1E2A28);
  static const muted = Color(0xFF5F6B69);
  static const border = Color(0xFFD3E2DF);
  static const danger = Color(0xFFB44A3C);
  static const warning = accent;

  static const brandGradient = LinearGradient(
    colors: [forest, ocean],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildLokalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LokalColors.forest,
      primary: LokalColors.forest,
      secondary: LokalColors.accent,
      onSecondary: Colors.white,
      tertiary: LokalColors.ocean,
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
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: LokalColors.forest),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: LokalColors.forest),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? LokalColors.forest : null,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LokalColors.forestDark,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Color(0xFFFFB98A),
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
