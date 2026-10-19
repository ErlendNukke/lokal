import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light theme matched to the app icon: white surfaces, near-black text and
/// wordmark, icon orange-red as the main colour.
class LokalColors {
  static const primary = Color(0xFFD9381E); // icon orange-red, white text 4.6:1
  static const primaryText = Color(
    0xFFB8301A,
  ); // primary as text on light bg, 5.5:1
  static const onPrimary = Color(0xFFFFFFFF); // text on primary
  static const heading = Color(0xFF121212); // headings / prices
  static const primarySoft = Color(0xFFE0633F);
  static const blue = Color(0xFF1F5FE0); // icon blue (user location)
  static const accent = Color(0xFFD9381E); // map markers
  static const accentBright = Color(0xFFF07A10); // decorative only
  static const surfaceSoft = Color(0xFFF1EFEC);
  static const placeholder = Color(0xFFE7E4DF); // image placeholders
  static const background = Color(0xFFF7F6F4); // page background
  static const card = Color(0xFFFFFFFF);
  static const field = Color(0xFFFFFFFF);
  static const chipBg = Color(0xFFFFFFFF);
  static const nav = Color(0xFFFFFFFF);
  static const banner = Color(0xFF121212); // snackbar / install banner
  static const ink = Color(0xFF121212);
  static const muted = Color(0xFF5E5E66);
  static const border = Color(0xFFE2DFDA);
  static const danger = Color(0xFFC0362C);
  static const warning = accent;
  /// Text and icons on [banner] surfaces (snackbar, install prompt).
  static const onBanner = Color(0xFFFFFFFF);
  static final shadow = const Color(0xFF000000).withValues(alpha: 0.06);
}

ColorScheme _lokalColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: LokalColors.primary,
    primary: LokalColors.primary,
    onPrimary: LokalColors.onPrimary,
    secondary: LokalColors.accent,
    onSecondary: LokalColors.onPrimary,
    tertiary: LokalColors.blue,
    onTertiary: LokalColors.onPrimary,
    surface: LokalColors.background,
    onSurface: LokalColors.ink,
    onSurfaceVariant: LokalColors.muted,
    error: LokalColors.danger,
    onError: LokalColors.onPrimary,
    outline: LokalColors.border,
    brightness: Brightness.light,
  ).copyWith(
    surfaceContainerLowest: LokalColors.background,
    surfaceContainerLow: LokalColors.surfaceSoft,
    surfaceContainer: LokalColors.card,
    surfaceContainerHigh: LokalColors.card,
    surfaceContainerHighest: LokalColors.surfaceSoft,
  );
}

ThemeData buildLokalTheme() {
  final scheme = _lokalColorScheme();
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LokalColors.background,
  );

  return base.copyWith(
    textTheme: GoogleFonts.sourceSans3TextTheme(
      base.textTheme,
    ).apply(bodyColor: LokalColors.ink, displayColor: LokalColors.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: LokalColors.background.withValues(alpha: 0.94),
      foregroundColor: LokalColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: LokalColors.heading,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: LokalColors.primary,
      backgroundColor: LokalColors.chipBg,
      disabledColor: LokalColors.surfaceSoft,
      side: const BorderSide(color: LokalColors.border),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: LokalColors.ink,
      ),
      secondaryLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: LokalColors.onPrimary,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LokalColors.primary,
        foregroundColor: LokalColors.onPrimary,
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
      fillColor: LokalColors.field,
      labelStyle: const TextStyle(color: LokalColors.muted),
      hintStyle: const TextStyle(color: LokalColors.muted),
      prefixIconColor: LokalColors.muted,
      suffixIconColor: LokalColors.muted,
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
        borderSide: const BorderSide(color: LokalColors.primary, width: 1.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: LokalColors.primaryText),
    ),
    iconTheme: const IconThemeData(color: LokalColors.ink),
    dividerColor: LokalColors.border,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LokalColors.primary,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? LokalColors.primary : null,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: LokalColors.banner,
      contentTextStyle: TextStyle(color: LokalColors.onBanner),
      actionTextColor: LokalColors.primarySoft,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LokalColors.card,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: brandTitle(size: 20),
      contentTextStyle: const TextStyle(color: LokalColors.ink, height: 1.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LokalColors.border),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LokalColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(color: LokalColors.ink),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(LokalColors.card),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(
          const BorderSide(color: LokalColors.border),
        ),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(LokalColors.card),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(
          const BorderSide(color: LokalColors.border),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: LokalColors.card,
      surfaceTintColor: Colors.transparent,
      textStyle: const TextStyle(color: LokalColors.ink),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: LokalColors.border),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LokalColors.primary;
          }
          return LokalColors.chipBg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LokalColors.onPrimary;
          }
          return LokalColors.ink;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: LokalColors.border),
        ),
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LokalColors.nav,
      selectedItemColor: LokalColors.primary,
      unselectedItemColor: LokalColors.muted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      // Keep slightly translucent: a fully opaque Card hides the HTML <img>
      // product photos (web platform views) on WebKit, e.g. in Tellimused.
      color: LokalColors.card.withValues(alpha: 0.9),
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
  color: LokalColors.heading,
  letterSpacing: -0.4,
);
