/// An event from the native analysis over `gymassistant/analysis/events`
/// (Diseño §11.4). F1 emits `performance`; `framing` arrives with SCRUM-50.
sealed class AnalysisEvent {
  const AnalysisEvent({required this.emittedAtMs});

  /// When Kotlin emitted the event (`t`), in wall-clock milliseconds since the epoch.
  final int emittedAtMs;
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
