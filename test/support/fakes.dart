import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gymassistant/analysis/analysis_bridge.dart';
import 'package:gymassistant/analysis/analysis_event.dart';
import 'package:gymassistant/analysis/camera_permission.dart';
import 'package:gymassistant/preferences/preferences_service.dart';
import 'package:gymassistant/training/exercise.dart';

/// An [AnalysisBridge] without native code: it records the commands it gets and emits the
/// events a test hands it.
class FakeAnalysisBridge implements AnalysisBridge {
  /// Marks the stand-in for the native camera view.
  static const cameraViewKey = Key('fake-camera-view');

  final _events = StreamController<AnalysisEvent>.broadcast();

  int startCameraCalls = 0;
  int releaseCameraCalls = 0;

  /// The exercises [checkFraming] was asked for, in order.
  final checkFramingCalls = <Exercise>[];

  /// Thrown by the next [startCamera], as the native side would.
  AnalysisException? startCameraError;

  /// Thrown by [checkFraming], as the native side would.
  AnalysisException? checkFramingError;

  void emit(AnalysisEvent event) => _events.add(event);

  @override
  Stream<AnalysisEvent> get events => _events.stream;

  @override
  Widget cameraView({required VoidCallback onCreated}) => _FakeCameraView(onCreated: onCreated);

  @override
  Future<void> startCamera() async {
    startCameraCalls++;
    final error = startCameraError;
    if (error != null) throw error;
  }

  @override
  Future<void> releaseCamera() async => releaseCameraCalls++;

  @override
  Future<AnalysisCapabilities> capabilities() async => const AnalysisCapabilities(modelVariant: ModelVariant.full);

  @override
  Future<void> checkFraming(Exercise exercise) async {
    checkFramingCalls.add(exercise);
    final error = checkFramingError;
    if (error != null) throw error;
  }

  @override
  Future<void> startSet({required Exercise exercise, required bool silentMode, required String rulesVersion}) async {}

  @override
  Future<SetSummary> stopSet() async => const SetSummary(totalRepetitions: 0, correctRepetitions: 0);
}

class _FakeCameraView extends StatefulWidget {
  const _FakeCameraView({required this.onCreated});

  final VoidCallback onCreated;

  @override
  State<_FakeCameraView> createState() => _FakeCameraViewState();
}

class _FakeCameraViewState extends State<_FakeCameraView> {
  @override
  void initState() {
    super.initState();
    // Like a platform view, it exists only after the frame that inserts it.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onCreated());
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand(key: FakeAnalysisBridge.cameraViewKey);
}

/// A [CameraPermission] whose answers the test sets.
class FakeCameraPermission implements CameraPermission {
  FakeCameraPermission({this.current = CameraPermissionStatus.granted, this.answer = CameraPermissionStatus.granted});

  /// What [status] reports.
  CameraPermissionStatus current;

  /// What the user answers when [request] shows the system dialog.
  CameraPermissionStatus answer;

  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<CameraPermissionStatus> status() async => current;

  @override
  Future<CameraPermissionStatus> request() async {
    requests++;
    return current = answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

/// A [PreferencesService] kept in memory. Share one between two `pumpApp` calls to reopen the
/// app on the same phone.
class FakePreferencesService implements PreferencesService {
  final skippedGuides = <Exercise>{};

  @override
  Future<bool> cameraGuideSkipped(Exercise exercise) async => skippedGuides.contains(exercise);

  @override
  Future<void> setCameraGuideSkipped(Exercise exercise, {required bool skipped}) async {
    if (skipped) {
      skippedGuides.add(exercise);
    } else {
      skippedGuides.remove(exercise);
    }
  }
}
