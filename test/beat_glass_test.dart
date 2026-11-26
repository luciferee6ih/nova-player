import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:nova_player/features/settings/data/nova_feature_settings.dart';
import 'package:nova_player/ui/widgets/player/beat_glass/beat_glass_background.dart';
import 'package:nova_player/ui/widgets/player/beat_glass/beat_glass_motion.dart';

class _FakePlayback extends Playback {
  _FakePlayback(this.playing);
  final bool playing;
  @override
  PlaybackState build() => PlaybackState(isPlaying: playing);
}

class _FakeFeatures extends NovaFeatureSettingsNotifier {
  _FakeFeatures(this.initial);
  final NovaFeatureSettings initial;
  @override
  NovaFeatureSettings build() => initial;
}

/// A spectrum frame with [bass] in the low bands and quiet highs.
Float32List _frame(double bass) {
  final f = Float32List(16);
  for (int i = 0; i < 16; i++) {
    f[i] = i < 4 ? bass : 0.1;
  }
  return f;
}

/// Feeds a four-on-the-floor pattern at [bpm] for [seconds], stepping the
/// motion at 60 fps and the FFT at 20 Hz like the app does.
void _play(BeatGlassMotion m, {double bpm = 120, double seconds = 4}) {
  const double dt = 1 / 60;
  final double beatPeriod = 60 / bpm;
  double t = 0, nextFft = 0;
  while (t < seconds) {
    if (t >= nextFft) {
      final double phase = (t % beatPeriod) / beatPeriod;
      m.addFrame(_frame(phase < 0.12 ? 0.95 : 0.15), 40, 16000);
      nextFft += 0.05;
    }
    m.step(dt, playing: true);
    t += dt;
  }
}

void main() {
  group('BeatGlassMotion', () {
    test('spawns ripples on beats, capped and spaced', () {
      final m = BeatGlassMotion();
      _play(m);
      expect(m.ripples, isNotEmpty);
      expect(m.ripples.length, lessThanOrEqualTo(BeatGlassMotion.maxRipples));
      for (final r in m.ripples) {
        expect(r.age, lessThan(BeatGlassMotion.lifetime));
        expect(r.strength, inInclusiveRange(0.0, 1.0));
      }
    });

    test('steady sound with no onsets spawns nothing', () {
      final m = BeatGlassMotion();
      for (int i = 0; i < 240; i++) {
        if (i % 3 == 0) m.addFrame(_frame(0.5), 40, 16000);
        m.step(1 / 60, playing: true);
      }
      expect(m.ripples, isEmpty);
    });

    test('a very fast pulse never exceeds the ripple cap', () {
      final m = BeatGlassMotion();
      _play(m, bpm: 400, seconds: 6);
      expect(m.ripples.length, lessThanOrEqualTo(BeatGlassMotion.maxRipples));
    });

    test('settles after pause so the ticker can stop', () {
      final m = BeatGlassMotion();
      _play(m);
      for (int i = 0; i < 60 * 8; i++) {
        m.step(1 / 60, playing: false);
      }
      expect(m.ripples, isEmpty);
      expect(m.settled, isTrue);
    });

    test('ripple shape: grows outwards and fades', () {
      final r = BeatRipple(1);
      final r0 = BeatGlassMotion.radiusOf(r);
      final a0 = BeatGlassMotion.opacityOf(r);
      r.age = BeatGlassMotion.lifetime * 0.5;
      expect(BeatGlassMotion.radiusOf(r), greaterThan(r0));
      expect(BeatGlassMotion.opacityOf(r), lessThan(a0));
      r.age = BeatGlassMotion.lifetime;
      expect(BeatGlassMotion.opacityOf(r), closeTo(0, 1e-9));
    });
  });

  group('beatGlassFrameDue', () {
    test('paints every vsync at 60 Hz', () {
      const vsync = Duration(microseconds: 16667);
      expect(beatGlassFrameDue(vsync, Duration.zero), isTrue);
    });

    test('paints every other vsync at 120 Hz', () {
      const vsync = Duration(microseconds: 8333);
      expect(beatGlassFrameDue(vsync, Duration.zero), isFalse);
      expect(beatGlassFrameDue(vsync * 2, Duration.zero), isTrue);
    });

    test('caps at about 60 paints a second at 120 Hz', () {
      var last = Duration.zero;
      var paints = 0;
      for (int i = 1; i <= 120; i++) {
        final now = Duration(microseconds: 8333 * i);
        if (beatGlassFrameDue(now, last)) {
          last = now;
          paints++;
        }
      }
      expect(paints, inInclusiveRange(58, 61));
    });
  });

  group('BeatGlassBackground widget', () {
    Widget host({
      required bool playing,
      NovaFeatureSettings features = const NovaFeatureSettings(),
      bool tickers = true,
    }) => ProviderScope(
      key: ValueKey((playing, features, tickers)),
      overrides: [
        playbackProvider.overrideWith(() => _FakePlayback(playing)),
        novaFeatureSettingsProvider.overrideWith(() => _FakeFeatures(features)),
      ],
      child: MaterialApp(
        home: TickerMode(
          enabled: tickers,
          child: const BeatGlassBackground(artPath: null, darkness: 0.4),
        ),
      ),
    );

    testWidgets('idle while paused: no ticker, no frames scheduled', (
      tester,
    ) async {
      await tester.pumpWidget(host(playing: false));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byType(CustomPaint), findsWidgets);
      // Its painters sit in their own repaint boundaries.
      expect(
        find.descendant(
          of: find.byType(BeatGlassBackground),
          matching: find.byType(RepaintBoundary),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('reduce effects: a still frame even while playing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          playing: true,
          features: const NovaFeatureSettings(reduceEffects: true),
        ),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('hidden (tickers off): does not animate', (tester) async {
      await tester.pumpWidget(host(playing: true, tickers: false));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}
