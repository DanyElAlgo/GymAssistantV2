import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/analysis_event.dart';
import 'package:gymassistant/analysis/body.dart';

import 'fakes.dart';

/// Opens P08 for the lat pulldown from P06, through the camera guide.
Future<void> openFraming(WidgetTester tester) async {
  await tester.tap(find.text('Jalón al pecho'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Listo, abrir cámara'));
  await tester.pumpAndSettle();
}

final cameraView = find.byKey(FakeAnalysisBridge.cameraViewKey);

final startButton = find.widgetWithText(FilledButton, 'Empezar');

bool isEnabled(WidgetTester tester, Finder button) => tester.widget<FilledButton>(button).onPressed != null;

FramingEvent framing({
  bool personDetected = true,
  bool isValid = false,
  List<Joint> missing = const [],
  Side? side,
}) =>
    FramingEvent(emittedAtMs: 0, personDetected: personDetected, isValid: isValid, missingJoints: missing, measuredSide: side);
