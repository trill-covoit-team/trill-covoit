import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/widgets/motion_entrance.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Une entrée ne rejoue pas après reconstruction ou remontage', (tester) async {
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

  testWidgets('Le mouvement réduit affiche directement le widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: MotionEntrance(
              timeline: EntranceTimeline(),
              index: 5,
              child: const Text('Entrée immédiate'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Animate), findsNothing);
    expect(find.text('Entrée immédiate'), findsOneWidget);
  });
}
