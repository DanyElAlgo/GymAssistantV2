import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../training/exercise.dart';
import 'analysis_bridge.dart';
import 'analysis_event.dart';
import 'body.dart';

/// [AnalysisBridge] over the native channels of Diseño §11.4.
class ChannelAnalysisBridge implements AnalysisBridge {
  static const _methods = MethodChannel('gymassistant/analysis');
  static const _events = EventChannel('gymassistant/analysis/events');
  static const _cameraViewType = 'gymassistant/camera-view';

  /// One native subscription shared by every listener: Kotlin keeps a single event sink, so a
  /// second channel subscription would replace the first.
  @override
  late final Stream<AnalysisEvent> events =
      _events.receiveBroadcastStream().map(_parseEvent).where((event) => event != null).cast<AnalysisEvent>();

  @override
  Widget cameraView({required VoidCallback onCreated}) => AndroidView(
        viewType: _cameraViewType,
        onPlatformViewCreated: (_) => onCreated(),
      );

  @override
  Future<void> startCamera() => _invoke('startCamera');

  @override
  Future<void> checkFraming(Exercise exercise) => _invoke('checkFraming', {'exercise': exercise.code});

  @override
  Future<void> startSet({required Exercise exercise, required bool silentMode, required String rulesVersion}) =>
      _invoke('startSet', {'exercise': exercise.code, 'silentMode': silentMode, 'rulesVersion': rulesVersion});

  @override
  Future<SetSummary> stopSet() async {
    final summary = await _invoke<Map<Object?, Object?>>('stopSet');
    return SetSummary(totalRepetitions: summary!['total_reps']! as int, correctRepetitions: summary['correct_reps']! as int);
  }

  @override
  Future<void> releaseCamera() => _invoke('releaseCamera');

  @override
  Future<AnalysisCapabilities> capabilities() async {
    final map = await _invoke<Map<Object?, Object?>>('capabilities');
    return AnalysisCapabilities(
      modelVariant: ModelVariant.fromCode(map!['model_variant'] as String?),
      analysisWidth: map['analysis_width'] as int?,
      analysisHeight: map['analysis_height'] as int?,
      fps: (map['fps'] as num?)?.toDouble(),
    );
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _methods.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw AnalysisException(AnalysisErrorCode.fromCode(e.code), e.message);
    }
  }

  /// The typed event, or null for a type this version of the app doesn't handle yet.
  static AnalysisEvent? _parseEvent(Object? raw) {
    final map = raw! as Map<Object?, Object?>;
    final emittedAtMs = map['t']! as int;
    return switch (map['type']) {
      'framing' => FramingEvent(
          emittedAtMs: emittedAtMs,
          personDetected: map['person_detected']! as bool,
          isValid: map['is_valid']! as bool,
          // Both sides list the same joints; one this version doesn't know is left out.
          missingJoints: (map['missing_landmarks']! as List<Object?>).map((code) => Joint.fromCode(code! as String)).nonNulls.toList(),
          measuredSide: Side.fromCode(map['measured_side'] as String?),
        ),
      'performance' => PerformanceEvent(
          emittedAtMs: emittedAtMs,
          fps: (map['fps']! as num).toDouble(),
          captureToAnalysisMs: map['latency_ms'] as int?,
        ),
      _ => null,
    };
  }
}
