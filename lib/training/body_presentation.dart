import '../analysis/analysis_event.dart';
import '../analysis/body.dart';
import '../l10n/app_localizations.dart';

/// How a [Joint] is named on screen.
extension JointPresentation on Joint {
  String localizedName(AppLocalizations l10n) => switch (this) {
        Joint.shoulder => l10n.jointShoulder,
        Joint.elbow => l10n.jointElbow,
        Joint.wrist => l10n.jointWrist,
        Joint.hip => l10n.jointHip,
        Joint.knee => l10n.jointKnee,
        Joint.ankle => l10n.jointAnkle,
      };
}

/// What a [FramingEvent] tells the user is wrong.
extension FramingPresentation on FramingEvent {
  /// That no one is in view, or which body parts are out of it; null when every required
  /// joint is seen.
  String? problem(AppLocalizations l10n) => switch (this) {
        FramingEvent(personDetected: false) => l10n.framingNoPerson,
        FramingEvent(missingJoints: final missing) when missing.isNotEmpty =>
          l10n.framingMissingJoints(missing.map((joint) => joint.localizedName(l10n)).join(', ')),
        FramingEvent() => null,
      };
}

/// How a [Side] is named on screen.
extension SidePresentation on Side {
  String localizedName(AppLocalizations l10n) => switch (this) {
        Side.left => l10n.sideLeft,
        Side.right => l10n.sideRight,
      };
}
