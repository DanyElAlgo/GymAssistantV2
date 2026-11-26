import 'dart:collection';
import 'dart:math' as math;

import 'analysis_event.dart';

/// The pipeline's measured performance as Flutter sees it (RNF-01, RNF-02).
///
/// Latency runs from frame capture until the `performance` event reaches Flutter: the native
/// capture-to-analysis latency plus the delivery time, measured on the wall clock both sides
/// share. The median covers the latest [windowSeconds] one-second events.
class PerformanceStats {
  PerformanceStats({this.windowSeconds = 10});

  final int windowSeconds;

  double? _fps;
  final _latenciesMs = ListQueue<int>();

  /// Frames analysed per second in the latest event; null before the first one.
  double? get fps => _fps;

  /// Median capture-to-Flutter latency; null until a frame has been analysed.
  int? get medianLatencyMs {
    if (_latenciesMs.isEmpty) return null;
    final sorted = _latenciesMs.toList()..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[middle] : ((sorted[middle - 1] + sorted[middle]) / 2).round();
  }

  /// Takes [event], received at [receivedAtMs] on the wall clock.
  void add(PerformanceEvent event, {required int receivedAtMs}) {
    _fps = event.fps;
    final captureToAnalysisMs = event.captureToAnalysisMs;
    if (captureToAnalysisMs == null) return;
    final deliveryMs = math.max(0, receivedAtMs - event.emittedAtMs);
    _latenciesMs.addLast(captureToAnalysisMs + deliveryMs);
    while (_latenciesMs.length > windowSeconds) {
      _latenciesMs.removeFirst();
    }
  }
}
