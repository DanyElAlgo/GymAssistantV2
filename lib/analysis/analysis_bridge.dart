import 'package:flutter/widgets.dart';

import '../training/exercise.dart';
import 'analysis_event.dart';

/// The app's only way into the native analysis (Diseño §4.2, §11.4).
///
/// Screens depend on this interface; [ChannelAnalysisBridge] talks to Kotlin, and tests use a
/// fake. No image ever crosses it (RNF-07, ADR-0005): it carries commands, events and the
/// native camera view.
abstract interface class AnalysisBridge {
  /// The native camera preview with the skeleton (PlatformView `gymassistant/camera-view`).
  /// [onCreated] runs once the native view exists, which [startCamera] requires.
  Widget cameraView({required VoidCallback onCreated});

  /// Starts the front camera in the camera view. Throws [AnalysisException] with
  /// [AnalysisErrorCode.cameraPermission] or [AnalysisErrorCode.cameraInUse].
  Future<void> startCamera();

  /// Asks for `framing` events for [exercise], with the thresholds of [rulesVersion]. Throws
  /// [AnalysisException] with [AnalysisErrorCode.unknownExercise], or with
  /// [AnalysisErrorCode.invalidConfig] when that rules file is missing or invalid.
  Future<void> checkFraming({required Exercise exercise, required String rulesVersion});

  /// Starts a set of [exercise] with the thresholds of [rulesVersion]: from now until [stopSet]
  /// the measured side stays fixed, and `framing` reports when framing is lost or regained.
  /// Throws [AnalysisException] like [checkFraming].
  Future<void> startSet({required Exercise exercise, required bool silentMode, required String rulesVersion});

  /// Ends the set and returns the native repetition count, as a cross-check; zero until the
  /// repetition count arrives in F2. Throws [AnalysisException] with
  /// [AnalysisErrorCode.noActiveSet] when no set is running.
  Future<SetSummary> stopSet();

  /// Stops the camera and frees the pose model.
  Future<void> releaseCamera();

  /// The model variant in use, the analysis resolution and the measured fps.
  Future<AnalysisCapabilities> capabilities();

  /// Events from the native analysis.
  Stream<AnalysisEvent> get events;
}

/// The error codes of the native channel (Diseño §11.4).
enum AnalysisErrorCode {
  cameraPermission('CAMERA_PERMISSION'),
  cameraInUse('CAMERA_IN_USE'),
  unknownExercise('UNKNOWN_EXERCISE'),
  invalidConfig('INVALID_CONFIG'),
  noActiveSet('NO_ACTIVE_SET'),

  /// Any code outside the contract.
  unknown('');

  const AnalysisErrorCode(this.code);

  final String code;

  static AnalysisErrorCode fromCode(String code) =>
      values.firstWhere((value) => value.code == code, orElse: () => unknown);
}

/// A command the native analysis refused.
class AnalysisException implements Exception {
  const AnalysisException(this.code, [this.message]);

  final AnalysisErrorCode code;
  final String? message;

  @override
  String toString() => 'AnalysisException(${code.name}${message == null ? '' : ': $message'})';
}

/// The MediaPipe Pose Landmarker models the app ships.
enum ModelVariant {
  lite('LITE'),
  full('FULL');

  const ModelVariant(this.code);

  final String code;

  static ModelVariant? fromCode(String? code) {
    for (final variant in values) {
      if (variant.code == code) return variant;
    }
    return null;
  }
}

/// Diseño §11.4 `capabilities`.
class AnalysisCapabilities {
  const AnalysisCapabilities({required this.modelVariant, this.analysisWidth, this.analysisHeight, this.fps});

  final ModelVariant? modelVariant;

  /// Size of the analysed frames, upright; null before the first frame.
  final int? analysisWidth;
  final int? analysisHeight;

  /// The latest measured fps; null before the first measurement.
  final double? fps;
}

/// Diseño §11.4 `stopSet`: the native repetition counts.
class SetSummary {
  const SetSummary({required this.totalRepetitions, required this.correctRepetitions});

  final int totalRepetitions;
  final int correctRepetitions;
}
