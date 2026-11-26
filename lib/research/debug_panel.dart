import 'dart:async';

import 'package:flutter/material.dart';

import '../analysis/analysis_event.dart';
import '../analysis/body.dart';
import '../analysis/performance_stats.dart';
import '../l10n/app_localizations.dart';
import '../training/body_presentation.dart';

/// Research build only (ADR-0013): the measured fps and the median latency from frame capture
/// to Flutter, to check RNF-01 and RNF-02 while testing, and the measured side (ADR-0012).
class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key, required this.events, required this.wallClockMs});

  final Stream<AnalysisEvent> events;
  final int Function() wallClockMs;

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final _stats = PerformanceStats();

  /// The latest framing result, for the measured side; null until the first one.
  FramingEvent? _framing;
  late final StreamSubscription<AnalysisEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.events.listen((event) {
      if (event is PerformanceEvent) {
        // Read the clock on arrival, before rebuilding, so the delivery time is not inflated.
        final receivedAtMs = widget.wallClockMs();
        setState(() => _stats.add(event, receivedAtMs: receivedAtMs));
      } else if (event is FramingEvent) {
        setState(() => _framing = event);
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
    final framing = _framing;
    if (fps == null && framing == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final latency = _stats.medianLatencyMs;
    final Side? side = framing?.measuredSide;
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
              if (fps != null) ...[
                Text(l10n.debugPanelFps(fps)),
                Text(latency == null ? l10n.debugPanelLatencyPending : l10n.debugPanelLatency(latency)),
              ],
              Text(side == null ? l10n.debugPanelSidePending : l10n.debugPanelSide(side.localizedName(l10n))),
            ],
          ),
        ),
      ),
    );
  }
}
