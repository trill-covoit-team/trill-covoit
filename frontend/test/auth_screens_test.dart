import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/home_screen.dart';
import 'package:trill_covoit/features/auth/screens/landing_screen.dart';
import 'package:trill_covoit/features/auth/screens/login_register_screen.dart';
import 'package:trill_covoit/features/auth/screens/verify_email_screen.dart';
import 'package:trill_covoit/features/auth/services/auth_api_service.dart';
import 'package:trill_covoit/main.dart';

final _emailField = find.byKey(const ValueKey('email'));
final _passwordField = find.byKey(const ValueKey('password'));
final _codeField = find.byKey(const ValueKey('verification-code'));

http.Response _message(String message, [int status = 200]) =>
    http.Response(jsonEncode({'message': message}), status);

http.Response _session() => http.Response(
  jsonEncode({
    'accessToken': 'test-token',
    'user': {'userId': 1, 'email': 'marie@exemple.fr', 'emailVerified': true},
  }),
  200,
);

Future<AuthProvider> _pumpApp(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) handler, {
  Widget? screen,
}) async {
  final client = MockClient(handler);
  final auth = AuthProvider(
    apiService: AuthApiService(client: client, baseUrl: 'http://test.local'),
  );
  addTearDown(auth.dispose);
  addTearDown(client.close);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: auth,
      child: screen == null
          ? const MainApp()
          : MaterialApp(theme: AppTheme.light, home: screen),
    ),
  );
  return auth;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester, {bool isLogin = false}) async {
  await _tap(tester, find.text(isLogin ? "J'ai déjà un compte" : 'Commencer'));
}

