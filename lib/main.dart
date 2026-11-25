import 'package:flutter/material.dart';

void main() {
  runApp(const GymAssistantApp());
}

/// Root widget. Navigation, state and localized texts arrive with the first
/// screens (SCRUM-47).
class GymAssistantApp extends StatelessWidget {
  const GymAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold());
  }
}
