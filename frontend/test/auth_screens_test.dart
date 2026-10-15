import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
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
          : MaterialApp(theme: AppTheme.lightTheme, home: screen),
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
  await _tap(
    tester,
    find.text(isLogin ? "J'ai déjà un compte" : "Continuer avec l'email"),
  );
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
  testWidgets('Les entrées de l’accueil ouvrent le bon onglet', (tester) async {
    await _pumpApp(tester, (_) async => _message('Non utilisé'));
    await _openForm(tester);
    expect(find.text('Créez votre compte'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openForm(tester, isLogin: true);
    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  final invalidRegistrations = [
    ('email vide', '', 'Password123!', true, 'Veuillez saisir votre email.'),
    (
      'email invalide',
      'invalide',
      'Password123!',
      true,
      'Veuillez saisir un email valide.',
    ),
    (
      'mot de passe vide',
      'marie@exemple.fr',
      '',
      true,
      'Veuillez saisir votre mot de passe.',
    ),
    (
      'sept caractères',
      'marie@exemple.fr',
      '1234567',
      true,
      'Le mot de passe doit contenir au moins 8 caractères.',
    ),
    (
      'conditions refusées',
      'marie@exemple.fr',
      'Password123!',
      false,
      "Veuillez accepter les conditions d'utilisation.",
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
      if (terms) await _tap(tester, find.byType(CheckboxListTile));
      await _tap(tester, find.text("S'inscrire"));
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
    await _tap(tester, find.byType(CheckboxListTile));
    await _tap(tester, find.text("S'inscrire"));
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.text('marie@exemple.fr'), findsOneWidget);
    expect(jsonDecode(requests.first.body), {
      'email': 'marie@exemple.fr',
      'password': '12345678',
      'termsAccepted': true,
    });

    await tester.enterText(_codeField, '012345');
    await _tap(tester, find.text('Valider mon email'));
    expect(jsonDecode(requests[1].body), {
      'email': 'marie@exemple.fr',
      'code': '012345',
    });
    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.text('Email validé avec succès.'), findsOneWidget);
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
    await _tap(tester, find.text('Déconnexion'));
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
      (_) async => _message('Cet email est déjà utilisé.', 409),
    );
    await _openForm(tester);
    await _fillCredentials(tester);
    await _tap(tester, find.byType(CheckboxListTile));
    await _tap(tester, find.text("S'inscrire"));
    expect(find.text('Cet email est déjà utilisé.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Connexion'));
    expect(auth.errorMessage, isNull);
    expect(
      tester.widget<TextFormField>(_passwordField).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(_emailField).controller!.text,
      'marie@exemple.fr',
    );
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Inscription'));
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
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

  for (final isLogin in [false, true]) {
    testWidgets(
      'La ${isLogin ? 'connexion' : 'inscription'} permet une nouvelle tentative',
      (tester) async {
        var count = 0;
        await _pumpApp(tester, (_) async {
          count++;
          return count == 1
              ? _message('Demande refusée.', isLogin ? 401 : 409)
              : isLogin
              ? _session()
              : _message('Compte créé avec succès.', 201);
        });
        await _openForm(tester, isLogin: isLogin);
        await _fillCredentials(tester);
        if (!isLogin) await _tap(tester, find.byType(CheckboxListTile));
        final label = isLogin ? 'Se connecter' : "S'inscrire";
        await _tap(tester, find.text(label));
        expect(find.text('Demande refusée.'), findsOneWidget);
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
      return _message('Identifiants incorrects.', 401);
    });
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester, password: ' a ');
    await _tap(tester, find.text('Se connecter'));
    expect(jsonDecode(requests.single.body)['password'], ' a ');
    expect(find.text('Identifiants incorrects.'), findsOneWidget);
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

  testWidgets('Un email non validé propose le bon écran de validation', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      (_) async => _message('Veuillez valider votre email.', 403),
    );
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester, email: 'attente@exemple.fr');
    await _tap(tester, find.text('Se connecter'));
    expect(find.text('Veuillez valider votre email.'), findsOneWidget);
    await _tap(tester, find.text('Valider mon email'));
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
          : _message('Identifiants incorrects.', 401);
    });
    await _openForm(tester, isLogin: true);
    await _fillCredentials(tester);
    await _tap(tester, find.text('Se connecter'));
    expect(find.text('Valider mon email'), findsOneWidget);
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
    expect(tester.widget<TextFormField>(_codeField).controller!.text, '012345');
  });

  testWidgets('Un code refusé permet une nouvelle tentative', (tester) async {
    final codes = <String>[];
    await _pumpApp(tester, (request) async {
      codes.add(jsonDecode(request.body)['code'] as String);
      return codes.length == 1
          ? _message('Code invalide ou expiré.', 400)
          : _message('Email validé avec succès.');
    }, screen: const VerifyEmailScreen(email: 'marie@exemple.fr'));
    await tester.enterText(_codeField, '000000');
    await _tap(tester, find.text('Valider mon email'));
    expect(find.text('Code invalide ou expiré.'), findsOneWidget);
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    await tester.enterText(_codeField, '012345');
    await _tap(tester, find.text('Valider mon email'));
    expect(codes, ['000000', '012345']);
    expect(find.text('Email validé avec succès.'), findsOneWidget);
    expect(find.text('Bon retour'), findsOneWidget);
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
        if (!isLogin) await _tap(tester, find.byType(CheckboxListTile));
        final submit = find.widgetWithText(
          ElevatedButton,
          isLogin ? 'Se connecter' : "S'inscrire",
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
              .widget<OutlinedButton>(
                find.widgetWithText(
                  OutlinedButton,
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
    expect(tester.widget<TextFormField>(_codeField).enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(_message('Email validé avec succès.'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isFalse);
    expect(find.text('Bon retour'), findsOneWidget);
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
    expect(find.text('Déconnexion'), findsNothing);
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
        screen is VerifyEmailScreen ? 'Valider mon email' : "S'inscrire",
      );
      await _tap(tester, button);
      expect(tester.takeException(), isNull);
    });
  }
}
