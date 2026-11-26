import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymassistant/analysis/rules_version.dart';

void main() {
  test('the active rules version is a file the app ships', () {
    expect(File('assets/rules/rules_v$activeRulesVersion.json').existsSync(), isTrue);
  });
}
