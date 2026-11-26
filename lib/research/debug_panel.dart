import 'dart:async';

import 'package:flutter/material.dart';

import '../analysis/analysis_event.dart';
import '../analysis/performance_stats.dart';
import '../l10n/app_localizations.dart';

/// Research build only (ADR-0013): the measured fps and the median latency from frame capture
/// to Flutter, to check RNF-01 and RNF-02 while testing. The measured side and the primary
/// angle join it with SCRUM-50 and SCRUM-51.
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key, required this.events, required this.wallClockMs});

  final Stream<AnalysisEvent> events;
  final int Function() wallClockMs;

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final _stats = PerformanceStats();
  late final StreamSubscription<AnalysisEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.events.listen((event) {
      if (event is PerformanceEvent) {
        // Read the clock on arrival, before rebuilding, so the delivery time is not inflated.
        final receivedAtMs = widget.wallClockMs();
        setState(() => _stats.add(event, receivedAtMs: receivedAtMs));
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fps = _stats.fps;
    if (fps == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final latency = _stats.medianLatencyMs;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.debugPanelFps(fps)),
              Text(latency == null ? l10n.debugPanelLatencyPending : l10n.debugPanelLatency(latency)),
            ],
          ),
        ),
      ),
    );
  }
}
