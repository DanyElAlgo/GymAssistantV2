import 'package:flutter/foundation.dart';

import 'body.dart';

/// An event from the native analysis over `gymassistant/analysis/events`
/// (Diseño §11.4). F1 emits `framing` and `performance`.
sealed class AnalysisEvent {
  const AnalysisEvent({required this.emittedAtMs});

  /// When Kotlin emitted the event (`t`), in wall-clock milliseconds since the epoch.
  final int emittedAtMs;
}

/// `framing`, whenever the framing check's result changes during P08 (HU-10).
final class FramingEvent extends AnalysisEvent {
  const FramingEvent({
    required super.emittedAtMs,
    required this.personDetected,
    required this.isValid,
    required this.missingJoints,
    this.measuredSide,
  });

  /// Whether the camera sees a person at all.
  final bool personDetected;

  /// Whether every required joint has been seen long enough for a set to start.
  final bool isValid;

  /// The required joints the camera does not see; all of them when no person is detected.
  final List<Joint> missingJoints;

  /// The side the exercise is measured on; known only while [isValid].
  final Side? measuredSide;

  @override
  bool operator ==(Object other) =>
      other is FramingEvent &&
      other.emittedAtMs == emittedAtMs &&
      other.personDetected == personDetected &&
      other.isValid == isValid &&
      listEquals(other.missingJoints, missingJoints) &&
      other.measuredSide == measuredSide;

  @override
  int get hashCode => Object.hash(emittedAtMs, personDetected, isValid, Object.hashAll(missingJoints), measuredSide);

  @override
  String toString() =>
      'FramingEvent(t: $emittedAtMs, person: $personDetected, valid: $isValid, missing: $missingJoints, side: $measuredSide)';
}

/// `performance`, once per second, to measure RNF-01 and RNF-02.
final class PerformanceEvent extends AnalysisEvent {
  const PerformanceEvent({required super.emittedAtMs, required this.fps, required this.captureToAnalysisMs});

  /// Frames analysed during the last second.
  final double fps;

  /// Median time from capturing a frame to having its pose, during the last second;
  /// null if no frame was analysed.
  final int? captureToAnalysisMs;

  @override
  bool operator ==(Object other) =>
      other is PerformanceEvent &&
      other.emittedAtMs == emittedAtMs &&
      other.fps == fps &&
      other.captureToAnalysisMs == captureToAnalysisMs;

  @override
  int get hashCode => Object.hash(emittedAtMs, fps, captureToAnalysisMs);

  @override
  String toString() => 'PerformanceEvent(t: $emittedAtMs, fps: $fps, latency_ms: $captureToAnalysisMs)';
}
