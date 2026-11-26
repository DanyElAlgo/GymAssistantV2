import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/analysis_event.dart';
import 'debug_panel.dart';

/// Whether this is the research build (ADR-0013). A compile-time constant, so the Play build's
/// compiler drops every research-only branch, and the code behind it, from the binary.
const isResearchBuild = appFlavor == 'research';

/// Builds the research debug panel from the analysis events and the wall clock.
typedef DebugPanelBuilder = Widget Function(Stream<AnalysisEvent> events, int Function() wallClockMs);

/// The debug panel in the research build; null in the Play build, which does not contain it.
final debugPanelProvider = Provider<DebugPanelBuilder?>(
  (ref) => isResearchBuild ? (events, wallClockMs) => DebugPanel(events: events, wallClockMs: wallClockMs) : null,
);
