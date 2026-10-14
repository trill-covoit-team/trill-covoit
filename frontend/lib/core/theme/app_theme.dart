import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFFF6F5F0);
  static const primary = Color(0xFF22252A);
  static const secondary = Color(0xFFEAE7DF);
  static const border = Color(0xFFC8C4BA);
  static const muted = Color(0xFF64615B);
  static const error = Color(0xFFB3261E);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: primary,
      surface: background,
      onSurface: primary,
      error: error,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );

    // Utiliser les polices système sans téléchargement externe.
    final serifFamily = defaultTargetPlatform == TargetPlatform.android
        ? 'serif'
        : 'Georgia';
    final textTheme = base.textTheme.apply(
      bodyColor: primary,
      displayColor: primary,
    );

    TextStyle displayStyle(TextStyle? style) => style!.copyWith(
      fontFamily: serifFamily,
      fontFamilyFallback: const ['Times New Roman', 'serif'],
      fontWeight: FontWeight.w700,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: border),
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: displayStyle(textTheme.displayLarge),
        displayMedium: displayStyle(textTheme.displayMedium),
        displaySmall: displayStyle(textTheme.displaySmall),
        headlineLarge: displayStyle(textTheme.headlineLarge),
        headlineMedium: displayStyle(textTheme.headlineMedium),
        headlineSmall: displayStyle(textTheme.headlineSmall),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: buttonShape,
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: muted),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return border;
          }
          return states.contains(WidgetState.selected) ? primary : null;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
    );
  }
}
