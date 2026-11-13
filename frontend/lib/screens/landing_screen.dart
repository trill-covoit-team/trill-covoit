import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/providers/auth_provider.dart';
import 'package:trill_covoit/widgets/motion_entrance.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    this.onStart,
    this.onLogin,
  });

  final VoidCallback? onStart;
  final VoidCallback? onLogin;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _entrance = EntranceTimeline();

  Widget _enter(int index, Widget child) => MotionEntrance(
        timeline: _entrance,
        index: index,
        start: AppMotion.slow,
        child: child,
      );

  void _handleStart(BuildContext context) {
    final auth = context.read<AuthProvider>();
    auth.clearMessages();
    auth.setPendingVerificationEmail(null);
    widget.onStart?.call();
  }

  void _handleLogin(BuildContext context) {
    final auth = context.read<AuthProvider>();
    auth.clearMessages();
    auth.setPendingVerificationEmail(null);
    widget.onLogin?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                    return const SizedBox.shrink();
                  }
                  final visualSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight * .5,
                  );
                  final geometry = _RouteGeometry(
                    visualSize,
                    theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    MediaQuery.textScalerOf(context),
                  );
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: visualSize.height,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ExcludeSemantics(
                                child: Animate(
                                  effects: [
                                    CustomEffect(
                                      duration: MediaQuery.disableAnimationsOf(context)
                                          ? Duration.zero
                                          : AppMotion.slow,
                                      curve: AppMotion.curve,
                                      builder: (_, value, _) => CustomPaint(
                                        painter: _RoutePainter(
                                          primary: theme.colorScheme.primary,
                                          background: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          foreground: theme.colorScheme.onPrimary,
                                          labelStyle: theme.textTheme.labelSmall!
                                              .copyWith(
                                                color: theme.colorScheme.onSurface,
                                              ),
                                          textScaler: MediaQuery.textScalerOf(
                                            context,
                                          ),
                                          geometry: geometry,
                                          progress: MediaQuery.disableAnimationsOf(context)
                                              ? 1
                                              : value,
                                        ),
                                      ),
                                    ),
                                  ],
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Positioned(
                                left: geometry.marker.position.dx -
                                    _carSize.width / 2,
                                top: geometry.marker.position.dy -
                                    _carSize.height / 2,
                                width: _carSize.width,
                                height: _carSize.height,
                                child: ExcludeSemantics(
                                  child: Transform.rotate(
                                    key: const ValueKey('welcome-car-rotation'),
                                    angle: geometry.marker.angle + math.pi / 2,
                                    child: SvgPicture.asset(
                                      'assets/images/car_top.svg',
                                      key: const ValueKey('welcome-car'),
                                      width: _carSize.width,
                                      height: _carSize.height,
                                      colorFilter: ColorFilter.mode(
                                        theme.colorScheme.primary,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s24,
                            vertical: AppSpace.s16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _enter(
                                0,
                                Text(
                                  'TRILL Covoit’',
                                  style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.s8),
                              _enter(
                                1,
                                Text(
                                  'Le covoiturage universitaire simple, économique et sécurisé',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.s24),
                              _enter(
                                2,
                                const _BenefitRow(
                                  icon: Icons.school_outlined,
                                  label: 'Réservé à la communauté étudiante et universitaire',
                                ),
                              ),
                              const SizedBox(height: AppSpace.s12),
                              _enter(
                                3,
                                const _BenefitRow(
                                  icon: Icons.euro_outlined,
                                  label: 'Partage équitable des frais sans commission',
                                ),
                              ),
                              const SizedBox(height: AppSpace.s12),
                              _enter(
                                4,
                                const _BenefitRow(
                                  icon: Icons.eco_outlined,
                                  label: 'Réduisez votre empreinte carbone au quotidien',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s24,
                AppSpace.s8,
                AppSpace.s24,
                AppSpace.s16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMinTouch * 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _enter(
                      5,
                      FilledButton(
                        key: const ValueKey('landing-start-button'),
                        onPressed: () => _handleStart(context),
                        child: const Text('Commencer'),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s8),
                    _enter(
                      6,
                      OutlinedButton(
                        key: const ValueKey('landing-login-button'),
                        onPressed: () => _handleLogin(context),
                        child: const Text("J'ai déjà un compte"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _carSize = Size(28, 50);

class _RouteGeometry {
  _RouteGeometry(Size size, TextStyle labelStyle, TextScaler scaler) {
    final start = Offset(size.width * .15, size.height * .75);
    final control1 = Offset(size.width * .2, size.height * .15);
    final control2 = Offset(size.width * .8, size.height * .85);
    final end = Offset(size.width * .85, size.height * .25);

    pins = [start, end];
    route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        end.dx,
        end.dy,
      );

    labels = [
      _RouteLabel(
        'IUT Rangueil',
        size,
        labelStyle,
        scaler,
        start + const Offset(AppSpace.s12, -AppSpace.s32),
      ),
      _RouteLabel(
        'Campus Mirail',
        size,
        labelStyle,
        scaler,
        end + const Offset(-AppSpace.s12, -AppSpace.s32),
        alignRight: true,
      ),
    ];

    final obstacles = [
      for (final pin in pins)
        Rect.fromLTRB(
          pin.dx - AppSpace.s12,
          pin.dy - AppSpace.s32,
          pin.dx + AppSpace.s12,
          pin.dy,
        ),
      for (final label in labels) label.bounds,
    ];

    final metric = route.computeMetrics().first;
    for (final fraction in [.45, .50, .55, .40, .35]) {
      final tangent = metric.getTangentForOffset(metric.length * fraction)!;
      marker = tangent;
      final angle = tangent.angle + math.pi / 2;
      final width =
          _carSize.width * math.cos(angle).abs() +
          _carSize.height * math.sin(angle).abs();
      final height =
          _carSize.width * math.sin(angle).abs() +
          _carSize.height * math.cos(angle).abs();
      final bounds = Rect.fromCenter(
        center: tangent.position,
        width: width,
        height: height,
      ).inflate(AppSpace.s4);
      if (!obstacles.any(bounds.overlaps)) break;
    }
  }

  late final Path route;
  late final List<Offset> pins;
  late final List<_RouteLabel> labels;
  late Tangent marker;
}

class _RouteLabel {
  _RouteLabel(
    String label,
    Size size,
    TextStyle style,
    TextScaler scaler,
    Offset anchor, {
    bool alignRight = false,
  }) {
    text = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: size.width * .4);
    final maxLeft = math.max(AppSpace.s8, size.width - text.width - AppSpace.s8);
    final left = (alignRight ? anchor.dx - text.width : anchor.dx).clamp(
      AppSpace.s8,
      maxLeft,
    );
    origin = Offset(left, anchor.dy);
    bounds = (origin & text.size).inflate(AppSpace.s4);
  }

  late final TextPainter text;
  late final Offset origin;
  late final Rect bounds;
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: AppSpace.s24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.primary,
    required this.background,
    required this.foreground,
    required this.labelStyle,
    required this.textScaler,
    required this.geometry,
    this.progress = 1,
  });

  final Color primary;
  final Color background;
  final Color foreground;
  final TextStyle labelStyle;
  final TextScaler textScaler;
  final _RouteGeometry geometry;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [background, primary],
        ).createShader(bounds),
    );
    final metric = geometry.route.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = AppSpace.s4,
    );
    for (final point in geometry.pins) {
      final pin = Path()
        ..moveTo(point.dx, point.dy)
        ..quadraticBezierTo(
          point.dx - AppSpace.s24,
          point.dy - AppSpace.s32,
          point.dx,
          point.dy - AppSpace.s32,
        )
        ..quadraticBezierTo(
          point.dx + AppSpace.s24,
          point.dy - AppSpace.s32,
          point.dx,
          point.dy,
        );
      canvas.drawPath(pin, Paint()..color = foreground);
      canvas.drawCircle(
        point.translate(0, -AppSpace.s24),
        AppSpace.s4,
        Paint()..color = primary,
      );
    }
    canvas.save();
    canvas.translate(
      geometry.marker.position.dx,
      geometry.marker.position.dy + AppShadow.low.first.offset.dy,
    );
    canvas.rotate(geometry.marker.angle + math.pi / 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: AppSpace.s24,
        height: AppSpace.s48,
      ),
      Paint()
        ..color = AppColors.textPrimary.withAlpha(64)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppSpace.s4),
    );
    canvas.restore();
    for (final label in geometry.labels) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          label.bounds,
          const Radius.circular(AppRadius.sm),
        ),
        Paint()..color = background,
      );
      label.text.paint(canvas, label.origin);
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      primary != oldDelegate.primary ||
      progress != oldDelegate.progress ||
      background != oldDelegate.background ||
      foreground != oldDelegate.foreground ||
      geometry != oldDelegate.geometry ||
      labelStyle != oldDelegate.labelStyle ||
      textScaler != oldDelegate.textScaler;
}
