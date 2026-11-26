import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../preferences/preferences_service.dart';
import '../routing/app_router.dart';
import 'exercise.dart';
import 'exercise_presentation.dart';

/// P06, Elegir ejercicio. The silent mode switch arrives in F2 (HU-20).
class ChooseExerciseScreen extends StatelessWidget {
  const ChooseExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chooseExerciseTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final exercise in Exercise.values) _ExerciseOption(exercise: exercise),
        ],
      ),
    );
  }
}

class _ExerciseOption extends ConsumerWidget {
  const _ExerciseOption({required this.exercise});

  final Exercise exercise;

  /// P07 first, unless the user asked not to see it again for this exercise (Diseño §10.1).
  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final skipGuide = await ref.read(preferencesServiceProvider).cameraGuideSkipped(exercise);
    if (!context.mounted) return;
    context.go(skipGuide ? AppRoutes.framing(exercise) : AppRoutes.cameraGuide(exercise));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SvgPicture.asset(
                exercise.illustrationAsset,
                width: 120,
                height: 80,
                excludeFromSemantics: true,
                colorFilter: ColorFilter.mode(theme.colorScheme.onSurfaceVariant, BlendMode.srcIn),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  exercise.localizedName(AppLocalizations.of(context)),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
