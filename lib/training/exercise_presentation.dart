import '../l10n/app_localizations.dart';
import 'exercise.dart';

/// How an [Exercise] is shown on screen.
extension ExercisePresentation on Exercise {
  /// The exercise's name in the current language.
  String localizedName(AppLocalizations l10n) => switch (this) {
        Exercise.legPress45 => l10n.exerciseLegPress45,
        Exercise.latPulldown => l10n.exerciseLatPulldown,
        Exercise.legExtension => l10n.exerciseLegExtension,
      };

  /// A neutral line drawing of the machine, without people.
  String get illustrationAsset => switch (this) {
        Exercise.legPress45 => 'assets/exercises/leg_press_45.svg',
        Exercise.latPulldown => 'assets/exercises/lat_pulldown.svg',
        Exercise.legExtension => 'assets/exercises/leg_extension.svg',
      };
}
