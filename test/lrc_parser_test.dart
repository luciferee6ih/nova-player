import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/features/playback/domain/lyric_models.dart';

void main() {
  const total = Duration(minutes: 3);
  const lrc = '[ti:Song]\n'
      '[ar:Artist]\n'
      '[00:01.00]First line\n'
      '[00:05.50]Second line\n'
      '[00:10.123]Third line\n';

  group('LrcParser', () {
    test('isTimed tells timed from plain lyrics', () {
      expect(LrcParser.isTimed(lrc), isTrue);
      expect(LrcParser.isTimed('Just words\nmore words'), isFalse);
    });

    test('parse reads line texts in order', () {
      final lines = LrcParser.parse(lrc, total);
      final texts = lines.map((l) => l.text).where((t) => t.isNotEmpty);
      expect(texts, containsAllInOrder(['First line', 'Second line', 'Third line']));
    });

    test('parse reads 2- and 3-digit fractions', () {
      final lines = LrcParser.parse(lrc, total);
      LyricLine line(String t) => lines.firstWhere((l) => l.text == t);
      expect(line('First line').startTime, const Duration(seconds: 1));
      expect(line('Second line').startTime, const Duration(milliseconds: 5500));
      expect(line('Third line').startTime, const Duration(milliseconds: 10123));
    });

    test('shift moves every timestamp', () {
      final lines = LrcParser.parse(
        lrc,
        total,
        shift: const Duration(milliseconds: 500),
      );
      final first = lines.firstWhere((l) => l.text == 'First line');
      expect(first.startTime, const Duration(milliseconds: 1500));
    });

    test('plainText drops tags and timestamps', () {
      expect(
        LrcParser.plainText(lrc),
        'First line\nSecond line\nThird line',
      );
    });

    test('plainText keeps Persian (RTL) text intact', () {
      expect(
        LrcParser.plainText('[00:01.00]سلام دنیا\n[00:02.00]خط دوم'),
        'سلام دنیا\nخط دوم',
      );
    });
  });
}
