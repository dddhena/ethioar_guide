import 'package:flutter/material.dart';

/// Premium Ethiopian-inspired palette for the tourist journey experience.
abstract final class EthioColors {
  static const cream = Color(0xFFFAF8F5);
  static const sand = Color(0xFFF3EDE4);
  static const stone = Color(0xFF8B7355);
  static const earth = Color(0xFF6B5344);
  static const forest = Color(0xFF2D5A3D);
  static const forestLight = Color(0xFF3D7A52);
  static const terracotta = Color(0xFFC4784A);
  static const slate = Color(0xFF3D6B8E);
  static const charcoal = Color(0xFF2C2825);
  static const muted = Color(0xFF7A736B);
  static const divider = Color(0xFFE8E2D9);
  static const cardShadow = Color(0x1A2C2825);
}

ThemeData buildEthioTheme() {
  const seed = EthioColors.forest;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: EthioColors.cream,
    onSurface: EthioColors.charcoal,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: EthioColors.cream,
    fontFamily: 'Segoe UI',
  );

  final textTheme = baseTheme.textTheme.copyWith(
    headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: EthioColors.charcoal,
      letterSpacing: -0.6,
      height: 1.2,
    ),
    titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: EthioColors.charcoal,
      letterSpacing: -0.3,
    ),
    titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: EthioColors.charcoal,
    ),
    bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
      fontSize: 15,
      color: EthioColors.charcoal,
      height: 1.5,
    ),
    bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: EthioColors.muted,
      height: 1.45,
    ),
    labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: EthioColors.muted,
    ),
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: EthioColors.cream,
      foregroundColor: EthioColors.charcoal,
      centerTitle: false,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: EthioColors.charcoal,
        letterSpacing: -0.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          inherit: false,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EthioColors.muted,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, inherit: false),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: EthioColors.cardShadow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EthioColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EthioColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EthioColors.forest, width: 1.5),
      ),
      hintStyle: const TextStyle(color: EthioColors.muted, fontSize: 14),
    ),
  );
}

BoxDecoration ethioGlassCard({Color? tint, double radius = 20}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: Colors.white.withValues(alpha: 0.92),
    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
    boxShadow: [
      BoxShadow(
        color: EthioColors.cardShadow,
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: (tint ?? EthioColors.forest).withValues(alpha: 0.04),
        blurRadius: 40,
        offset: const Offset(0, 16),
      ),
    ],
  );
}
