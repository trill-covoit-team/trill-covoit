import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/widgets/loading_morph_button.dart';
import 'package:trill_covoit/widgets/motion_entrance.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Une entrée ne rejoue pas après reconstruction ou remontage', (
    tester,
  ) async {
    final timeline = EntranceTimeline();
    Widget page({bool show = true}) => MaterialApp(
      home: Scaffold(
        body: show
            ? MotionEntrance(
                timeline: timeline,
                index: 0,
                child: const Text('Bienvenue'),
              )
            : const SizedBox(),
      ),
    );
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(Animate));
    await tester.pumpWidget(page());
    expect(tester.state(find.byType(Animate)), same(state));
    await tester.pumpWidget(page(show: false));
    await tester.pumpWidget(page());
    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('Le mouvement réduit montre immédiatement les éléments', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: MotionEntrance(
              timeline: EntranceTimeline(),
              index: 5,
              child: LoadingMorphButton(
                label: 'Créer mon compte',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Animate), findsNothing);
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('loading-morph')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNotNull,
    );
  });

  testWidgets('Le bouton reprend toute sa largeur après une erreur', (
    tester,
  ) async {
    var loading = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) {
              rebuild = setState;
              return SizedBox(
                width: 320,
                child: LoadingMorphButton(
                  label: 'Se connecter',
                  isLoading: loading,
                  onPressed: () {},
                ),
              );
            },
          ),
        ),
      ),
    );
    final button = find.byType(FilledButton);
    final width = tester.getSize(button).width;
    rebuild(() => loading = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(button).width, tester.getSize(button).height);
    rebuild(() => loading = false);
    await tester.pumpAndSettle();
    expect(tester.getSize(button).width, width);
  });
}
