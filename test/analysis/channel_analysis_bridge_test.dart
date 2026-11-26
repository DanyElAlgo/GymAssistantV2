import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/analysis_bridge.dart';
import 'package:gymassistant/analysis/analysis_event.dart';
import 'package:gymassistant/analysis/body.dart';
import 'package:gymassistant/analysis/channel_analysis_bridge.dart';
import 'package:gymassistant/training/exercise.dart';

const methods = MethodChannel('gymassistant/analysis');
const events = EventChannel('gymassistant/analysis/events');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockStreamHandler(events, null);
  });

  void answer(Future<Object?> Function(MethodCall call) handler) => messenger.setMockMethodCallHandler(methods, handler);

  void emit(List<Object?> natives) => messenger.setMockStreamHandler(
        events,
        MockStreamHandler.inline(onListen: (arguments, sink) {
          natives.forEach(sink.success);
          sink.endOfStream();
        }),
      );

  test('performance events arrive typed, and event types it does not know yet are skipped', () async {
    emit([
      {'type': 'performance', 't': 1700000000123, 'fps': 23.5, 'latency_ms': 71},
      {'type': 'phase', 't': 1700000000200, 'phase': 'START'},
      {'type': 'performance', 't': 1700000001123, 'fps': 0.0, 'latency_ms': null},
    ]);

    final received = await ChannelAnalysisBridge().events.toList();

    expect(received, const [
      PerformanceEvent(emittedAtMs: 1700000000123, fps: 23.5, captureToAnalysisMs: 71),
      PerformanceEvent(emittedAtMs: 1700000001123, fps: 0, captureToAnalysisMs: null),
    ]);
  });

  test('framing events arrive typed, with the missing joints by name and the measured side', () async {
    emit([
      {'type': 'framing', 't': 1700000000100, 'person_detected': false, 'is_valid': false, 'missing_landmarks': ['shoulder', 'elbow', 'wrist'], 'measured_side': null},
      {'type': 'framing', 't': 1700000000200, 'person_detected': true, 'is_valid': false, 'missing_landmarks': ['knee'], 'measured_side': null},
      {'type': 'framing', 't': 1700000002300, 'person_detected': true, 'is_valid': true, 'missing_landmarks': <Object?>[], 'measured_side': 'right'},
    ]);

    final received = await ChannelAnalysisBridge().events.toList();

    expect(received, const [
      FramingEvent(
        emittedAtMs: 1700000000100,
        personDetected: false,
        isValid: false,
        missingJoints: [Joint.shoulder, Joint.elbow, Joint.wrist],
      ),
      FramingEvent(emittedAtMs: 1700000000200, personDetected: true, isValid: false, missingJoints: [Joint.knee]),
      FramingEvent(emittedAtMs: 1700000002300, personDetected: true, isValid: true, missingJoints: [], measuredSide: Side.right),
    ]);
  });

  test('checkFraming sends the exercise code', () async {
    final calls = <MethodCall>[];
    answer((call) async {
      calls.add(call);
      return null;
    });

    await ChannelAnalysisBridge().checkFraming(Exercise.legPress45);

    expect(calls.single.method, 'checkFraming');
    expect(calls.single.arguments, {'exercise': 'LEG_PRESS_45'});
  });

  test('a native refusal arrives as an AnalysisException with its contract code', () async {
    answer((call) async => throw PlatformException(code: 'CAMERA_PERMISSION', message: 'not granted'));

    await expectLater(
      ChannelAnalysisBridge().startCamera(),
      throwsA(isA<AnalysisException>().having((e) => e.code, 'code', AnalysisErrorCode.cameraPermission)),
    );
  });

  test('commands go to the native methods of Diseño §11.4', () async {
    final calls = <String>[];
    answer((call) async {
      calls.add(call.method);
      return null;
    });
    final bridge = ChannelAnalysisBridge();

    await bridge.startCamera();
    await bridge.releaseCamera();

    expect(calls, ['startCamera', 'releaseCamera']);
  });

  test('capabilities report the model variant, the analysis resolution and the measured fps', () async {
    answer((call) async => {'model_variant': 'FULL', 'analysis_width': 480, 'analysis_height': 640, 'fps': 21.0});

    final capabilities = await ChannelAnalysisBridge().capabilities();

    expect(capabilities.modelVariant, ModelVariant.full);
    expect(capabilities.analysisWidth, 480);
    expect(capabilities.analysisHeight, 640);
    expect(capabilities.fps, 21.0);
  });
}
