import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/main.dart';

void main() {
  testWidgets('the app starts', (tester) async {
    await tester.pumpWidget(const GymAssistantApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
