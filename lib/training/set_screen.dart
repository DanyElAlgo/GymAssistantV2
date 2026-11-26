import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../analysis/analysis_bridge.dart';
import '../analysis/analysis_event.dart';
import '../analysis/analysis_providers.dart';
import '../l10n/app_localizations.dart';
import '../research/research_build.dart';
import '../routing/app_router.dart';
import 'body_presentation.dart';
import 'exercise.dart';
import 'exercise_presentation.dart';
import 'portrait_lock.dart';

/// P09, Serie en curso, in its F1 form (SCRUM-51): the camera with the skeleton and a finish
/// button, without a counter yet. P08 starts the set and leaves the camera running, and this
/// screen takes it over, so the measured side chosen there stays fixed (ADR-0012); the screen
/// warns when framing is lost.
///
/// Finishing, or going back, stops the set and returns to P06 until P10 and the discard dialog
/// arrive in F2. The camera is released when the screen closes.
class SetScreen extends ConsumerStatefulWidget {
  const SetScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<SetScreen> createState() => _SetScreenState();
}

enum _Stage { camera, cameraUnavailable }

class _SetScreenState extends ConsumerState<SetScreen> {
  late final AnalysisBridge _bridge;
  late final StreamSubscription<AnalysisEvent> _events;
  var _stage = _Stage.camera;
  var _finishing = false;

  /// The latest framing result during the set; null while nothing has changed since P08.
  FramingEvent? _framing;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(analysisBridgeProvider);
    _events = _bridge.events.listen((event) {
      if (event is FramingEvent && mounted) setState(() => _framing = event);
    });
  }

  @override
  void dispose() {
    _events.cancel();
    _bridge.releaseCamera();
    super.dispose();
  }

  /// The camera is already running: this moves its preview into this screen's view.
  Future<void> _takeOverCamera() async {
    try {
      await _bridge.startCamera();
    } on AnalysisException {
      if (mounted) setState(() => _stage = _Stage.cameraUnavailable);
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    try {
      await _bridge.stopSet();
    } on AnalysisException {
      // The native side already has no set running: nothing is lost by leaving.
    }
    if (mounted) context.go(AppRoutes.train);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PortraitLock(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _finish();
        },
        child: Scaffold(
          appBar: AppBar(title: Text(widget.exercise.localizedName(l10n))),
          body: switch (_stage) {
            _Stage.cameraUnavailable => _Message(l10n.cameraUnavailable),
            _Stage.camera => Stack(
                fit: StackFit.expand,
                children: [
                  _bridge.cameraView(onCreated: _takeOverCamera),
                  if (ref.watch(debugPanelProvider) case final debugPanel?)
                    Positioned(top: 16, left: 16, child: debugPanel(_bridge.events, ref.watch(wallClockMsProvider))),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.all(16),
                      child: _SetControls(warning: _framing?.problem(l10n), onFinish: _finish),
                    ),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}

/// The framing warning, if any, and the finish button.
class _SetControls extends StatelessWidget {
  const _SetControls({required this.warning, required this.onFinish});

  final String? warning;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final warning = this.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (warning != null) ...[
              Text(warning, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            FilledButton(onPressed: onFinish, child: Text(l10n.finishSet)),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}
