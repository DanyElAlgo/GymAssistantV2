import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/analysis_providers.dart';
import 'package:gymassistant/app.dart';
import 'package:gymassistant/research/debug_panel.dart';
import 'package:gymassistant/research/research_build.dart';

import 'fakes.dart';

/// Starts the app as a phone set to [locale] would, with fakes instead of native code.
/// [researchBuild] adds what only the research build contains; [nowMs] is the wall clock the
/// app reads.
Future<void> pumpApp(
  WidgetTester tester, {
  Locale locale = const Locale('es'),
  FakeAnalysisBridge? bridge,
  FakeCameraPermission? permission,
  bool researchBuild = false,
  int nowMs = 0,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      analysisBridgeProvider.overrideWithValue(bridge ?? FakeAnalysisBridge()),
      cameraPermissionProvider.overrideWithValue(permission ?? FakeCameraPermission()),
      debugPanelProvider.overrideWithValue(
        researchBuild ? (events, wallClockMs) => DebugPanel(events: events, wallClockMs: wallClockMs) : null,
      ),
      wallClockMsProvider.overrideWithValue(() => nowMs),
    ],
    child: const GymAssistantApp(),
  ));
  await tester.pumpAndSettle();
}
