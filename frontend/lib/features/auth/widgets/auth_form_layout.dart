import 'package:flutter/material.dart';
import 'package:trill_covoit/core/theme/tokens.dart';

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.child,
    this.isBusy = false,
    this.showTitle = true,
    this.footer,
    this.onBack,
  });

  final String title;
  final Widget child;
  final bool isBusy;
  final bool showTitle;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        appBar: AppBar(
          title: showTitle ? Text(title) : null,
          automaticallyImplyLeading: !isBusy,
          leading: onBack == null
              ? null
              : IconButton(
                  tooltip: 'Retour',
                  onPressed: isBusy ? null : onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.s24,
                        AppSpace.s16,
                        AppSpace.s24,
                        AppSpace.s24,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: kMinTouch * 10,
                          ),
                          child: SizedBox(width: double.infinity, child: child),
                        ),
                      ),
                    ),
                    // Overlay semi-transparent pendant le chargement.
                    if (isBusy)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: isBusy ? 0.4 : 0.0,
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : AppMotion.fast,
                            child: ColoredBox(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s24,
                    AppSpace.s8,
                    AppSpace.s24,
                    AppSpace.s16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kMinTouch * 10,
                      ),
                      child: SizedBox(width: double.infinity, child: footer),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
