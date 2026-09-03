import 'package:flutter/material.dart';

/// Premium Ethiopian-inspired palette for the tourist journey experience.
abstract final class EthioColors {
  static const cream = Color(0xFFFCFAF7);
  static const sand = Color(0xFFF5EFE6);
  static const stone = Color(0xFFA38C75);
  static const earth = Color(0xFF5E4534);
  static const forest = Color(0xFF144D3B);
  static const forestLight = Color(0xFF2E8A6E);
  static const terracotta = Color(0xFFD4693F);
  static const slate = Color(0xFF2E5F80);
  static const charcoal = Color(0xFF1F1C1A);
  static const muted = Color(0xFF827D75);
  static const divider = Color(0xFFEAE5DC);
  static const cardShadow = Color(0x0D1F1C1A);

  // Mapped modern hues for dynamic content tags & screens
  static const emergency = Color(0xFFC63E3D);
  static const recommendation = Color(0xFF7B529B);
  static const providerBlue = Color(0xFF2E5C8D);
  static const guideGreen = Color(0xFF1C7A54);
  static const adminGold = Color(0xFFC59B27);
}

ThemeData buildEthioTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: EthioColors.forest,
    onPrimary: Colors.white,
    primaryContainer: EthioColors.forest.withValues(alpha: 0.08),
    onPrimaryContainer: EthioColors.forest,
    secondary: EthioColors.terracotta,
    onSecondary: Colors.white,
    secondaryContainer: EthioColors.terracotta.withValues(alpha: 0.08),
    onSecondaryContainer: EthioColors.terracotta,
    tertiary: EthioColors.slate,
    onTertiary: Colors.white,
    tertiaryContainer: EthioColors.slate.withValues(alpha: 0.08),
    onTertiaryContainer: EthioColors.slate,
    surface: EthioColors.cream,
    onSurface: EthioColors.charcoal,
    error: EthioColors.emergency,
    onError: Colors.white,
    outline: EthioColors.divider,
    shadow: EthioColors.cardShadow,
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
        backgroundColor: EthioColors.forest,
        foregroundColor: Colors.white,
        disabledBackgroundColor: EthioColors.muted.withValues(alpha: 0.24),
        disabledForegroundColor: EthioColors.muted.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: EthioColors.forest,
        side: const BorderSide(color: EthioColors.forest, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EthioColors.forest,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.divider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.forest, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.emergency, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.emergency, width: 2),
      ),
      hintStyle: const TextStyle(color: EthioColors.muted, fontSize: 14),
      labelStyle: const TextStyle(color: EthioColors.muted, fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: EthioColors.sand,
      disabledColor: EthioColors.sand.withValues(alpha: 0.5),
      selectedColor: EthioColors.forest.withValues(alpha: 0.12),
      secondarySelectedColor: EthioColors.forest.withValues(alpha: 0.12),
      labelStyle: const TextStyle(color: EthioColors.charcoal, fontSize: 12, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: EthioColors.forest, fontSize: 12, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: BorderSide.none,
      checkmarkColor: EthioColors.forest,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: EthioColors.cardShadow,
      indicatorColor: EthioColors.forest.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final isSelected = states.contains(MaterialState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? EthioColors.forest : EthioColors.muted,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final isSelected = states.contains(MaterialState.selected);
        return IconThemeData(
          size: 24,
          color: isSelected ? EthioColors.forest : EthioColors.muted,
        );
      }),
    ),
  );
}

ThemeData buildEthioDarkTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: EthioColors.forestLight,
    onPrimary: Colors.white,
    primaryContainer: EthioColors.forest.withValues(alpha: 0.15),
    onPrimaryContainer: EthioColors.forestLight,
    secondary: EthioColors.terracotta,
    onSecondary: Colors.white,
    secondaryContainer: EthioColors.terracotta.withValues(alpha: 0.15),
    onSecondaryContainer: EthioColors.terracotta,
    tertiary: EthioColors.slate,
    onTertiary: Colors.white,
    tertiaryContainer: EthioColors.slate.withValues(alpha: 0.15),
    onTertiaryContainer: EthioColors.slate,
    surface: const Color(0xFF1A1A1A),
    onSurface: const Color(0xFFE0E0E0),
    error: EthioColors.emergency,
    onError: Colors.white,
    outline: const Color(0xFF3A3A3A),
    shadow: EthioColors.cardShadow,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Segoe UI',
  );

  final textTheme = baseTheme.textTheme.copyWith(
    headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFE0E0E0),
      letterSpacing: -0.6,
      height: 1.2,
    ),
    titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFE0E0E0),
      letterSpacing: -0.3,
    ),
    titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFE0E0E0),
    ),
    bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
      fontSize: 15,
      color: const Color(0xFFB0B0B0),
      height: 1.5,
    ),
    bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: const Color(0xFF909090),
      height: 1.45,
    ),
    labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: const Color(0xFF909090),
    ),
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      foregroundColor: const Color(0xFFE0E0E0),
      centerTitle: false,
      titleTextStyle: textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFE0E0E0),
        letterSpacing: -0.2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: EthioColors.forestLight,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF3A3A3A),
        disabledForegroundColor: const Color(0xFF606060),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: EthioColors.forestLight,
        side: const BorderSide(color: EthioColors.forestLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: EthioColors.forestLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: EthioColors.cardShadow,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.forestLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.emergency, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: EthioColors.emergency, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF606060), fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF606060), fontSize: 14),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      disabledColor: const Color(0xFF3A3A3A),
      selectedColor: EthioColors.forestLight.withValues(alpha: 0.2),
      secondarySelectedColor: EthioColors.forestLight.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 12, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: EthioColors.forestLight, fontSize: 12, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: BorderSide.none,
      checkmarkColor: EthioColors.forestLight,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 8,
      shadowColor: EthioColors.cardShadow,
      indicatorColor: EthioColors.forestLight.withValues(alpha: 0.15),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        final isSelected = states.contains(MaterialState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? EthioColors.forestLight : const Color(0xFF606060),
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final isSelected = states.contains(MaterialState.selected);
        return IconThemeData(
          size: 24,
          color: isSelected ? EthioColors.forestLight : const Color(0xFF606060),
        );
      }),
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
