import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/constants/api_constants.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/main.dart';
import 'package:trill_covoit/features/auth/screens/landing_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  test('La configuration API respecte la valeur de compilation', () {
    const override = String.fromEnvironment('API_BASE_URL');
    final expected = override.isEmpty ? 'http://10.0.2.2:8080' : override;

    expect(ApiConstants.baseUrl, expected);
    expect(ApiConstants.requestTimeout, const Duration(seconds: 15));
  });

  testWidgets('Le thème respecte les tokens partagés', (tester) async {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, AppColors.bg);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.accent);
  });

  test('Les erreurs restent contrastées dans les deux thèmes', () {
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
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MainApp(),
      ),
    );

    expect(find.text('TRILL Covoit’'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text("J'ai déjà un compte"), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.bg);
    expect(tester.takeException(), isNull);
  });

  for (final height in [640.0, 800.0]) {
    testWidgets(
      'Le sprite suit le tracé sans recouvrir les pins à 360 × $height',
      (tester) async {
        tester.view.physicalSize = Size(360, height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: const LandingScreen()),
        );
        await tester.pumpAndSettle();
        final car = find.byKey(const ValueKey('welcome-car'));
        expect(tester.widget<SvgPicture>(car).width, 28);
        expect(tester.getSize(car), const Size(28, 50));
        final rotation = tester.widget<Transform>(
          find.byKey(const ValueKey('welcome-car-rotation')),
        );
        final paint = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .firstWhere(
              (paint) =>
                  paint.painter.runtimeType.toString() == '_RoutePainter',
            );
        final dynamic geometry = (paint.painter as dynamic).geometry;
        final marker = geometry.marker as Tangent;
        final angle = marker.angle + math.pi / 2;
        expect(rotation.transform.entry(0, 0), closeTo(math.cos(angle), .0001));
        expect(rotation.transform.entry(1, 0), closeTo(math.sin(angle), .0001));
        final metric = (geometry.route as Path).computeMetrics().first;
        expect(
          [.45, .50, .55, .40, .35].any(
            (fraction) =>
                (marker.position -
                        metric
                            .getTangentForOffset(metric.length * fraction)!
                            .position)
                    .distance <
                .001,
          ),
          isTrue,
        );
        final bounds = Rect.fromCenter(
          center: marker.position,
          width: 28 * math.cos(angle).abs() + 50 * math.sin(angle).abs(),
          height: 28 * math.sin(angle).abs() + 50 * math.cos(angle).abs(),
        );
        for (final Offset pin in geometry.pins) {
          expect(
            bounds.overlaps(
              Rect.fromLTRB(
                pin.dx - AppSpace.s12,
                pin.dy - AppSpace.s32,
                pin.dx + AppSpace.s12,
                pin.dy,
              ),
            ),
            isFalse,
          );
        }
        for (final dynamic label in geometry.labels) {
          expect(bounds.overlaps(label.bounds as Rect), isFalse);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
