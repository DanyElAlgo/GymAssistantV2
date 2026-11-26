import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/analysis_bridge.dart';
import 'package:gymassistant/analysis/analysis_event.dart';
import 'package:gymassistant/analysis/camera_permission.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

/// Opens P08 for the lat pulldown from P06.
Future<void> openFraming(WidgetTester tester) async {
  await tester.tap(find.text('Jalón al pecho'));
  await tester.pumpAndSettle();
}

final cameraView = find.byKey(FakeAnalysisBridge.cameraViewKey);

void main() {
  testWidgets('explains why it needs the camera before asking for it, then shows the camera', (tester) async {
    final bridge = FakeAnalysisBridge();
    final permission = FakeCameraPermission(current: CameraPermissionStatus.denied);
    await pumpApp(tester, bridge: bridge, permission: permission);

    await openFraming(tester);

    expect(find.textContaining('nunca se guardan ni se envían'), findsOneWidget);
    expect(permission.requests, 0);
    expect(cameraView, findsNothing);

    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();

    expect(permission.requests, 1);
    expect(cameraView, findsOneWidget);
    expect(bridge.startCameraCalls, 1);
  });

  testWidgets('a denied permission leads to the system settings, and the camera opens once it is granted there',
      (tester) async {
    final bridge = FakeAnalysisBridge();
    final permission = FakeCameraPermission(current: CameraPermissionStatus.denied, answer: CameraPermissionStatus.denied);
    await pumpApp(tester, bridge: bridge, permission: permission);
    await openFraming(tester);

    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();

    expect(cameraView, findsNothing);
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    expect(permission.settingsOpened, 1);

    // The user grants it in the settings and comes back to the app.
    permission.current = CameraPermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(cameraView, findsOneWidget);
    expect(bridge.startCameraCalls, 1);
  });

  testWidgets('closing the permission dialog with a denial stays on the settings screen', (tester) async {
    final permission = FakeCameraPermission(current: CameraPermissionStatus.denied, answer: CameraPermissionStatus.denied);
    await pumpApp(tester, permission: permission);
    await openFraming(tester);

    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();
    // Android resumes the app when the system dialog closes.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Abrir ajustes'), findsOneWidget);
  });

  testWidgets('a permission denied for good goes straight to the settings screen', (tester) async {
    final permission = FakeCameraPermission(current: CameraPermissionStatus.permanentlyDenied);
    await pumpApp(tester, permission: permission);

    await openFraming(tester);

    expect(find.text('Abrir ajustes'), findsOneWidget);
    expect(find.text('Permitir cámara'), findsNothing);
  });

  testWidgets('CAMERA_PERMISSION from the native side shows the settings screen', (tester) async {
    final bridge = FakeAnalysisBridge()..startCameraError = const AnalysisException(AnalysisErrorCode.cameraPermission);
    await pumpApp(tester, bridge: bridge);

    await openFraming(tester);

    expect(find.text('Abrir ajustes'), findsOneWidget);
    expect(cameraView, findsNothing);
  });

  testWidgets('a camera that cannot open offers to try again', (tester) async {
    final bridge = FakeAnalysisBridge()..startCameraError = const AnalysisException(AnalysisErrorCode.cameraInUse);
    await pumpApp(tester, bridge: bridge);
    await openFraming(tester);

    bridge.startCameraError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(cameraView, findsOneWidget);
    expect(bridge.startCameraCalls, 2);
  });

  testWidgets('with permission granted it shows the camera, and releases it when leaving P08', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);

    await openFraming(tester);

    expect(cameraView, findsOneWidget);
    expect(bridge.startCameraCalls, 1);
    expect(bridge.releaseCameraCalls, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(bridge.releaseCameraCalls, 1);
  });

  testWidgets('the research build shows the fps and the median latency up to Flutter', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge, researchBuild: true, nowMs: 50012);
    await openFraming(tester);

    bridge.emit(const PerformanceEvent(emittedAtMs: 50000, fps: 23.5, captureToAnalysisMs: 80));
    await tester.pumpAndSettle();

    expect(find.text('23,5 fps'), findsOneWidget);
    expect(find.text('Latencia mediana: 92 ms'), findsOneWidget);
  });

  testWidgets('the Play build has no debug panel', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge, nowMs: 50012);
    await openFraming(tester);

    bridge.emit(const PerformanceEvent(emittedAtMs: 50000, fps: 23.5, captureToAnalysisMs: 80));
    await tester.pumpAndSettle();

    expect(find.textContaining('fps'), findsNothing);
    expect(find.textContaining('Latencia'), findsNothing);
  });
}
