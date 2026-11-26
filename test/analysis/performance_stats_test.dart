import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/analysis_event.dart';
import 'package:gymassistant/analysis/performance_stats.dart';

void main() {
  test('latency runs from capture to arrival in Flutter: native latency plus delivery', () {
    final stats = PerformanceStats();

    stats.add(const PerformanceEvent(emittedAtMs: 50000, fps: 24, captureToAnalysisMs: 80), receivedAtMs: 50012);

    expect(stats.fps, 24);
    expect(stats.medianLatencyMs, 92);
  });

  test('the latency shown is the median of the last 10 seconds', () {
    final stats = PerformanceStats();
    // An old slow second that has left the window, then 10 seconds at 100 to 190 ms, one with a 900 ms spike.
    final totals = [5000, 100, 110, 120, 130, 140, 150, 160, 170, 180, 900];
    for (final (second, total) in totals.indexed) {
      final emitted = 1000 * second;
      stats.add(PerformanceEvent(emittedAtMs: emitted, fps: 20, captureToAnalysisMs: total - 10), receivedAtMs: emitted + 10);
    }

    // Median of 100…180 and 900: the mean of 140 and 150.
    expect(stats.medianLatencyMs, 145);
  });

  test('a second without analysed frames shows 0 fps and keeps the latency of earlier seconds', () {
    final stats = PerformanceStats();
    stats.add(const PerformanceEvent(emittedAtMs: 1000, fps: 18, captureToAnalysisMs: 70), receivedAtMs: 1005);

    stats.add(const PerformanceEvent(emittedAtMs: 2000, fps: 0, captureToAnalysisMs: null), receivedAtMs: 2005);

    expect(stats.fps, 0);
    expect(stats.medianLatencyMs, 75);
  });

  test('a delivery that appears to arrive before it was sent counts as instant', () {
    // The two sides read the same wall clock, but it can be adjusted between the readings.
    final stats = PerformanceStats();

    stats.add(const PerformanceEvent(emittedAtMs: 1000, fps: 30, captureToAnalysisMs: 60), receivedAtMs: 990);

    expect(stats.medianLatencyMs, 60);
  });
}
