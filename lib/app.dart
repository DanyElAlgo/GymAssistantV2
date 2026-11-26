import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';

/// Root widget. Expects a [ProviderScope] above it.
///
/// The app follows the phone's language among es, en and pt, and falls back to
/// Spanish (RNF-14). Material 3 with a dark theme (Diseño §9.2).
class GymAssistantApp extends ConsumerWidget {
  const GymAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: _supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

/// The generated list is alphabetical; Spanish goes first because Flutter
/// falls back to the first supported locale when the phone's isn't supported.
final _supportedLocales = [
  const Locale('es'),
  ...AppLocalizations.supportedLocales.where((locale) => locale.languageCode != 'es'),
];
