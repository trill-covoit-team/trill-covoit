import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/widgets/auth_form_layout.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget createWidget({
    String title = 'Titre de test',
    Widget child = const Text('Contenu du formulaire'),
    bool isBusy = false,
    bool showTitle = true,
    Widget? footer,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: AuthFormLayout(
        title: title,
        isBusy: isBusy,
        showTitle: showTitle,
        footer: footer,
        onBack: onBack,
        child: child,
      ),
    );
  }

  testWidgets('Affiche le titre, le corps et le pied de page', (tester) async {
    await tester.pumpWidget(
      createWidget(
        title: 'Connexion',
        child: const Text('Champs du formulaire'),
        footer: const Text('Bouton d\'action'),
      ),
    );

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Champs du formulaire'), findsOneWidget);
    expect(find.text('Bouton d\'action'), findsOneWidget);
  });

  testWidgets('Masque le titre si showTitle est false', (tester) async {
    await tester.pumpWidget(
      createWidget(
        title: 'Titre masqué',
        showTitle: false,
      ),
    );

    expect(find.text('Titre masqué'), findsNothing);
  });

  testWidgets('Le bouton retour appelle onBack si isBusy est false', (tester) async {
    var backCalled = false;
    await tester.pumpWidget(
      createWidget(
        onBack: () => backCalled = true,
      ),
    );

    expect(find.byTooltip('Retour'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    expect(backCalled, isTrue);
  });

  testWidgets('Bloque le bouton retour et affiche l\'overlay si isBusy est true', (tester) async {
    await tester.pumpWidget(
      createWidget(
        isBusy: true,
        onBack: () {},
      ),
    );

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(iconButton.onPressed, isNull);

    // Vérifie la présence de l'overlay IgnorePointer
    expect(find.byKey(const ValueKey('busy-overlay')), findsOneWidget);
  });
}