Future<void> _fillCredentials(
  WidgetTester tester, {
  String email = 'marie@exemple.fr',
  String password = 'Password123!',
}) async {
  await tester.enterText(_emailField, email);
  await tester.enterText(_passwordField, password);
  await tester.pump();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('Les entrées de l’accueil ouvrent le bon onglet', (tester) async {
    await _pumpApp(tester, (_) async => _message('Non utilisé'));
    await _openForm(tester);
    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openForm(tester, isLogin: true);
    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('Les actions restent en bas après défilement de l’accueil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpApp(tester, (_) async => _message('Non utilisé'));
    final button = find.widgetWithText(OutlinedButton, "J'ai déjà un compte");
    final before = tester.getRect(button);
    expect(before.bottom, lessThanOrEqualTo(640));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(button), before);
    expect(find.text("Jusqu'à 70 % moins cher qu'en solo"), findsOneWidget);
    expect(find.text('Des voisins qui font le même trajet'), findsOneWidget);
    expect(find.text('Moins de CO2 chaque jour'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final isLogin in [false, true]) {
    testWidgets('Le bouton auth reste au-dessus du clavier ($isLogin)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await _pumpApp(
        tester,
        (_) async => _message('Non utilisé'),
        screen: LoginRegisterScreen(initialLogin: isLogin),
      );
      final button = find.byType(FilledButton);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(360));
      expect(tester.getRect(button).top, greaterThanOrEqualTo(0));
      final email = tester.widget<TextField>(
        find.descendant(of: _emailField, matching: find.byType(TextField)),
      );
      final password = tester.widget<TextField>(
        find.descendant(of: _passwordField, matching: find.byType(TextField)),
      );
      expect(
        email.decoration!.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
      expect(
        password.decoration!.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
      expect(email.keyboardType, TextInputType.emailAddress);
      expect(email.textInputAction, TextInputAction.next);
      expect(password.textInputAction, TextInputAction.done);
      expect(tester.takeException(), isNull);
    });
  }

  final invalidRegistrations = [
    ('email vide', '', 'Password123!', true, 'Veuillez saisir votre email.'),
    (
      'email invalide',
      'invalide',
      'Password123!',
      true,
      'Adresse email invalide.',
    ),
    (
      'mot de passe vide',
      'marie@exemple.fr',
      '',
      true,
      'Le mot de passe doit contenir au moins 8 caractères.',
    ),
    (
      'sept caractères',
      'marie@exemple.fr',
      '1234567',
      true,
      'Le mot de passe doit contenir au moins 8 caractères.',
    ),
    (
      'mot de passe trop long',
      'marie@exemple.fr',
      'A' * 73,
      true,
      'Le mot de passe est trop long.',
    ),
    (
      'conditions refusées',
      'marie@exemple.fr',
      'Password123!',
      false,
      'Vous devez accepter les conditions pour continuer.',
    ),
  ];
  for (final (name, email, password, terms, error) in invalidRegistrations) {
    testWidgets('L’inscription refuse $name sans appel API', (tester) async {
      var count = 0;
      await _pumpApp(tester, (_) async {
        count++;
        return _message('Non utilisé');
      });
      await _openForm(tester);
      await _fillCredentials(tester, email: email, password: password);
      if (terms) await _tap(tester, find.byType(Checkbox));
      await _tap(tester, find.text('Créer mon compte'));
      expect(find.text(error), findsOneWidget);
      expect(count, 0);
    });
  }

  testWidgets('Le parcours inscription, validation, connexion et déconnexion', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final auth = await _pumpApp(tester, (request) async {
      requests.add(request);
      return switch (request.url.path) {
        '/auth/register' => _message('Compte créé avec succès.', 201),
        '/auth/verify-email' => _message('Email validé avec succès.'),
        '/auth/login' => _session(),
        _ => _message('Route inconnue', 404),
      };
    });
    await _openForm(tester);
    await _fillCredentials(
      tester,
      email: '  marie@exemple.fr  ',
      password: '12345678',
    );
    await _tap(tester, find.byType(Checkbox));
    await _tap(tester, find.text('Créer mon compte'));
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.text('marie@exemple.fr'), findsOneWidget);
    expect(jsonDecode(requests.first.body), {
      'email': 'marie@exemple.fr',
      'password': '12345678',
      'termsAccepted': true,
    });

    await tester.enterText(_codeField, '012345');
    await tester.pumpAndSettle();
    expect(find.text('Adresse email validée'), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await _tap(tester, find.text('Se connecter'));
    expect(jsonDecode(requests[1].body), {
      'email': 'marie@exemple.fr',
      'code': '012345',
    });
    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Adresse email validée'), findsOneWidget);
    expect(auth.pendingVerificationEmail, isNull);
    expect(auth.isAuthenticated, isFalse);
    expect(
      tester.widget<TextFormField>(_emailField).controller!.text,
      'marie@exemple.fr',
    );
    expect(
      tester.widget<TextFormField>(_passwordField).controller!.text,
      isEmpty,
    );

    await tester.enterText(_passwordField, '12345678');
    await _tap(tester, find.text('Se connecter'));
    expect(jsonDecode(requests[2].body), {
      'email': 'marie@exemple.fr',
      'password': '12345678',
    });
    expect(auth.isAuthenticated, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('marie@exemple.fr'), findsOneWidget);
    expect(find.byType(LoginRegisterScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
      isFalse,
    );
    await _tap(tester, find.text('Se déconnecter'));
    expect(auth.isAuthenticated, isFalse);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(LandingScreen))).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changer de mode efface mot de passe, conditions et erreurs', (
    tester,
  ) async {
    final auth = await _pumpApp(
      tester,
      (_) async => _message('Cette adresse email est déjà utilisée.', 409),
    );
    await _openForm(tester);
    await _fillCredentials(tester);
    await _tap(tester, find.byType(Checkbox));
    await _tap(tester, find.text('Créer mon compte'));
    expect(find.text('Cette adresse email est déjà utilisée.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(TextButton, 'Connexion'));
    expect(auth.errorMessage, isNull);
    expect(
      tester.widget<TextFormField>(_passwordField).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(_emailField).controller!.text,
      'marie@exemple.fr',
    );
    await _tap(tester, find.widgetWithText(TextButton, 'Inscription'));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('Le mot de passe peut être affiché et masqué', (tester) async {
    await _pumpApp(tester, (_) async => _message('Non utilisé'));
    await _openForm(tester);
    await _fillCredentials(tester);
    final input = find.descendant(
      of: _passwordField,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(input).obscureText, isTrue);
    await _tap(tester, find.byTooltip('Afficher le mot de passe'));
    expect(tester.widget<EditableText>(input).obscureText, isFalse);
    await _tap(tester, find.byTooltip('Masquer le mot de passe'));
    expect(tester.widget<EditableText>(input).obscureText, isTrue);
  });

  testWidgets(
    'Les textes légaux sont consultables sans accepter les conditions',
    (tester) async {
      await _pumpApp(tester, (_) async => _message('Non utilisé'));
      await _openForm(tester);
      for (final (link, title, content) in [
        (
          "conditions d'utilisation",
          "Conditions d'utilisation",
          'Version de démonstration',
        ),
        (
          'politique de confidentialité',
          'Politique de confidentialité',
          'Information sur le traitement des données personnelles',
        ),
      ]) {
        final richText = find.byKey(const ValueKey('terms-text'));
        await tester.ensureVisible(richText);
        final paragraph = tester.renderObject<RenderParagraph>(richText);
        final sentence = paragraph.text.toPlainText();
        final start = sentence.indexOf(link);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + link.length),
        );
        await tester.tapAt(
          paragraph.localToGlobal(boxes.first.toRect().center),
        );
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(find.textContaining(content), findsOneWidget);
        await _tap(tester, find.byTooltip('Fermer'));
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      }
    },
  );

  testWidgets('La robustesse reste indicative et le titre reste unique', (
    tester,
  ) async {
    await _pumpApp(tester, (_) async => _message('Non utilisé'));
    await _openForm(tester);
    expect(find.text('Bienvenue'), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).title, isNull);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('Robustesse :'), findsNothing);
    await tester.enterText(_passwordField, '1234567');
    await tester.pump();
    expect(find.text('Robustesse : Faible'), findsOneWidget);
    await tester.enterText(_passwordField, '12345678');
    await tester.pump();
    expect(find.text('Robustesse : Moyen'), findsOneWidget);
    await tester.enterText(_passwordField, 'MotDePasse1!');
    await tester.pump();
    expect(find.text('Robustesse : Robuste'), findsOneWidget);
    await tester.enterText(_passwordField, '');
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  for (final isLogin in [false, true]) {
    testWidgets(
      'La ${isLogin ? 'connexion' : 'inscription'} permet une nouvelle tentative',
      (tester) async {
        var count = 0;
        await _pumpApp(tester, (_) async {
          count++;
          return count == 1
              ? _message(
                  isLogin
                      ? "L'adresse email ou le mot de passe est incorrect."
                      : 'Cette adresse email est déjà utilisée.',
                  isLogin ? 401 : 409,
                )
              : isLogin
              ? _session()
              : _message('Compte créé avec succès.', 201);
        });
        await _openForm(tester, isLogin: isLogin);
        await _fillCredentials(tester);
        if (!isLogin) await _tap(tester, find.byType(Checkbox));
        final label = isLogin ? 'Se connecter' : 'Créer mon compte';
        await _tap(tester, find.text(label));
        expect(
          find.text(
            isLogin
                ? 'Identifiants invalides'
                : 'Cette adresse email est déjà utilisée.',
          ),
          findsOneWidget,
        );
        await _tap(tester, find.text(label));
        expect(count, 2);
        expect(
          isLogin ? find.byType(HomeScreen) : find.byType(VerifyEmailScreen),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('La connexion transmet un mot de passe court sans le modifier', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await _pumpApp(tester, (request) async {
      requests.add(request);
      return _message("L'adresse email ou le mot de passe est incorrect.", 401);
    });
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester, password: ' a ');
    await _tap(tester, find.text('Se connecter'));
    expect(jsonDecode(requests.single.body)['password'], ' a ');
    expect(find.text('Identifiants invalides'), findsOneWidget);
  });

  testWidgets('La connexion refuse un mot de passe vide sans appel API', (
    tester,
  ) async {
    var count = 0;
    await _pumpApp(tester, (_) async {
      count++;
      return _message('Non utilisé');
    });
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester, password: '');
    await _tap(tester, find.text('Se connecter'));
    expect(find.text('Veuillez saisir votre mot de passe.'), findsOneWidget);
    expect(count, 0);
  });

  testWidgets('Un email non validé ouvre automatiquement la validation', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      (_) async => _message('Veuillez valider votre email.', 403),
    );
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester, email: 'attente@exemple.fr');
    await _tap(tester, find.text('Se connecter'));
    expect(
      find.text("Validez votre adresse email pour accéder à l'application."),
      findsOneWidget,
    );
    expect(
      tester.widget<VerifyEmailScreen>(find.byType(VerifyEmailScreen)).email,
      'attente@exemple.fr',
    );
    expect(find.byType(LoginRegisterScreen), findsNothing);
  });

  testWidgets('Une autre erreur ne réutilise pas un ancien email en attente', (
    tester,
  ) async {
    var count = 0;
    final auth = await _pumpApp(tester, (_) async {
      count++;
      return count == 1
          ? _message('Veuillez valider votre email.', 403)
          : _message("L'adresse email ou le mot de passe est incorrect.", 401);
    });
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester);
    await _tap(tester, find.text('Se connecter'));
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await _tap(tester, find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await _fillCredentials(tester);
    await _tap(tester, find.text('Se connecter'));
    expect(auth.pendingVerificationEmail, isNull);
    expect(find.text('Valider mon email'), findsNothing);
    expect(find.byType(VerifyEmailScreen), findsNothing);
  });

  testWidgets('Changer l’email efface l’invitation de validation précédente', (
    tester,
  ) async {
    final auth = await _pumpApp(
      tester,
      (_) async => _message('Veuillez valider votre email.', 403),
    );
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester);
    await _tap(tester, find.text('Se connecter'));
    await _tap(tester, find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await tester.enterText(_emailField, 'autre@exemple.fr');
    await tester.pumpAndSettle();
    expect(auth.pendingVerificationEmail, isNull);
    expect(find.text('Valider mon email'), findsNothing);
    expect(auth.errorMessage, isNull);
  });

  testWidgets('Un code incomplet ne déclenche pas de vérification', (
    tester,
  ) async {
    var count = 0;
    await _pumpApp(tester, (_) async {
      count++;
      return _message('Non utilisé');
    }, screen: const VerifyEmailScreen(email: 'marie@exemple.fr'));
    await tester.enterText(_codeField, '12345');
    await _tap(tester, find.text('Valider mon email'));
    expect(
      find.text('Veuillez saisir les 6 chiffres du code.'),
      findsOneWidget,
    );
    expect(count, 0);
  });

  testWidgets('Le code collé est filtré et limité à six chiffres', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      (_) async => _message('Non utilisé'),
      screen: const VerifyEmailScreen(email: 'marie@exemple.fr'),
    );
    await tester.enterText(_codeField, 'ab01 23-4567');
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .map((field) => field.controller!.text)
          .join(),
      '012345',
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Six chiffres avancent le focus et déclenchent un seul envoi', (
    tester,
  ) async {
    var count = 0;
    final auth = await _pumpApp(tester, (_) async {
      count++;
      return _message('Le code de validation est invalide ou expiré.', 400);
    }, screen: const VerifyEmailScreen(email: 'marie@exemple.fr'));
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(6));
    for (var i = 0; i < 6; i++) {
      final field = i == 0
          ? _codeField
          : find.byKey(ValueKey('verification-digit-$i'));
      final box = tester.getSize(field);
      expect(box.width, greaterThanOrEqualTo(48));
      expect(box.height, greaterThanOrEqualTo(48));
      expect(fields[i].autofillHints, contains(AutofillHints.oneTimeCode));
      await tester.enterText(field, '$i');
      await tester.pump();
      if (i < 5) expect(fields[i + 1].focusNode!.hasFocus, isTrue);
      expect(count, i < 5 ? 0 : 1);
    }
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isFalse);
    expect(find.text('Code invalide. Réessayez.'), findsOneWidget);
    for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
      expect(field.controller!.text, isEmpty);
      expect(
        (field.decoration!.enabledBorder! as OutlineInputBorder)
            .borderSide
            .color,
        Theme.of(tester.element(_codeField)).colorScheme.error,
      );
    }
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'Le code refusé est effacé après le retour visuel ($reducedMotion)',
      (tester) async {
        final response = Completer<http.Response>();
        final codes = <String>[];
        await _pumpApp(
          tester,
          (request) {
            codes.add(jsonDecode(request.body)['code'] as String);
            return codes.length == 1
                ? response.future
                : Future.value(_message('Email validé avec succès.'));
          },
          screen: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: const VerifyEmailScreen(email: 'marie@exemple.fr'),
          ),
        );
        await tester.enterText(_codeField, '000000');
        await tester.pump();
        response.complete(
          _message('Le code de validation est invalide ou expiré.', 400),
        );
        await tester.pump();
        final fields = tester
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        final submit = find.byType(FilledButton);
        expect(find.text('Code invalide. Réessayez.'), findsOneWidget);
        if (!reducedMotion) {
          expect(
            fields.map((field) => field.controller!.text).join(),
            '000000',
          );
          expect(fields.every((field) => field.enabled == false), isTrue);
          expect(tester.widget<FilledButton>(submit).onPressed, isNull);
          await tester.pump(const Duration(milliseconds: 199));
          expect(
            fields.map((field) => field.controller!.text).join(),
            '000000',
          );
          expect(codes, ['000000']);
          await tester.pump(const Duration(milliseconds: 1));
        } else {
          expect(
            fields.every((field) => field.controller!.text.isEmpty),
            isTrue,
          );
        }
        await tester.pumpAndSettle();
        expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
        expect(fields.first.focusNode!.hasFocus, isTrue);
        expect(tester.widget<TextField>(_codeField).enabled, isTrue);
        expect(find.text('Code invalide. Réessayez.'), findsOneWidget);
        for (var i = 0; i < 6; i++) {
          await tester.enterText(
            i == 0 ? _codeField : find.byKey(ValueKey('verification-digit-$i')),
            '$i',
          );
          await tester.pump();
          if (i < 5) {
            expect(codes, ['000000']);
            expect(find.text('Code invalide. Réessayez.'), findsNothing);
          }
        }
        await tester.pumpAndSettle();
        expect(codes, ['000000', '012345']);
        expect(find.text('Adresse email validée'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Quitter pendant le shake ne provoque pas de rappel après dispose',
    (tester) async {
      final response = Completer<http.Response>();
      await _pumpApp(
        tester,
        (_) => response.future,
        screen: const VerifyEmailScreen(email: 'marie@exemple.fr'),
      );
      await tester.enterText(_codeField, '000000');
      await tester.pump();
      response.complete(
        _message('Le code de validation est invalide ou expiré.', 400),
      );
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Aucun faux renvoi ni appel supplémentaire sans API de renvoi', (
    tester,
  ) async {
    var count = 0;
    await _pumpApp(tester, (_) async {
      count++;
      return _message('Non utilisé');
    }, screen: const VerifyEmailScreen(email: 'marie@exemple.fr'));
    final resend = find.widgetWithText(TextButton, 'Renvoyer le code');
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    await tester.pump(const Duration(seconds: 31));
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    expect(find.text('Un nouveau code a été envoyé.'), findsNothing);
    expect(count, 0);
  });

  for (final verification in [false, true]) {
    for (final network in [false, true]) {
      testWidgets('Erreur ${network ? "réseau" : "serveur"} ($verification)', (
        tester,
      ) async {
        var count = 0;
        await _pumpApp(
          tester,
          (_) async {
            count++;
            if (network) throw const SocketException('Hors ligne');
            return _message('Détail technique confidentiel', 500);
          },
          screen: verification
              ? const VerifyEmailScreen(email: 'marie@exemple.fr')
              : const LoginRegisterScreen(initialLogin: true),
        );
        if (verification) {
          await tester.enterText(_codeField, '012345');
          await tester.pumpAndSettle();
        } else {
          await _fillCredentials(tester);
          await _tap(tester, find.text('Se connecter'));
        }
        expect(
          find.text(
            network
                ? 'Connexion impossible. Vérifiez votre réseau.'
                : 'Une erreur est survenue. Réessayez plus tard.',
          ),
          findsOneWidget,
        );
        expect(find.text('Détail technique confidentiel'), findsNothing);
        if (verification) {
          expect(
            tester
                .widgetList<TextField>(find.byType(TextField))
                .map((field) => field.controller!.text)
                .join(),
            '012345',
          );
        }
        await _tap(
          tester,
          find.text(verification ? 'Valider mon email' : 'Se connecter'),
        );
        expect(count, 2);
      });
    }
  }

  testWidgets(
    'Le retour système de vérification ouvre Auth avec le bon email',
    (tester) async {
      await _pumpApp(
        tester,
        (_) async => _message('Non utilisé'),
        screen: const VerifyEmailScreen(email: 'retour@exemple.fr'),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LoginRegisterScreen), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_emailField).controller!.text,
        'retour@exemple.fr',
      );
      expect(find.byType(Checkbox), findsNothing);
    },
  );

  testWidgets('Un code refusé permet une nouvelle tentative', (tester) async {
    final codes = <String>[];
    await _pumpApp(tester, (request) async {
      codes.add(jsonDecode(request.body)['code'] as String);
      return codes.length == 1
          ? _message('Code invalide ou expiré.', 400)
          : _message('Email validé avec succès.');
    }, screen: const VerifyEmailScreen(email: 'marie@exemple.fr'));
    await tester.enterText(_codeField, '000000');
    await tester.pumpAndSettle();
    expect(find.text('Code invalide. Réessayez.'), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await tester.enterText(_codeField, '012345');
    await tester.pumpAndSettle();
    expect(codes, ['000000', '012345']);
    expect(find.text('Adresse email validée'), findsOneWidget);
    await _tap(tester, find.text('Se connecter'));
    expect(find.text('Bienvenue'), findsOneWidget);
  });

  for (final isLogin in [false, true]) {
    testWidgets(
      'La ${isLogin ? 'connexion' : 'inscription'} bloque les doubles envois',
      (tester) async {
        final response = Completer<http.Response>();
        var count = 0;
        final auth = await _pumpApp(tester, (_) {
          count++;
          return response.future;
        });
        await _openForm(tester, isLogin: isLogin);
        await _fillCredentials(tester);
        if (!isLogin) await _tap(tester, find.byType(Checkbox));
        final submit = find.widgetWithText(
          FilledButton,
          isLogin ? 'Se connecter' : 'Créer mon compte',
        );
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.tap(submit);
        await tester.pump();
        expect(count, 1);
        expect(auth.isLoading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.widget<TextFormField>(_emailField).enabled, isFalse);
        expect(tester.widget<TextFormField>(_passwordField).enabled, isFalse);
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(
                  TextButton,
                  isLogin ? 'Inscription' : 'Connexion',
                ),
              )
              .onPressed,
          isNull,
        );
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(find.byType(LoginRegisterScreen), findsOneWidget);
        response.complete(
          isLogin ? _session() : _message('Compte créé avec succès.', 201),
        );
        await tester.pumpAndSettle();
        expect(auth.isLoading, isFalse);
        expect(
          isLogin ? find.byType(HomeScreen) : find.byType(VerifyEmailScreen),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('La vérification bloque les doubles envois', (tester) async {
    final response = Completer<http.Response>();
    var count = 0;
    final auth = await _pumpApp(tester, (_) {
      count++;
      return response.future;
    }, screen: const VerifyEmailScreen(email: 'marie@exemple.fr'));
    await tester.enterText(_codeField, '012345');
    final submit = find.text('Valider mon email');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(count, 1);
    expect(auth.isLoading, isTrue);
    expect(tester.widget<TextField>(_codeField).enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(_message('Email validé avec succès.'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isFalse);
    expect(find.text('Adresse email validée'), findsOneWidget);
  });

  testWidgets('La porte d’entrée réagit à une session modifiée hors écran', (
    tester,
  ) async {
    final auth = await _pumpApp(tester, (_) async => _session());
    await _openForm(tester);
    await auth.login(email: 'marie@exemple.fr', password: 'Password123!');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginRegisterScreen), findsNothing);
    auth.logout();
    await tester.pumpAndSettle();
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(LandingScreen))).canPop(),
      isFalse,
    );
  });

  testWidgets('Sans session, l’accueil protégé ne montre aucune donnée', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      (_) async => _message('Non utilisé'),
      screen: const HomeScreen(),
    );
    expect(find.byType(LandingScreen), findsOneWidget);
    expect(find.text('Se déconnecter'), findsNothing);
  });

  for (final screen in [
    const LoginRegisterScreen(),
    const VerifyEmailScreen(email: 'marie@exemple.fr'),
  ]) {
    testWidgets('${screen.runtimeType} reste utilisable avec le clavier', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpApp(
        tester,
        (_) async => _message('Non utilisé'),
        screen: screen,
      );
      final button = find.text(
        screen is VerifyEmailScreen ? 'Valider mon email' : 'Créer mon compte',
      );
      await _tap(tester, button);
      expect(tester.takeException(), isNull);
    });
  }
}
