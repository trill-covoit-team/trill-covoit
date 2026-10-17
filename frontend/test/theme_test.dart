import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/main.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('Les tokens de couleurs et d’espacement sont cohérents', () {
    expect(AppColors.primary, const Color(0xFF0F766E));
    expect(AppColors.accent, const Color(0xFFF59E0B));
    expect(AppColors.bg, const Color(0xFFF6F8F9));
    expect(AppColors.surface, Colors.white);
    expect(AppColors.error, const Color(0xFFB42318));
    expect(AppColors.errorDark, const Color(0xFFFDA29B));

    expect(AppSpace.s4, 4.0);
    expect(AppSpace.s16, 16.0);
    expect(AppSpace.s24, 24.0);
    expect(AppRadius.sm, 8.0);
    expect(AppRadius.md, 14.0);
    expect(AppRadius.lg, 24.0);
  });

  testWidgets('Le thème respecte les tokens partagés', (tester) async {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, AppColors.bg);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.accent);
    expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w800);
  });

  test('Les erreurs restent contrastées dans les deux thèmes (WCAG AA)', () {
    double contrast(Color first, Color second) {
      final firstLuminance = first.computeLuminance();
      final secondLuminance = second.computeLuminance();
      return (math.max(firstLuminance, secondLuminance) + .05) /
          (math.min(firstLuminance, secondLuminance) + .05);
    }

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      expect(
        scheme.error,
        theme.brightness == Brightness.dark
            ? AppColors.errorDark
            : AppColors.error,
      );
      for (final surface in [
        scheme.surface,
        scheme.surfaceContainerHighest,
        theme.scaffoldBackgroundColor,
      ]) {
        expect(contrast(scheme.error, surface), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(scheme.onError, scheme.error), greaterThanOrEqualTo(4.5));
      final inputs = theme.inputDecorationTheme;
      expect(
        (inputs.errorBorder! as OutlineInputBorder).borderSide.color,
        scheme.error,
      );
      expect(
        (inputs.focusedErrorBorder! as OutlineInputBorder).borderSide.color,
        scheme.error,
      );
    }
  });

  testWidgets('L’application démarre avec le thème partagé', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('TRILL Covoit’'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.bg);
    expect(tester.takeException(), isNull);
  });
}
