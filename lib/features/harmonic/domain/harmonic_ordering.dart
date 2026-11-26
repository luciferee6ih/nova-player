import 'camelot.dart';

/// What the harmonic ordering knows about one track. Either part can be
/// missing (not analyzed yet, or too unsure to use).
class TrackFeatures {
  const TrackFeatures({this.bpm, this.key});

  final double? bpm;
  final CamelotKey? key;

  bool get isEmpty => bpm == null && key == null;

  @override
  bool operator ==(Object other) =>
      other is TrackFeatures && other.bpm == bpm && other.key == key;

  @override
  int get hashCode => Object.hash(bpm, key);
}

/// Cost weights of [harmonicTransitionCost]. Lower is a better transition.
abstract final class HarmonicCost {
  static const double keySame = 0;
  static const double keyNear = 0.2;
  static const double keyClash = 1.0;
  static const double tempoClash = 1.0;

  /// For a side that isn't known: between a good and a bad match, so a
  /// known-good candidate wins and a known clash loses.
  static const double unknown = 0.55;

  /// Per slot a candidate sits further down the original order. Keeps the
  /// queue's general shape: a compatible track one slot later beats a
  /// clashing one now, but not one twenty slots later.
  static const double perSlot = 0.06;
}

/// Cost of playing [to] right after [from].
double harmonicTransitionCost(TrackFeatures from, TrackFeatures to) {
  final double keyCost;
  final CamelotKey? fk = from.key, tk = to.key;
  if (fk == null || tk == null) {
    keyCost = HarmonicCost.unknown;
  } else {
    keyCost = switch (keyRelation(fk, tk)) {
      KeyRelation.same => HarmonicCost.keySame,
      KeyRelation.adjacent || KeyRelation.relative => HarmonicCost.keyNear,
      KeyRelation.clash => HarmonicCost.keyClash,
    };
  }
  final double tempoCost;
  final double? fb = from.bpm, tb = to.bpm;
  if (fb == null || tb == null) {
    tempoCost = HarmonicCost.unknown;
  } else {
    final double d = bpmDistance(fb, tb);
    tempoCost = d <= defaultBpmTolerance
        ? 0.25 * d / defaultBpmTolerance
        : HarmonicCost.tempoClash;
  }
  return keyCost + tempoCost;
}

/// Reorders [upcoming] (the not-yet-played part of the queue, in its
/// current order) so each track leads well into the next, starting from
/// [current], the track playing now.
///
/// Greedy, and deliberately local: each step picks the cheapest of the
/// next [window] tracks in their current order (cost from
/// [harmonicTransitionCost] plus [HarmonicCost.perSlot] per slot it would
/// jump). So the queue keeps its overall order (an album or playlist still
/// moves forward), nothing is starved at the end, ties keep the current
/// order, and tracks with no analysis yet mostly stay where they are.
/// Runs in O(n * window). Returns indexes into [upcoming].
List<int> harmonicOrder({
  required TrackFeatures current,
  required List<TrackFeatures> upcoming,
  int window = 8,
}) {
  final int n = upcoming.length;
  final List<int> remaining = [for (int i = 0; i < n; i++) i];
  final List<int> order = [];
  // The reference is the last placed track that has any features, so one
  // unanalyzed track doesn't break the chain.
  TrackFeatures reference = current;
  while (remaining.isNotEmpty) {
    final int limit = remaining.length < window ? remaining.length : window;
    int bestSlot = 0;
    double bestCost = double.infinity;
    for (int slot = 0; slot < limit; slot++) {
      final double cost =
          harmonicTransitionCost(reference, upcoming[remaining[slot]]) +
          slot * HarmonicCost.perSlot;
      // Strictly less: equal cost keeps the earlier track.
      if (cost < bestCost - 1e-9) {
        bestCost = cost;
        bestSlot = slot;
      }
    }
    final int chosen = remaining.removeAt(bestSlot);
    order.add(chosen);
    if (!upcoming[chosen].isEmpty) reference = upcoming[chosen];
  }
  return order;
}
