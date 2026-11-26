import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/analysis_bridge.dart';
import 'package:gymassistant/analysis/body.dart';
import 'package:gymassistant/analysis/rules_version.dart';
import 'package:gymassistant/training/exercise.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';
import '../support/training.dart';

final finishButton = find.widgetWithText(FilledButton, 'Terminar');

/// Opens P08 for the lat pulldown, waits for valid framing and starts the set (P09).
Future<void> openSet(WidgetTester tester, FakeAnalysisBridge bridge) async {
  await openFraming(tester);
  bridge.emit(framing(isValid: true, side: Side.left));
  await tester.pumpAndSettle();
  await tester.tap(startButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starting the set opens P09 with the camera and a finish button, and starts the set with the active rules',
      (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);

    await openSet(tester, bridge);

    expect(cameraView, findsOneWidget);
    expect(finishButton, findsOneWidget);
    expect(startButton, findsNothing);
    expect(bridge.startSetCalls, [(exercise: Exercise.latPulldown, silentMode: false, rulesVersion: activeRulesVersion)]);
    expect(bridge.stopSetCalls, 0);
  });

  testWidgets('the camera stays on from P08 to P09, so the framing and its measured side carry over', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);

    await openSet(tester, bridge);

    expect(bridge.releaseCameraCalls, 0);
    // P09's camera view takes over the running camera instead of asking for a new framing check.
    expect(bridge.checkFramingCalls, hasLength(1));
  });

  testWidgets('Terminar stops the set, releases the camera and goes back to the exercise list', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);
    await openSet(tester, bridge);

    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(bridge.stopSetCalls, 1);
    expect(bridge.releaseCameraCalls, 1);
    expect(cameraView, findsNothing);
    expect(find.text('Elige un ejercicio'), findsOneWidget);
  });

  testWidgets('Android back also ends the set and goes back to the exercise list', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);
    await openSet(tester, bridge);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(bridge.stopSetCalls, 1);
    expect(bridge.releaseCameraCalls, 1);
    expect(find.text('Elige un ejercicio'), findsOneWidget);
  });

  testWidgets('P09 warns when framing is lost during the set, and the warning goes once it is back', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);
    await openSet(tester, bridge);

    expect(find.textContaining('Fuera de la imagen'), findsNothing);

    bridge.emit(framing(missing: [Joint.wrist], side: Side.left));
    await tester.pumpAndSettle();
    expect(find.text('Fuera de la imagen: muñeca'), findsOneWidget);

    bridge.emit(framing(personDetected: false, missing: [Joint.shoulder, Joint.elbow, Joint.wrist], side: Side.left));
    await tester.pumpAndSettle();
    expect(find.text('No veo a nadie. Ponte frente a la cámara.'), findsOneWidget);

    bridge.emit(framing(isValid: true, side: Side.left));
    await tester.pumpAndSettle();
    expect(find.textContaining('Fuera de la imagen'), findsNothing);
    expect(find.textContaining('No veo a nadie'), findsNothing);
    expect(finishButton, findsOneWidget);
  });

  testWidgets('a set the native side refuses stays out of P09 and explains that the analysis cannot start',
      (tester) async {
    final bridge = FakeAnalysisBridge()..startSetError = const AnalysisException(AnalysisErrorCode.invalidConfig);
    await pumpApp(tester, bridge: bridge);

    await openSet(tester, bridge);

    expect(find.textContaining('configuración del análisis'), findsOneWidget);
    expect(finishButton, findsNothing);
  });

  testWidgets('a second tap on the start button starts only one set', (tester) async {
    final bridge = FakeAnalysisBridge();
    await pumpApp(tester, bridge: bridge);
    await openFraming(tester);
    bridge.emit(framing(isValid: true, side: Side.left));
    await tester.pumpAndSettle();

    await tester.tap(startButton);
    await tester.tap(startButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(bridge.startSetCalls, hasLength(1));
  });
}
