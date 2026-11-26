import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Message keys of an ARB file, without its metadata (`@@locale`, `@key`).
Set<String> messageKeys(String language) {
  final arb = jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync()) as Map<String, dynamic>;
  return arb.keys.where((key) => !key.startsWith('@')).toSet();
}

void main() {
  test('the app is translated into exactly es, en and pt (RNF-14)', () {
    final languages = Directory('lib/l10n')
        .listSync()
        .map((file) => RegExp(r'app_(\w+)\.arb$').firstMatch(file.path)?.group(1))
        .nonNulls
        .toSet();

    expect(languages, {'es', 'en', 'pt'});
  });

  test('the en and pt texts have exactly the keys of the Spanish template', () {
    final template = messageKeys('es');

    expect(template, isNotEmpty);
    expect(messageKeys('en'), template);
    expect(messageKeys('pt'), template);
  });
}
