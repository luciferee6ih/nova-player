import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/features/harmonic/data/key_bpm_analyzer.dart';
import 'package:nova_player/features/harmonic/domain/camelot.dart';
import 'package:nova_player/features/harmonic/domain/harmonic_ordering.dart';

CamelotKey k(String s) => CamelotKey.tryParse(s)!;

void main() {
  group('CamelotKey', () {
    test('maps the wheel correctly', () {
      const majors = {
        0: '8B', 7: '9B', 2: '10B', 9: '11B', 4: '12B', 11: '1B', //
        6: '2B', 1: '3B', 8: '4B', 3: '5B', 10: '6B', 5: '7B',
      };
      const minors = {
        9: '8A', 4: '9A', 11: '10A', 6: '11A', 1: '12A', 8: '1A', //
        3: '2A', 10: '3A', 5: '4A', 0: '5A', 7: '6A', 2: '7A',
      };
      majors.forEach((pc, label) {
        expect(CamelotKey.fromPitchClass(pc, minor: false).label, label);
      });
      minors.forEach((pc, label) {
        expect(CamelotKey.fromPitchClass(pc, minor: true).label, label);
      });
    });

    test('pitch class and index round-trip for all 24 keys', () {
      for (int i = 0; i < 24; i++) {
        final key = CamelotKey.fromIndex(i);
        expect(key.index, i);
        expect(CamelotKey.tryParse(key.label), key);
      }
    });

    test('names', () {
      expect(k('8B').musicalName, 'C');
      expect(k('8A').musicalName, 'Am');
      expect(k('2B').musicalName, 'F♯');
    });

    test('parsing rejects junk', () {
      expect(CamelotKey.tryParse('13A'), isNull);
      expect(CamelotKey.tryParse('0B'), isNull);
      expect(CamelotKey.tryParse('8C'), isNull);
      expect(CamelotKey.tryParse(''), isNull);
      expect(CamelotKey.tryParse(' 12b '), const CamelotKey(12, minor: false));
    });
  });

  group('key compatibility', () {
    test('same, ±1 and relative are compatible', () {
      expect(keyRelation(k('8A'), k('8A')), KeyRelation.same);
      expect(keyRelation(k('8A'), k('9A')), KeyRelation.adjacent);
      expect(keyRelation(k('8A'), k('7A')), KeyRelation.adjacent);
      expect(keyRelation(k('8A'), k('8B')), KeyRelation.relative);
      expect(keysCompatible(k('8B'), k('8A')), isTrue);
    });

    test('wraps around 12 to 1', () {
      expect(keyRelation(k('12B'), k('1B')), KeyRelation.adjacent);
      expect(keyRelation(k('1A'), k('12A')), KeyRelation.adjacent);
    });

    test('everything else clashes', () {
      expect(keysCompatible(k('8A'), k('10A')), isFalse);
      expect(keysCompatible(k('8A'), k('9B')), isFalse); // diagonal
      expect(keysCompatible(k('8A'), k('2A')), isFalse);
      expect(keysCompatible(k('3B'), k('4A')), isFalse);
    });

    test('compatibility is symmetric', () {
      for (int a = 0; a < 24; a++) {
        for (int b = 0; b < 24; b++) {
          final ka = CamelotKey.fromIndex(a), kb = CamelotKey.fromIndex(b);
          expect(keysCompatible(ka, kb), keysCompatible(kb, ka));
        }
      }
    });

    test('every key has exactly 4 compatible keys', () {
      for (int a = 0; a < 24; a++) {
        final ka = CamelotKey.fromIndex(a);
        final count = [
          for (int b = 0; b < 24; b++)
            if (keysCompatible(ka, CamelotKey.fromIndex(b))) b,
        ].length;
        expect(count, 4, reason: ka.label); // itself, ±1, relative
      }
    });
  });

  group('tempo compatibility', () {
    test('within 6%', () {
      expect(bpmCompatible(120, 126), isTrue);
      expect(bpmCompatible(120, 127.3), isFalse);
      expect(bpmCompatible(128, 121), isTrue);
    });

    test('double and half time', () {
      expect(bpmCompatible(70, 140), isTrue);
      expect(bpmCompatible(140, 70), isTrue);
      expect(bpmCompatible(87, 174), isTrue);
      expect(bpmCompatible(90, 140), isFalse);
    });

    test('invalid tempos never match', () {
      expect(bpmCompatible(0, 120), isFalse);
      expect(bpmCompatible(-5, 120), isFalse);
    });
  });

  group('harmonicOrder', () {
    TrackFeatures f(double? bpm, String? key) =>
        TrackFeatures(bpm: bpm, key: key == null ? null : k(key));

    List<int> order(
      TrackFeatures current,
      List<TrackFeatures> up, {
      int window = 8,
    }) => harmonicOrder(current: current, upcoming: up, window: window);

    test('returns a permutation', () {
      final up = [
        for (int i = 0; i < 30; i++)
          f(100 + (i * 7) % 40, '${i % 12 + 1}${i.isEven ? 'A' : 'B'}'),
      ];
      final o = order(f(120, '8A'), up);
      expect(o.length, up.length);
      expect(o.toSet().length, up.length);
    });

    test('pulls a compatible track forward', () {
      final up = [
        f(120, '2B'), // clash
        f(121, '9A'), // compatible key and tempo
        f(119, '5B'),
      ];
      expect(order(f(120, '8A'), up).first, 1);
    });

    test('chains through the wheel', () {
      final up = [f(124, '10A'), f(122, '9A'), f(123, '11A')];
      expect(order(f(120, '8A'), up), [1, 0, 2]);
    });

    test('prefers tempo within 6% (and half time) over a big jump', () {
      final up = [f(150, '8A'), f(61, '8A')];
      expect(order(f(122, '8A'), up).first, 1);
    });

    test('keeps the order when nothing is known', () {
      final up = List.generate(10, (_) => const TrackFeatures());
      expect(order(f(120, '8A'), up), List.generate(10, (i) => i));
    });

    test('keeps the order when everything already fits', () {
      final up = List.generate(6, (_) => f(120, '8A'));
      expect(order(f(120, '8A'), up), [0, 1, 2, 3, 4, 5]);
    });

    test('never moves a track further than the window allows per step', () {
      // The only compatible track sits at the very end of a long queue of
      // clashes; with window 4 it can't jump straight to the front.
      final up = [for (int i = 0; i < 12; i++) f(90, '2B'), f(120, '8A')];
      final o = order(f(120, '8A'), up, window: 4);
      expect(o.first, isNot(12));
      expect(o.length, 13);
    });

    test('an unanalyzed track does not break the chain', () {
      final up = [const TrackFeatures(), f(120, '2B'), f(121, '9A')];
      final o = order(f(120, '8A'), up);
      // After the unknown one, the compatible 9A still beats the clash.
      expect(o.indexOf(2), lessThan(o.indexOf(1)));
    });
  });

  group('KeyBpmAnalyzer', () {
    const int sr = KeyBpmAnalyzer.analysisSampleRate;

    /// Clicks with a little noise at [bpm] for [seconds].
    Float32List clickTrack(double bpm, double seconds) {
      final rnd = math.Random(7);
      final n = (sr * seconds).round();
      final out = Float32List(n);
      final period = sr * 60 / bpm;
      for (int i = 0; i < n; i++) {
        out[i] = (rnd.nextDouble() - 0.5) * 0.02;
      }
      for (double t = 0; t < n; t += period) {
        final start = t.round();
        for (int j = 0; j < 400 && start + j < n; j++) {
          out[start + j] +=
              math.exp(-j / 60) * math.sin(2 * math.pi * 900 * j / sr) * 0.8;
        }
      }
      return out;
    }

    /// Chords (root, third, fifth with two harmonics), 2 s each.
    Float32List chords(List<List<int>> midiChords, {int repeats = 4}) {
      final per = sr * 2;
      final n = per * midiChords.length * repeats;
      final out = Float32List(n);
      for (int r = 0; r < repeats; r++) {
        for (int c = 0; c < midiChords.length; c++) {
          final offset = (r * midiChords.length + c) * per;
          for (final midi in midiChords[c]) {
            final f0 = 440 * math.pow(2, (midi - 69) / 12);
            for (int h = 1; h <= 3; h++) {
              final a = 0.12 / h;
              for (int i = 0; i < per; i++) {
                out[offset + i] += a * math.sin(2 * math.pi * f0 * h * i / sr);
              }
            }
          }
        }
      }
      return out;
    }

    test('finds the tempo of a click track', () {
      for (final bpm in [96.0, 124.0, 140.0]) {
        final r = KeyBpmAnalyzer.analyze(clickTrack(bpm, 30), sr);
        expect(r.bpm, isNotNull);
        expect(
          bpmDistance(r.bpm!, bpm),
          lessThan(0.02),
          reason: 'expected ~$bpm, got ${r.bpm}',
        );
        expect(r.bpmConfidence, greaterThan(0.2));
      }
    });

    test('finds A minor from i-iv-V-i', () {
      // Am, Dm, E, Am (harmonic minor: G#).
      final x = chords([
        [57, 60, 64],
        [62, 65, 69],
        [64, 68, 71],
        [57, 60, 64],
      ]);
      final (key, conf) = KeyBpmAnalyzer.estimateKey(x, sr);
      expect(key, k('8A'), reason: 'got ${key?.label}');
      expect(conf, greaterThan(0));
    });

    test('finds C major from I-IV-V-I', () {
      final x = chords([
        [60, 64, 67],
        [65, 69, 72],
        [67, 71, 74],
        [60, 64, 67],
      ]);
      final (key, _) = KeyBpmAnalyzer.estimateKey(x, sr);
      expect(key, k('8B'), reason: 'got ${key?.label}');
    });

    test('finds a transposed key (E major)', () {
      final x = chords([
        [64, 68, 71],
        [69, 73, 76],
        [71, 75, 78],
        [64, 68, 71],
      ]);
      final (key, _) = KeyBpmAnalyzer.estimateKey(x, sr);
      expect(key, k('12B'), reason: 'got ${key?.label}');
    });

    test('all 24 keys from I-IV-V-I / i-iv-V-i progressions', () {
      final misses = <String>[];
      for (int root = 0; root < 12; root++) {
        for (final minor in [false, true]) {
          final r = 57 + root;
          final third = minor ? 3 : 4;
          final x = chords([
            [r, r + third, r + 7],
            [r + 5, r + 5 + (minor ? 3 : 4), r + 12],
            [r + 7, r + 11, r + 14],
            [r, r + third, r + 7],
          ], repeats: 2);
          final want = CamelotKey.fromPitchClass(r % 12, minor: minor);
          final (got, conf) = KeyBpmAnalyzer.estimateKey(x, sr);
          if (got != want || conf < KeyBpmAnalyzer.minKeyConfidence) {
            misses.add('${want.musicalName}->${got?.musicalName} ($conf)');
          }
        }
      }
      expect(misses, isEmpty);
    });

    test('noise is not confidently in any key or tempo', () {
      final rnd = math.Random(3);
      final x = Float32List(sr * 40);
      for (int i = 0; i < x.length; i++) {
        x[i] = (rnd.nextDouble() - 0.5) * 0.3;
      }
      final r = KeyBpmAnalyzer.analyze(x, sr);
      expect(r.keyConfidence, lessThan(KeyBpmAnalyzer.minKeyConfidence));
      expect(r.bpmConfidence, lessThan(KeyBpmAnalyzer.minBpmConfidence));
    });

    test('silence and too-short audio give nothing', () {
      final silent = KeyBpmAnalyzer.analyze(Float32List(sr * 20), sr);
      expect(silent.bpm, isNull);
      expect(silent.key, isNull);
      final short = KeyBpmAnalyzer.analyze(clickTrack(120, 3), sr);
      expect(short.bpm, isNull);
    });

    test('pcm16ToFloat', () {
      final bytes = Uint8List.fromList([0x00, 0x80, 0xff, 0x7f, 0, 0]);
      final f = KeyBpmAnalyzer.pcm16ToFloat(bytes);
      expect(f[0], -1.0);
      expect(f[1], closeTo(1.0, 1e-4));
      expect(f[2], 0.0);
    });
  });
}
