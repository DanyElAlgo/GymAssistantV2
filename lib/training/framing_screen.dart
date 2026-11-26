import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/analysis_bridge.dart';
import '../analysis/analysis_event.dart';
import '../analysis/analysis_providers.dart';
import '../analysis/camera_permission.dart';
import '../analysis/rules_version.dart';
import '../l10n/app_localizations.dart';
import '../research/research_build.dart';
import 'body_presentation.dart';
import 'exercise.dart';
import 'exercise_presentation.dart';
import 'portrait_lock.dart';

/// P08, Verificar encuadre: the user sees themself in the front camera, as in a mirror, with
/// the skeleton on top (HU-08). The screen says which body parts the camera does not see, or
/// that it sees no one, and the start button stays locked until framing is valid (HU-10).
///
/// The camera permission is asked with an explanation first; if it is denied, the screen
/// leads to the system settings. The screen stays in portrait, and the camera is released
/// when the user leaves.
class FramingScreen extends ConsumerStatefulWidget {
  const FramingScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<FramingScreen> createState() => _FramingScreenState();
}

enum _Stage { checkingPermission, explainingPermission, permissionDenied, camera, cameraUnavailable, analysisUnavailable }

class _FramingScreenState extends ConsumerState<FramingScreen> with WidgetsBindingObserver {
  late final AnalysisBridge _bridge;
  late final CameraPermission _permission;
  late final StreamSubscription<AnalysisEvent> _events;
  var _stage = _Stage.checkingPermission;
  var _cameraStarted = false;

  /// The latest framing result; null until the first one arrives.
  FramingEvent? _framing;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(analysisBridgeProvider);
    _permission = ref.read(cameraPermissionProvider);
    _events = _bridge.events.listen((event) {
      if (event is FramingEvent && mounted) setState(() => _framing = event);
    });
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    _events.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_cameraStarted) _bridge.releaseCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the system settings, where the user may have granted the permission. Closing
    // the permission dialog resumes the app too, so anything short of a grant stays put.
    if (state == AppLifecycleState.resumed && _stage == _Stage.permissionDenied) _recheckGrant();
  }

  Future<void> _recheckGrant() async {
    final status = await _permission.status();
    if (status == CameraPermissionStatus.granted) _showPermission(status, deniedStage: _Stage.permissionDenied);
  }

  Future<void> _checkPermission() async {
    final status = await _permission.status();
    _showPermission(status, deniedStage: _Stage.explainingPermission);
  }

  Future<void> _requestPermission() async {
    final status = await _permission.request();
    _showPermission(status, deniedStage: _Stage.permissionDenied);
  }

  void _showPermission(CameraPermissionStatus status, {required _Stage deniedStage}) {
    if (!mounted) return;
    setState(() => _stage = switch (status) {
          CameraPermissionStatus.granted => _Stage.camera,
          CameraPermissionStatus.permanentlyDenied => _Stage.permissionDenied,
          CameraPermissionStatus.denied => deniedStage,
        });
  }

  Future<void> _startCamera() async {
    setState(() => _framing = null);
    try {
      await _bridge.startCamera();
      _cameraStarted = true;
    } on AnalysisException catch (e) {
      if (!mounted) return;
      setState(() => _stage =
          e.code == AnalysisErrorCode.cameraPermission ? _Stage.permissionDenied : _Stage.cameraUnavailable);
      return;
    }
    try {
      await _bridge.checkFraming(exercise: widget.exercise, rulesVersion: activeRulesVersion);
    } on AnalysisException {
      // An invalid rules file, or an exercise the native side does not know: nothing to retry.
      if (mounted) setState(() => _stage = _Stage.analysisUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PortraitLock(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.exercise.localizedName(l10n))),
        body: switch (_stage) {
          _Stage.checkingPermission => const SizedBox.shrink(),
          _Stage.explainingPermission => _Notice(
              icon: Icons.videocam_outlined,
              text: l10n.cameraPermissionExplanation,
              action: l10n.cameraPermissionAllow,
              onAction: _requestPermission,
            ),
          _Stage.permissionDenied => _Notice(
              icon: Icons.videocam_off_outlined,
              text: l10n.cameraPermissionDenied,
              action: l10n.cameraPermissionOpenSettings,
              onAction: _permission.openSettings,
            ),
          _Stage.cameraUnavailable => _Notice(
              icon: Icons.videocam_off_outlined,
              text: l10n.cameraUnavailable,
              action: l10n.retry,
              onAction: () => setState(() => _stage = _Stage.camera),
            ),
          _Stage.analysisUnavailable => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.analysisConfigInvalid, textAlign: TextAlign.center),
              ),
            ),
          _Stage.camera => Stack(
              fit: StackFit.expand,
              children: [
                _bridge.cameraView(onCreated: _startCamera),
                if (ref.watch(debugPanelProvider) case final debugPanel?)
                  Positioned(top: 16, left: 16, child: debugPanel(_bridge.events, ref.watch(wallClockMsProvider))),
                // The camera fills the screen edge to edge; the card keeps clear of the system bars.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.all(16),
                    child: _FramingStatus(framing: _framing),
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

/// What the framing check says, and the start button it unlocks.
class _FramingStatus extends StatelessWidget {
  const _FramingStatus({required this.framing});

  final FramingEvent? framing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final framing = this.framing;
    final message = switch (framing) {
      null => null,
      FramingEvent(personDetected: false) => l10n.framingNoPerson,
      FramingEvent(missingJoints: final missing) when missing.isNotEmpty =>
        l10n.framingMissingJoints(missing.map((joint) => joint.localizedName(l10n)).join(', ')),
      FramingEvent(isValid: false) => l10n.framingHold,
      FramingEvent() => l10n.framingReady,
    };
    final ready = framing?.isValid ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) ...[
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            // P09 and the set arrive with SCRUM-51.
            FilledButton(onPressed: ready ? () {} : null, child: Text(l10n.startSet)),
          ],
        ),
      ),
    );
  }
}

/// A centred message with one action, for the states without a camera image.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.action, required this.onAction});

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
