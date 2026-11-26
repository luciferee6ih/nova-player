import 'dart:math' as math;

/// A musical key on the Camelot wheel: [number] 1-12 around the circle of
/// fifths, [minor] the inner "A" ring, major the outer "B" ring.
class CamelotKey {
  const CamelotKey(this.number, {required this.minor})
    : assert(number >= 1 && number <= 12);

  final int number;
  final bool minor;

  static const List<String> _pitchNames = [
    'C', 'C♯', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B', //
  ];

  /// The key with tonic [pitchClass] (0 = C ... 11 = B).
  factory CamelotKey.fromPitchClass(int pitchClass, {required bool minor}) {
    final int pc = pitchClass % 12;
    // Each step around the wheel is a fifth (7 semitones); C major is 8B
    // and A minor (its relative) 8A.
    final int fifths = (pc * 7) % 12;
    final int offset = minor ? 5 : 8; // Cm = 5A, C = 8B.
    return CamelotKey((fifths + offset - 1) % 12 + 1, minor: minor);
  }

  /// Index 0-23: pitch class for majors (0-11), 12 + pitch class for
  /// minors (12-23). The form stored in the analysis cache.
  factory CamelotKey.fromIndex(int index) =>
      CamelotKey.fromPitchClass(index % 12, minor: index >= 12);

  /// Parses "8A", "12b" and the like; null for anything else.
  static CamelotKey? tryParse(String text) {
    final m = RegExp(r'^\s*(\d{1,2})\s*([ABab])\s*$').firstMatch(text);
    if (m == null) return null;
    final int n = int.parse(m.group(1)!);
    if (n < 1 || n > 12) return null;
    return CamelotKey(n, minor: m.group(2)!.toUpperCase() == 'A');
  }

  /// Tonic pitch class, 0 = C.
  int get pitchClass {
    final int offset = minor ? 5 : 8;
    final int fifths = (number - 1 - (offset - 1)) % 12;
    // Inverse of (pc * 7) % 12: 7 is its own inverse mod 12.
    return (fifths * 7) % 12;
  }

  int get index => (minor ? 12 : 0) + pitchClass;

  /// "8A" / "8B".
  String get label => '$number${minor ? 'A' : 'B'}';

  /// Conventional name, e.g. "A minor"-style short form "Am" / "C".
  String get musicalName => '${_pitchNames[pitchClass]}${minor ? 'm' : ''}';

  /// Steps between the two numbers around the wheel, 0-6.
  int wheelDistance(CamelotKey other) {
    final int d = (number - other.number).abs() % 12;
    return d > 6 ? 12 - d : d;
  }

  @override
  bool operator ==(Object other) =>
      other is CamelotKey && other.number == number && other.minor == minor;

  @override
  int get hashCode => Object.hash(number, minor);

  @override
  String toString() => label;
}

/// How well one key leads into another, for harmonic mixing.
enum KeyRelation {
  /// The same key.
  same,

  /// One step around the wheel on the same ring (a fifth up or down).
  adjacent,

  /// Same number, other ring: the relative major / minor.
  relative,

  /// Anything else.
  clash,
}

KeyRelation keyRelation(CamelotKey a, CamelotKey b) {
  if (a == b) return KeyRelation.same;
  if (a.minor == b.minor && a.wheelDistance(b) == 1) {
    return KeyRelation.adjacent;
  }
  if (a.number == b.number && a.minor != b.minor) return KeyRelation.relative;
  return KeyRelation.clash;
}

/// Same key, ±1 on the wheel, or relative major/minor.
bool keysCompatible(CamelotKey a, CamelotKey b) =>
    keyRelation(a, b) != KeyRelation.clash;

/// Default tempo tolerance for a smooth blend.
const double defaultBpmTolerance = 0.06;

/// How far apart two tempos are as a fraction, also counting double and
/// half time (a 70 BPM track sits fine next to a 140 BPM one). 0 = same.
double bpmDistance(double a, double b) {
  if (a <= 0 || b <= 0) return double.infinity;
  double best = double.infinity;
  for (final double k in const [0.5, 1.0, 2.0]) {
    final double x = a * k;
    // Relative to the slower of the two, so it's symmetric.
    final double d = (x - b).abs() / math.min(x, b);
    if (d < best) best = d;
  }
  return best;
}

/// Within [tolerance] (±6% by default), counting double / half time.
bool bpmCompatible(
  double a,
  double b, {
  double tolerance = defaultBpmTolerance,
}) => bpmDistance(a, b) <= tolerance + 1e-9;
