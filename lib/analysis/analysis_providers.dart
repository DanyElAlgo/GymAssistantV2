import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analysis_bridge.dart';
import 'camera_permission.dart';
import 'channel_analysis_bridge.dart';

/// The native analysis; tests override it with a fake.
final analysisBridgeProvider = Provider<AnalysisBridge>((ref) => ChannelAnalysisBridge());

final cameraPermissionProvider = Provider<CameraPermission>((ref) => const PluginCameraPermission());

/// Wall-clock milliseconds since the epoch, the clock the native events are stamped with.
final wallClockMsProvider = Provider<int Function()>((ref) => () => DateTime.now().millisecondsSinceEpoch);
