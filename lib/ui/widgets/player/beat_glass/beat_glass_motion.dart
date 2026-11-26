import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nova_player/ui/widgets/player/artwork_visualizer/visualizer_levels.dart';

/// One ring travelling out from the glass's center.
class BeatRipple {
  BeatRipple(this.strength);

  /// How hard the beat that made it hit, `(0, 1]`.
  final double strength;

  /// Seconds since it was born.
  double age = 0;
}

/// The state behind the Beat Glass background, kept free of Flutter so it
/// can be unit tested: the music's levels (from [VisualizerLevels], the
/// artwork visualizer's beat-aware smoothing) and the ripples they spawn.
///
/// A ripple starts when the bass onset envelope ([VisualizerLevels.beat])
/// rises through [beatThreshold], at most once every [minInterval], and
/// lives [lifetime] seconds. At most [maxRipples] are alive, so the painter
/// never draws more than that many rings however busy the music is.
class BeatGlassMotion {
  // The levels' reveal fade isn't used here; starting it done means a
  // paused, freshly shown glass is already settled and never ticks.
  BeatGlassMotion() : levels = VisualizerLevels(12)..reveal = 1;

  static const double beatThreshold = 0.42;
  static const double minInterval = 0.22;
  static const double lifetime = 1.7;
  static const int maxRipples = 5;

  final VisualizerLevels levels;
  final List<BeatRipple> ripples = [];

  double _sinceLastRipple = double.infinity;
  bool _armed = true;

  /// Feeds one spectrum frame (see [VisualizerLevels.addFrame]).
  void addFrame(Float32List bands, double lowHz, double highHz) =>
      levels.addFrame(bands, lowHz, highHz);

  /// Advances everything by [dt] seconds.
  void step(double dt, {required bool playing}) {
    if (dt <= 0) return;
    levels.step(dt, playing: playing);
    _sinceLastRipple += dt;
    for (final r in ripples) {
      r.age += dt;
    }
    ripples.removeWhere((r) => r.age >= lifetime);

    final double beat = levels.beat * levels.presence;
    // Re-arm once the envelope has fallen back, so one long kick spawns
    // one ripple, not one per frame above the threshold.
    if (beat < beatThreshold * 0.6) _armed = true;
    if (playing &&
        _armed &&
        beat >= beatThreshold &&
        _sinceLastRipple >= minInterval) {
      _armed = false;
      _sinceLastRipple = 0;
      if (ripples.length >= maxRipples) ripples.removeAt(0);
      ripples.add(BeatRipple(beat.clamp(0.0, 1.0)));
    }
  }

  /// Progress of [r] through its life, `[0, 1)`.
  static double progressOf(BeatRipple r) => (r.age / lifetime).clamp(0.0, 1.0);

  /// Radius of [r] as a fraction of the maximum, eased out so rings leave
  /// fast and slow down as they spread (like a ripple on water).
  static double radiusOf(BeatRipple r) {
    final double t = progressOf(r);
    return 1 - math.pow(1 - t, 2.2).toDouble();
  }

  /// Opacity of [r], fading as it spreads.
  static double opacityOf(BeatRipple r) {
    final double t = progressOf(r);
    return math.pow(1 - t, 1.6).toDouble() * (0.35 + 0.65 * r.strength);
  }

  /// Nothing left to animate: no ripples and the levels at rest.
  bool get settled => ripples.isEmpty && levels.settled;

  void clear() {
    ripples.clear();
    levels
      ..clear()
      ..reveal = 1;
    _sinceLastRipple = double.infinity;
    _armed = true;
  }
}

/// Frame pacing for the Beat Glass ticker: true when a repaint is due
/// given the time of the last one, capped at [maxFps] (with half a
/// millisecond of slack so a 60 Hz display never skips a vsync).
bool beatGlassFrameDue(
  Duration elapsed,
  Duration lastPaint, {
  double maxFps = 60,
}) {
  final int minMicros = (1e6 / maxFps).round() - 500;
  return (elapsed - lastPaint).inMicroseconds >= minMicros;
}
