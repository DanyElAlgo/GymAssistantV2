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

/// How a [Side] is named on screen.
extension SidePresentation on Side {
  String localizedName(AppLocalizations l10n) => switch (this) {
        Side.left => l10n.sideLeft,
        Side.right => l10n.sideRight,
      };
}
