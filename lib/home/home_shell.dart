import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// P05, Inicio: the container with the bottom bar.
///
/// Every tab an anonymous user will have is shown, but only Train is enabled
/// until Progress, Goals and Profile exist (F2 and F3).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.fitness_center), label: l10n.tabTrain),
          NavigationDestination(icon: const Icon(Icons.insights), label: l10n.tabProgress, enabled: false),
          NavigationDestination(icon: const Icon(Icons.flag_outlined), label: l10n.tabGoals, enabled: false),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.tabProfile, enabled: false),
        ],
      ),
    );
  }
}
