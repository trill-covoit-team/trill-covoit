import 'package:flutter/material.dart';
import 'package:trill_covoit/core/theme/tokens.dart';

class LoadingMorphButton extends StatelessWidget {
  const LoadingMorphButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.loadingLabel = 'Envoi en cours',
  });

  final String label;
  final String loadingLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final minimum = theme.filledButtonTheme.style?.minimumSize?.resolve({});
    final textHeight = MediaQuery.textScalerOf(context).scale(
      theme.textTheme.labelLarge!.fontSize!,
    );
    final height = textHeight + AppSpace.s32 > (minimum?.height ?? kMinTouch)
        ? textHeight + AppSpace.s32
        : (minimum?.height ?? kMinTouch);
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: AnimatedContainer(
          key: const ValueKey('loading-morph'),
          duration: reduced ? Duration.zero : AppMotion.normal,
          curve: AppMotion.curve,
          width: isLoading ? height : constraints.maxWidth,
          height: height,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
              animationDuration: reduced ? Duration.zero : AppMotion.normal,
              shape: isLoading
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
            ),
            child: isLoading
                ? Semantics(
                    label: label,
                    liveRegion: true,
                    child: SizedBox(
                      width: AppSpace.s24,
                      height: AppSpace.s24,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onSurface,
                        strokeWidth: AppSpace.s4,
                        semanticsLabel: loadingLabel,
                        value: reduced ? .75 : null,
                      ),
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}
