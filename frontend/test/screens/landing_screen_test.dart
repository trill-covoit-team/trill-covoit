import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/providers/auth_provider.dart';
import 'package:trill_covoit/screens/landing_screen.dart';
import 'package:trill_covoit/services/api_client.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  AuthProvider createTestProvider() {
    final mockClient = MockClient((_) async => http.Response('{}', 200));
    final apiClient = ApiClient(client: mockClient, baseUrl: 'http://test.local');
    final service = AuthApiService(apiClient: apiClient);
    return AuthProvider(apiService: service);
  }

  Widget createTestWidget({
    VoidCallback? onStart,
    VoidCallback? onLogin,
    AuthProvider? provider,
  }) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: provider ?? createTestProvider(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: LandingScreen(
          onStart: onStart,
          onLogin: onLogin,
        ),
      ),
    );
  }

  testWidgets('LandingScreen affiche les éléments textuels et bénéfices', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('TRILL Covoit’'), findsOneWidget);
    expect(
      find.text('Le covoiturage universitaire simple, économique et sécurisé'),
      findsOneWidget,
    );
    expect(
      find.text('Réservé à la communauté étudiante et universitaire'),
      findsOneWidget,
    );
    expect(
      find.text('Partage équitable des frais sans commission'),
      findsOneWidget,
    );
    expect(
      find.text('Réduisez votre empreinte carbone au quotidien'),
      findsOneWidget,
    );
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.text("J'ai déjà un compte"), findsOneWidget);
  });

  testWidgets('Appuyer sur Commencer appelle onStart et réinitialise les messages', (tester) async {
    var startCalled = false;
    final provider = createTestProvider();
    provider.setPendingVerificationEmail('attente@univ.fr');

    await tester.pumpWidget(createTestWidget(
      onStart: () => startCalled = true,
      provider: provider,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('landing-start-button')));
    await tester.pumpAndSettle();

    expect(startCalled, isTrue);
    expect(provider.pendingVerificationEmail, isNull);
  });

  testWidgets('Appuyer sur J\'ai déjà un compte appelle onLogin et réinitialise les messages', (tester) async {
    var loginCalled = false;
    final provider = createTestProvider();
    provider.setPendingVerificationEmail('attente@univ.fr');

    await tester.pumpWidget(createTestWidget(
      onLogin: () => loginCalled = true,
      provider: provider,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('landing-login-button')));
    await tester.pumpAndSettle();

    expect(loginCalled, isTrue);
    expect(provider.pendingVerificationEmail, isNull);
  });

  for (final height in [640.0, 800.0]) {
    testWidgets(
      'Le tracé et le sprite de véhicule s’adaptent sans collision à 360 × $height',
      (tester) async {
        tester.view.physicalSize = Size(360, height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
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
              (paint) => paint.painter.runtimeType.toString() == '_RoutePainter',
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
