import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/preferences/preferences_service.dart';
import 'package:gymassistant/training/exercise.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('the camera guide shows until the user skips it, one exercise at a time', () async {
    final preferences = SharedPreferencesService();

    expect(await preferences.cameraGuideSkipped(Exercise.legPress45), isFalse);

    await preferences.setCameraGuideSkipped(Exercise.legPress45, skipped: true);

    expect(await preferences.cameraGuideSkipped(Exercise.legPress45), isTrue);
    expect(await preferences.cameraGuideSkipped(Exercise.latPulldown), isFalse);

    await preferences.setCameraGuideSkipped(Exercise.legPress45, skipped: false);

    expect(await preferences.cameraGuideSkipped(Exercise.legPress45), isFalse);
  });

  test('uses the keys of the preference table, with text values (Diseño §12.3)', () async {
    await SharedPreferencesService().setCameraGuideSkipped(Exercise.legExtension, skipped: true);

    expect(await SharedPreferencesAsync().getString('guide_seen_LEG_EXTENSION'), 'true');
  });
}
