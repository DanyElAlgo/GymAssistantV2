import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analysis/analysis_bridge.dart';
import '../analysis/analysis_providers.dart';
import '../analysis/camera_permission.dart';
import '../l10n/app_localizations.dart';
import '../research/research_build.dart';
import 'exercise.dart';
import 'exercise_presentation.dart';

/// P08, Verificar encuadre: the user sees themself in the front camera, as in a mirror, with
/// the skeleton on top (HU-08). The framing check and its button arrive with SCRUM-50.
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

enum _Stage { checkingPermission, explainingPermission, permissionDenied, camera, cameraUnavailable }

class _FramingScreenState extends ConsumerState<FramingScreen> with WidgetsBindingObserver {
  late final AnalysisBridge _bridge;
  late final CameraPermission _permission;
  var _stage = _Stage.checkingPermission;
  var _cameraStarted = false;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(analysisBridgeProvider);
    _permission = ref.read(cameraPermissionProvider);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([]);
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
    try {
      await _bridge.startCamera();
      _cameraStarted = true;
    } on AnalysisException catch (e) {
      if (!mounted) return;
      setState(() => _stage =
          e.code == AnalysisErrorCode.cameraPermission ? _Stage.permissionDenied : _Stage.cameraUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
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
        _Stage.camera => Stack(
            fit: StackFit.expand,
            children: [
              _bridge.cameraView(onCreated: _startCamera),
              if (ref.watch(debugPanelProvider) case final debugPanel?)
                Positioned(top: 16, left: 16, child: debugPanel(_bridge.events, ref.watch(wallClockMsProvider))),
            ],
          ),
      },
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
