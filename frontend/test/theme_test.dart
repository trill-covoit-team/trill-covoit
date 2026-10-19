import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/main.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Le thème respecte les tokens partagés', (tester) async {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, AppColors.bg);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.accent);
    expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w800);
  });

  test('Les erreurs restent contrastées dans les deux thèmes (WCAG AA)', () {
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

  test('Les petits textes restent lisibles en mode sombre', () {
    final theme = AppTheme.dark;
    final styles = {
      'bodySmall': theme.textTheme.bodySmall!,
      'titleSmall': theme.textTheme.titleSmall!,
      'labelMedium': theme.textTheme.labelMedium!,
    };
    final backgrounds = {
      'surface': theme.colorScheme.surface,
      'surfaceContainerHighest': theme.colorScheme.surfaceContainerHighest,
      'scaffold': theme.scaffoldBackgroundColor,
    };

    for (final style in styles.entries) {
      for (final background in backgrounds.entries) {
        expect(
          contrast(style.value.color!, background.value),
          greaterThanOrEqualTo(4.5),
          reason: '${style.key} doit rester lisible sur ${background.key}.',
        );
      }
    }
  });

  testWidgets(
    "L'icône de navigation sélectionnée reste visible en mode sombre",
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            bottomNavigationBar: NavigationBar(
              selectedIndex: 1,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconContext = tester.element(find.byIcon(Icons.person));
      final iconColor = IconTheme.of(iconContext).color!;
      final indicator = tester.widget<NavigationIndicator>(
        find.descendant(
          of: find.widgetWithText(NavigationDestination, 'Profil'),
          matching: find.byType(NavigationIndicator),
        ),
      );

      expect(
        contrast(iconColor, indicator.color!),
        greaterThanOrEqualTo(3),
        reason: "L'icône sélectionnée doit contraster avec son indicateur.",
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Les boutons peuvent être placés côte à côte sans erreur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              FilledButton(onPressed: () {}, child: const Text('Valider')),
              OutlinedButton(onPressed: () {}, child: const Text('Annuler')),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).width, greaterThan(0));
    expect(tester.getSize(find.byType(OutlinedButton)).width, greaterThan(0));
  });

  testWidgets("L'application démarre avec le thème partagé", (tester) async {
    await tester.pumpWidget(const MainApp());

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.bg);
    expect(tester.takeException(), isNull);
  });
}

double contrast(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  return (math.max(firstLuminance, secondLuminance) + .05) /
      (math.min(firstLuminance, secondLuminance) + .05);
}
