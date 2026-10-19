import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trill_covoit/core/theme/tokens.dart';

/// Retour visuel uniquement ; la validation reste dans le formulaire.
class MotionField extends StatefulWidget {
  const MotionField({
    super.key,
    required this.focusNode,
    required this.error,
    required this.attempt,
    required this.child,
    this.radius = AppRadius.md,
    this.animateShake = true,
  });

  final FocusNode focusNode;
  final bool error;
  final int attempt;
  final Widget child;
  final double radius;
  final bool animateShake;

  @override
  State<MotionField> createState() => _MotionFieldState();
}

class _MotionFieldState extends State<MotionField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});

  @override
  void didUpdateWidget(MotionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateShake && widget.attempt != oldWidget.attempt && widget.error &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_focusChanged);
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final target = widget.error
        ? theme.colorScheme.error
        : widget.focusNode.hasFocus
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) => Transform.translate(
        offset: reduced
            ? Offset.zero
            : Offset(
                math.sin(_shake.value * math.pi * 6) *
                    AppSpace.s8 *
                    (1 - _shake.value),
                0,
              ),
        child: child,
      ),
      child: TweenAnimationBuilder<BorderSide>(
        tween: _BorderSideTween(
          end: BorderSide(
            color: target,
            width: widget.focusNode.hasFocus ? 2 : 1,
          ),
        ),
        duration: reduced ? Duration.zero : AppMotion.fast,
        curve: AppMotion.curve,
        builder: (_, side, child) {
          final border = OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.radius),
            borderSide: side,
          );
          return Theme(
            data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                errorBorder: border,
                focusedErrorBorder: border,
                disabledBorder: border,
              ),
            ),
            child: child!,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _BorderSideTween extends Tween<BorderSide> {
  _BorderSideTween({super.end});
  @override
  BorderSide lerp(double t) => BorderSide.lerp(begin!, end!, t);
}
