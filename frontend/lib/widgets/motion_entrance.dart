import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trill_covoit/core/theme/tokens.dart';

/// Mémoire des entrées de présentation pendant toute la visite.
class EntranceTimeline {
  final Set<int> _started = {};
  bool complete = false;
  bool claim(int index) => !complete && _started.add(index);
}

class MotionEntrance extends StatefulWidget {
  const MotionEntrance({
    super.key,
    required this.timeline,
    required this.index,
    required this.child,
    this.start = Duration.zero,
  });

  final EntranceTimeline timeline;
  final int index;
  final Duration start;
  final Widget child;

  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance> {
  late final bool _play = widget.timeline.claim(widget.index);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) || !_play) return widget.child;
    final delay = widget.start + AppMotion.stagger * widget.index;
    // Les éléments remontés après un changement d'onglet restent visibles.
    return widget.child
        .animate(onComplete: (_) => widget.timeline.complete = true)
        .fadeIn(
          delay: delay,
          duration: AppMotion.normal,
          curve: AppMotion.curve,
        )
        .moveY(
          delay: delay,
          begin: AppSpace.s12,
          end: 0,
          duration: AppMotion.normal,
          curve: AppMotion.curve,
        );
  }
}
