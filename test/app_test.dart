import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/training/exercise.dart';
import 'package:gymassistant/training/framing_screen.dart';

import 'support/test_app.dart';

/// Fails unless the picture found by [finder] exists in the bundle and parses.
/// Widget tests never finish loading SVGs on their own, so a missing file would
/// otherwise go unnoticed.
Future<void> expectSvgLoads(WidgetTester tester, Finder finder) async {
  final loader = tester.widget<SvgPicture>(finder).bytesLoader;
  final picture = await tester.runAsync(() => vg.loadPicture(loader, null));
  expect(picture, isNotNull);
  picture!.picture.dispose();
}

void main() {
  testWidgets('opens without an account on the Train tab, the only tab enabled', (tester) async {
    await pumpApp(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
    final tabs = bar.destinations.cast<NavigationDestination>();
    expect(tabs.map((tab) => tab.label), ['Entrenar', 'Progreso', 'Metas', 'Perfil']);
    expect(tabs.map((tab) => tab.enabled), [true, false, false, false]);
    expect(find.text('Elige un ejercicio'), findsOneWidget);
  });

  testWidgets('lists the three exercises, each with its illustration', (tester) async {
    await pumpApp(tester);

    for (final name in ['Prensa de piernas a 45°', 'Jalón al pecho', 'Extensión de cuádriceps']) {
      final option = find.ancestor(of: find.text(name), matching: find.byType(Card));
      expect(option, findsOneWidget, reason: name);
      final illustration = find.descendant(of: option, matching: find.byType(SvgPicture));
      expect(illustration, findsOneWidget, reason: name);
      await expectSvgLoads(tester, illustration);
    }
  });

  group('follows the phone language (RNF-14)', () {
    const cases = [
      (Locale('en', 'US'), 'Choose an exercise', 'Lat pulldown', 'Train'),
      (Locale('pt', 'BR'), 'Escolha um exercício', 'Puxada frontal', 'Treinar'),
      (Locale('es', 'BO'), 'Elige un ejercicio', 'Jalón al pecho', 'Entrenar'),
      // Any other language falls back to Spanish.
      (Locale('fr', 'FR'), 'Elige un ejercicio', 'Jalón al pecho', 'Entrenar'),
    ];
    for (final (locale, title, exercise, tab) in cases) {
      testWidgets('$locale', (tester) async {
        await pumpApp(tester, locale: locale);

        expect(find.text(title), findsOneWidget);
        expect(find.text(exercise), findsOneWidget);
        expect(find.text(tab), findsOneWidget);
      });
    }
  });

  // Until the camera guide (P07) exists, choosing goes straight to P08.
  testWidgets('choosing an exercise opens its framing check without the bottom bar', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Jalón al pecho'));
    await tester.pumpAndSettle();

    expect(tester.widget<FramingScreen>(find.byType(FramingScreen)).exercise, Exercise.latPulldown);
    expect(find.byType(NavigationBar), findsNothing);

    // Android's Back button (Diseño §10.1).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(FramingScreen), findsNothing);
    expect(find.text('Elige un ejercicio'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
