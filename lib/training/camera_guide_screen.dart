import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../preferences/preferences_service.dart';
import '../routing/app_router.dart';
import 'camera_position.dart';
import 'exercise.dart';
import 'exercise_presentation.dart';
import 'portrait_lock.dart';

/// P07, Guía de cámara: where to put the phone for [exercise] and how far away (HU-09, RF-10).
///
/// «No volver a mostrar» is saved as soon as it is ticked, so the next time P06 goes straight
/// to P08 for this exercise. The screen stays in portrait.
class CameraGuideScreen extends ConsumerStatefulWidget {
  const CameraGuideScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<CameraGuideScreen> createState() => _CameraGuideScreenState();
}

class _CameraGuideScreenState extends ConsumerState<CameraGuideScreen> {
  var _skipNextTime = false;

  void _setSkipNextTime(bool? value) {
    final skip = value ?? false;
    setState(() => _skipNextTime = skip);
    ref.read(preferencesServiceProvider).setCameraGuideSkipped(widget.exercise, skipped: skip);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final position = widget.exercise.cameraPosition;
    return PortraitLock(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.exercise.localizedName(l10n))),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.cameraGuideTitle, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox.square(
                          dimension: 220,
                          child: CustomPaint(
                            painter: _TopViewPainter(
                              position: position,
                              colors: theme.colorScheme,
                              textStyle: theme.textTheme.labelLarge!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _Instruction(
                        icon: Icons.rotate_right,
                        text: switch (position) {
                          CameraPosition.side => l10n.cameraGuideSide,
                          CameraPosition.oblique => l10n.cameraGuideOblique,
                        },
                      ),
                      _Instruction(icon: Icons.straighten, text: l10n.cameraGuideDistance),
                      if (widget.exercise == Exercise.latPulldown)
                        _Instruction(icon: Icons.height, text: l10n.cameraGuideChestHeight),
                      _Instruction(icon: Icons.stay_current_portrait, text: l10n.cameraGuideUpright),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                value: _skipNextTime,
                onChanged: _setSkipNextTime,
                title: Text(l10n.cameraGuideDontShowAgain),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push(AppRoutes.framing(widget.exercise)),
                    child: Text(l10n.cameraGuideReady),
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

class _Instruction extends StatelessWidget {
  const _Instruction({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

/// The user seen from above, facing up, with the phone at [position] on their side. The texts
/// say the same, so the drawing is left out of the semantics.
class _TopViewPainter extends CustomPainter {
  _TopViewPainter({required this.position, required this.colors, required this.textStyle});

  final CameraPosition position;
  final ColorScheme colors;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final user = Offset(size.width * 0.35, size.height * 0.64);
    final radius = size.width * 0.5;
    final angle = position.angleFromSideDegrees * math.pi / 180;
    // Up is the user's front, right is their side.
    final phone = user + Offset(math.cos(angle), -math.sin(angle)) * radius;

    final line = Paint()
      ..color = colors.outline
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final body = Paint()..color = colors.onSurfaceVariant;
    final accent = Paint()..color = colors.primary;

    // Facing direction.
    canvas.drawLine(user, user + Offset(0, -radius * 0.7), line);
    _drawArrowHead(canvas, user + Offset(0, -radius * 0.7), line);
    // The side line the angle is measured from.
    canvas.drawLine(user, user + Offset(radius * 1.05, 0), line);

    // Shoulders and head.
    canvas.drawOval(Rect.fromCenter(center: user, width: 70, height: 28), body);
    canvas.drawCircle(user, 12, Paint()..color = colors.surface);
    canvas.drawCircle(user, 10, body);

    // Line of sight and the angle.
    canvas.drawLine(user, phone, Paint()
      ..color = colors.primary
      ..strokeWidth = 2);
    if (angle > 0) {
      canvas.drawArc(Rect.fromCircle(center: user, radius: radius * 0.55), -angle, angle, false, line);
    }
    final label = TextPainter(
      text: TextSpan(text: '${position.angleFromSideDegrees}°', style: textStyle.copyWith(color: colors.onSurface)),
      textDirection: TextDirection.ltr,
    )..layout();
    // Inside the arc, halfway between the side line and the line of sight; above the side line
    // when the two coincide.
    final labelCentre = angle > 0
        ? user + Offset(math.cos(angle / 2), -math.sin(angle / 2)) * (radius * 0.8)
        : user + Offset(radius * 0.72, -label.height / 2 - 4);
    label.paint(canvas, labelCentre - Offset(label.width / 2, label.height / 2));

    // The phone, its screen facing the user.
    canvas.save();
    canvas.translate(phone.dx, phone.dy);
    canvas.rotate(-angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 12, height: 40), const Radius.circular(3)),
      accent,
    );
    canvas.restore();
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Paint paint) {
    canvas.drawLine(tip, tip + const Offset(-6, 8), paint);
    canvas.drawLine(tip, tip + const Offset(6, 8), paint);
  }

  @override
  bool shouldRepaint(_TopViewPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.colors != colors || oldDelegate.textStyle != textStyle;
}
