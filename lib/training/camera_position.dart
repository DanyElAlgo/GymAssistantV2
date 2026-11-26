import 'exercise.dart';

/// Where the phone stands relative to the user and the machine (GLOSSARY, Marco Teórico §1.5).
enum CameraPosition {
  /// Perpendicular to the user's side.
  side(angleFromSideDegrees: 0),

  /// Diagonal, between the side and the front.
  oblique(angleFromSideDegrees: 30);

  const CameraPosition({required this.angleFromSideDegrees});

  /// How far the phone turns from the user's side towards their front.
  final int angleFromSideDegrees;
}

extension RecommendedCameraPosition on Exercise {
  /// The position P07 recommends: oblique for the leg press, which needs both the side and the
  /// front view; side for the other two, analysed in the sagittal plane.
  CameraPosition get cameraPosition => switch (this) {
        Exercise.legPress45 => CameraPosition.oblique,
        Exercise.latPulldown || Exercise.legExtension => CameraPosition.side,
      };
}
