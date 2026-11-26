import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'exercise.dart';
import 'exercise_presentation.dart';

/// P08, Verificar encuadre. The camera, skeleton and framing check arrive with
/// SCRUM-49 and SCRUM-50.
class FramingScreen extends StatelessWidget {
  const FramingScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.localizedName(AppLocalizations.of(context)))),
    );
  }
}
