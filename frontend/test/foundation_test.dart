import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trill_covoit/core/constants/api_constants.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/main.dart';

void main() {
  test('La configuration API respecte la valeur de compilation', () {
    const override = String.fromEnvironment('API_BASE_URL');
    final expected = override.isEmpty
        ? 'http://10.0.2.2:8080/api'
        : override;

    expect(ApiConstants.baseUrl, expected);
    expect(ApiConstants.requestTimeout, const Duration(seconds: 15));
  });

  test('Le thème respecte les couleurs de la maquette', () {
    final theme = AppTheme.lightTheme;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F5F0));
    expect(theme.colorScheme.primary, const Color(0xFF22252A));
    expect(theme.colorScheme.secondary, const Color(0xFFEAE7DF));
    expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w700);
  });

  testWidgets('L’application démarre avec le thème partagé', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('TRILL Covoit’'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppTheme.background);
    expect(tester.takeException(), isNull);
  });
}
