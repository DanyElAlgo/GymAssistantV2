import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../training/exercise.dart';

/// The user's options on this phone (Diseño §4.2, `PreferencesService`).
///
/// Values are stored as text under the keys of the `preference` table (Diseño §12.3), so they
/// can move to the local database unchanged when it arrives in F2.
abstract interface class PreferencesService {
  /// Whether the user asked not to see the camera guide (P07) for [exercise] again.
  Future<bool> cameraGuideSkipped(Exercise exercise);

  Future<void> setCameraGuideSkipped(Exercise exercise, {required bool skipped});
}

/// [PreferencesService] over the platform's key-value store.
class SharedPreferencesService implements PreferencesService {
  SharedPreferencesService([SharedPreferencesAsync? store]) : _store = store ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _store;

  static String _guideSeenKey(Exercise exercise) => 'guide_seen_${exercise.code}';

  @override
  Future<bool> cameraGuideSkipped(Exercise exercise) async =>
      await _store.getString(_guideSeenKey(exercise)) == 'true';

  @override
  Future<void> setCameraGuideSkipped(Exercise exercise, {required bool skipped}) =>
      _store.setString(_guideSeenKey(exercise), '$skipped');
}

/// The phone's preferences; tests override it with a fake.
final preferencesServiceProvider = Provider<PreferencesService>((ref) => SharedPreferencesService());
