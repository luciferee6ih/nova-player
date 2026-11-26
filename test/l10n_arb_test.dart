import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every translation must keep the template's keys and placeholders, so a
/// missing or renamed `{placeholder}` can't break a screen at runtime.
void main() {
  final dir = Directory('lib/l10n');
  final template =
      json.decode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final messageKeys = template.keys.where((k) => !k.startsWith('@')).toSet();
  final placeholder = RegExp(r'\{(\w+)[,}]');

  Set<String> placeholders(String s) =>
      placeholder.allMatches(s).map((m) => m.group(1)!).toSet();

  final arbs = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  test('Persian translation exists', () {
    expect(arbs.map((f) => f.uri.pathSegments.last), contains('app_fa.arb'));
  });

  test('Persian has every message with the same placeholders', () {
    final fa =
        json.decode(File('lib/l10n/app_fa.arb').readAsStringSync())
            as Map<String, dynamic>;
    expect(fa['@@locale'], 'fa');
    for (final key in messageKeys) {
      expect(fa.containsKey(key), isTrue, reason: 'missing $key');
      expect(
        placeholders(fa[key] as String),
        placeholders(template[key] as String),
        reason: 'placeholders differ in $key',
      );
    }
  });

  for (final file in arbs) {
    test('${file.uri.pathSegments.last} is valid and has no unknown keys', () {
      final arb =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in arb.keys.where((k) => !k.startsWith('@'))) {
        expect(messageKeys, contains(key), reason: 'unknown key $key');
      }
    });
  }

  test('every translation has the NOVA branding keys', () {
    for (final file in arbs) {
      final arb =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in ['aboutNovaPlayer', 'novaPlayerVersion', 'developerLabel']) {
        expect(arb.containsKey(key), isTrue, reason: '${file.path}: $key');
      }
      expect(arb['novaAnalyze'], 'NOVA Analyze', reason: file.path);
    }
  });
}
