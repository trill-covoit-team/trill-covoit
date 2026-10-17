import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final primary = isDark ? AppColors.primaryOnDark : AppColors.primary;
    final onPrimary = isDark ? AppColors.onPrimaryDark : Colors.white;
    final bg = isDark ? AppColors.bgDark : AppColors.bg;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceAlt = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final text = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSub =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final scheme = ColorScheme(
      brightness: b,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceAlt,
      outline: border,
    );

    final base = GoogleFonts.plusJakartaSansTextTheme();
    TextStyle s(double size, FontWeight w, {double h = 1.3, Color? c}) =>
        GoogleFonts.plusJakartaSans(
            fontSize: size, fontWeight: w, height: h, color: c ?? text);

    final textTheme = base.copyWith(
      displayLarge: s(34, FontWeight.w800, h: 1.15),
      headlineMedium: s(26, FontWeight.w800, h: 1.2),
      titleLarge: s(20, FontWeight.w700),
      titleMedium: s(16, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, h: 1.45, c: textSub),
      labelLarge: s(15, FontWeight.w600),
      labelSmall: s(12, FontWeight.w600, c: textSub),
    );

    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md));
    const minSize = Size.fromHeight(kMinTouch + 4);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: minSize,
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: minSize,
          side: BorderSide(color: border),
          shape: shape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(kMinTouch, kMinTouch),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium,
        border: field(border),
        enabledBorder: field(border),
        focusedBorder: field(primary, 2),
        errorBorder: field(AppColors.error),
        focusedErrorBorder: field(AppColors.error, 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor:
            isDark ? AppColors.surfaceAltDark : AppColors.primarySoft,
        side: BorderSide.none,
        labelStyle: textTheme.labelSmall,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor:
            isDark ? AppColors.surfaceAltDark : AppColors.primarySoft,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1),
    );
  }
}