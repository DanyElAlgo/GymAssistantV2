import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/training/camera_guide_screen.dart';
import 'package:gymassistant/training/exercise.dart';
import 'package:gymassistant/training/framing_screen.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

const legPress = 'Prensa de piernas a 45°';
const latPulldown = 'Jalón al pecho';
const legExtension = 'Extensión de cuádriceps';

Future<void> tapAndSettle(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

final guide = find.byType(CameraGuideScreen);
final framing = find.byType(FramingScreen);

void main() {
  group('shows the camera position and distance of the chosen exercise (HU-09)', () {
    testWidgets('leg press: oblique, 30° from the side', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, legPress);

      expect(find.text('Coloca el teléfono'), findsOneWidget);
      expect(find.text('En diagonal, a 30° del lateral: entre tu costado y tu frente.'), findsOneWidget);
      expect(find.textContaining('De lado, a 0°'), findsNothing);
      expect(find.text('A unos 2 m de ti, para que se vea todo tu cuerpo.'), findsOneWidget);
      expect(find.text('A la altura de tu pecho.'), findsNothing);
    });

    for (final exercise in [latPulldown, legExtension]) {
      testWidgets('$exercise: side-on, 0°', (tester) async {
        await pumpApp(tester);
        await tapAndSettle(tester, exercise);

        expect(find.text('De lado, a 0°: el teléfono mira de frente a tu costado, sin diagonal.'), findsOneWidget);
        expect(find.textContaining('30°'), findsNothing);
        expect(find.text('A unos 2 m de ti, para que se vea todo tu cuerpo.'), findsOneWidget);
      });
    }

    testWidgets('lat pulldown: at chest height', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, latPulldown);

      expect(find.text('A la altura de tu pecho.'), findsOneWidget);
    });

    testWidgets('in the phone language', (tester) async {
      await pumpApp(tester, locale: const Locale('en', 'US'));
      await tapAndSettle(tester, '45° leg press');

      expect(find.text('At a diagonal, 30° from the side: between your side and your front.'), findsOneWidget);
      expect(find.text("Don't show again"), findsOneWidget);
      expect(find.text('Ready, open camera'), findsOneWidget);
    });
  });

  testWidgets('«no volver a mostrar» skips the guide for that exercise the next time', (tester) async {
    final preferences = FakePreferencesService();
    await pumpApp(tester, preferences: preferences);
    await tapAndSettle(tester, legPress);

    await tapAndSettle(tester, 'No volver a mostrar');
    expect(preferences.skippedGuides, {Exercise.legPress45});

    await back(tester);
    await tapAndSettle(tester, legPress);

    expect(guide, findsNothing);
    expect(tester.widget<FramingScreen>(framing).exercise, Exercise.legPress45);

    // Back from P08 returns to P06, the screen the user came from.
    await back(tester);
    expect(framing, findsNothing);
    expect(find.text('Elige un ejercicio'), findsOneWidget);

    // The other exercises still show their guide.
    await tapAndSettle(tester, legExtension);
    expect(tester.widget<CameraGuideScreen>(guide).exercise, Exercise.legExtension);
  });

  testWidgets('the choice survives reopening the app', (tester) async {
    final preferences = FakePreferencesService();
    await pumpApp(tester, preferences: preferences);
    await tapAndSettle(tester, latPulldown);
    await tapAndSettle(tester, 'No volver a mostrar');

    // Close the app, then open it again on the same phone.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, preferences: preferences);
    await tapAndSettle(tester, latPulldown);

    expect(guide, findsNothing);
    expect(tester.widget<FramingScreen>(framing).exercise, Exercise.latPulldown);
  });

  testWidgets('unticking the box keeps showing the guide', (tester) async {
    final preferences = FakePreferencesService();
    await pumpApp(tester, preferences: preferences);
    await tapAndSettle(tester, latPulldown);

    await tapAndSettle(tester, 'No volver a mostrar');
    await tapAndSettle(tester, 'No volver a mostrar');
    expect(preferences.skippedGuides, isEmpty);

    await back(tester);
    await tapAndSettle(tester, latPulldown);

    expect(guide, findsOneWidget);
  });

  testWidgets('stays in portrait from P07 through P08, and unlocks back on P06', (tester) async {
    final orientations = <Object?>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') orientations.add(call.arguments);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    const portrait = ['DeviceOrientation.portraitUp'];
    await pumpApp(tester);

    await tapAndSettle(tester, legPress);
    expect(orientations.last, portrait);

    await tapAndSettle(tester, 'Listo, abrir cámara');
    expect(orientations.last, portrait);

    // Closing P08 must not unlock P07 underneath it.
    await back(tester);
    expect(guide, findsOneWidget);
    expect(orientations.last, portrait);

    await back(tester);
    expect(orientations.last, isEmpty);
  });
}
