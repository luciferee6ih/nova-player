import 'dart:math' as math;
import 'dart:typed_data';

import '../domain/camelot.dart';

/// Result of [KeyBpmAnalyzer.analyze]. A part is null when the audio gave
/// nothing usable for it (silence, too short).
class KeyBpmResult {
  const KeyBpmResult({
    this.bpm,
    this.bpmConfidence = 0,
    this.key,
    this.keyConfidence = 0,
  });

  final double? bpm;

  /// `[0, 1]`: how clearly one tempo stood out.
  final double bpmConfidence;
  final CamelotKey? key;

  /// `[0, 1]`: how far the best key's fit is ahead of the runner-up,
  /// scaled down for audio with little pitched content.
  final double keyConfidence;
}

/// Offline tempo and key estimation on mono PCM, in plain Dart so it runs
/// in a background isolate on every platform.
///
/// * **Tempo**: log-magnitude spectral flux (512-point FFT, 128-sample
///   hop) as an onset envelope, autocorrelated over 50-220 BPM with a
///   broad preference around 120 BPM, refined between lags by parabolic
///   interpolation, then folded into [minFoldedBpm, maxFoldedBpm). Double
///   / half time errors are possible, which the queue ordering tolerates
///   (it treats 70 and 140 BPM as compatible).
/// * **Key**: a chromagram (8192-point FFT, 65 Hz - 2.1 kHz folded to 12
///   pitch classes, frames normalised so loud parts don't dominate)
///   correlated with the Temperley (Kostka-Payne) major and minor key
///   profiles, which confuse a key with its dominant less often than the
///   Krumhansl-Kessler ones. Template matching like this is commonly
///   reported right on roughly 3 of 4 real pop / dance tracks; the misses
///   are mostly a neighbouring key or the relative major/minor, which the
///   harmonic ordering treats as compatible anyway.
abstract final class KeyBpmAnalyzer {
  /// Below these a part of the result is not used (see [KeyBpmResult]).
  static const double minBpmConfidence = 0.12;
  static const double minKeyConfidence = 0.15;

  /// Sample rate the decoders produce for analysis.
  static const int analysisSampleRate = 11025;

  static const double minFoldedBpm = 75;
  static const double maxFoldedBpm = 185;

  static KeyBpmResult analyze(Float32List samples, int sampleRate) {
    if (sampleRate <= 0 || samples.length < sampleRate * 8) {
      return const KeyBpmResult();
    }
    final (bpm, bpmConf) = estimateTempo(samples, sampleRate);
    final (key, keyConf) = estimateKey(samples, sampleRate);
    return KeyBpmResult(
      bpm: bpm,
      bpmConfidence: bpmConf,
      key: key,
      keyConfidence: keyConf,
    );
  }

  /// Little-endian signed 16-bit PCM to floats in `[-1, 1)`.
  static Float32List pcm16ToFloat(Uint8List bytes) {
    final int n = bytes.lengthInBytes ~/ 2;
    final ByteData data = ByteData.sublistView(bytes);
    final Float32List out = Float32List(n);
    for (int i = 0; i < n; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  // ---------------------------------------------------------------- tempo

  static (double?, double) estimateTempo(Float32List x, int sampleRate) {
    const int fftSize = 512;
    const int hop = 128;
    final double frameRate = sampleRate / hop;
    final int frames = (x.length - fftSize) ~/ hop;
    if (frames < frameRate * 6) return (null, 0);

    final _Fft fft = _Fft(fftSize);
    final Float64List window = _hann(fftSize);
    final int maxBin = math.min(
      fftSize ~/ 2,
      (5000 * fftSize / sampleRate).floor(),
    );
    final Float64List re = Float64List(fftSize);
    final Float64List im = Float64List(fftSize);
    Float64List prev = Float64List(maxBin);
    Float64List cur = Float64List(maxBin);
    final Float64List onset = Float64List(frames);
    for (int f = 0; f < frames; f++) {
      final int start = f * hop;
      for (int i = 0; i < fftSize; i++) {
        re[i] = x[start + i] * window[i];
        im[i] = 0;
      }
      fft.transform(re, im);
      double flux = 0;
      for (int b = 1; b < maxBin; b++) {
        final double mag = math.sqrt(re[b] * re[b] + im[b] * im[b]);
        final double v = math.log(1 + 100 * mag);
        cur[b] = v;
        final double d = v - prev[b];
        if (d > 0) flux += d;
      }
      onset[f] = flux;
      final Float64List t = prev;
      prev = cur;
      cur = t;
    }

    // Remove the slow trend (a moving average over ~0.4 s) and keep the
    // rises: what's left is where notes start.
    final int half = (0.2 * frameRate).round();
    final Float64List env = Float64List(frames);
    double sum = 0;
    int lo = 0, hi = -1;
    for (int i = 0; i < frames; i++) {
      while (hi < math.min(frames - 1, i + half)) {
        sum += onset[++hi];
      }
      while (lo < i - half) {
        sum -= onset[lo++];
      }
      final double avg = sum / (hi - lo + 1);
      env[i] = math.max(0, onset[i] - avg);
    }
    double mean = 0;
    for (final v in env) {
      mean += v;
    }
    mean /= frames;
    if (mean <= 1e-9) return (null, 0);

    final int minLag = (60 * frameRate / 220).floor();
    final int maxLag = (60 * frameRate / 50).ceil();
    if (maxLag + 2 >= frames) return (null, 0);
    final Float64List acf = Float64List(maxLag + 2);
    for (int lag = minLag - 1; lag <= maxLag + 1; lag++) {
      double s = 0;
      for (int i = 0; i + lag < frames; i++) {
        s += env[i] * env[i + lag];
      }
      acf[lag] = s / (frames - lag);
    }

    double best = -1;
    int bestLag = -1;
    double acfMean = 0;
    for (int lag = minLag; lag <= maxLag; lag++) {
      final double bpm = 60 * frameRate / lag;
      final double octaves = math.log(bpm / 120) / math.ln2;
      final double prior = math.exp(-0.5 * octaves * octaves / (0.9 * 0.9));
      final double score = acf[lag] * prior;
      acfMean += acf[lag];
      if (score > best) {
        best = score;
        bestLag = lag;
      }
    }
    acfMean /= (maxLag - minLag + 1);
    if (bestLag < 0 || acf[bestLag] <= 0) return (null, 0);

    // Parabolic interpolation between the neighbouring lags.
    final double a = acf[bestLag - 1], b = acf[bestLag], c = acf[bestLag + 1];
    final double denom = a - 2 * b + c;
    final double shift = denom.abs() < 1e-12
        ? 0.0
        : (0.5 * (a - c) / denom).clamp(-0.5, 0.5);
    double bpm = 60 * frameRate / (bestLag + shift);
    while (bpm < minFoldedBpm) {
      bpm *= 2;
    }
    while (bpm >= maxFoldedBpm) {
      bpm /= 2;
    }
    final double ratio = acfMean <= 0 ? 0.0 : acf[bestLag] / acfMean;
    final double confidence = ((ratio - 1) / 3).clamp(0.0, 1.0);
    return (double.parse(bpm.toStringAsFixed(1)), confidence);
  }

  // ------------------------------------------------------------------ key

  /// Temperley's Kostka-Payne key profiles, tonic first.
  static const List<double> _major = [
    0.748,
    0.060,
    0.488,
    0.082,
    0.670,
    0.460,
    0.096,
    0.715,
    0.104,
    0.366,
    0.057,
    0.400,
  ];
  static const List<double> _minor = [
    0.712,
    0.084,
    0.474,
    0.618,
    0.049,
    0.460,
    0.105,
    0.747,
    0.404,
    0.067,
    0.133,
    0.330,
  ];

  /// The 12-bin chroma of [x], summed over the track and normalised to
  /// sum 1 (all zeros for silence).
  static Float64List chroma(Float32List x, int sampleRate) {
    const int fftSize = 8192;
    const int hop = 4096;
    final Float64List total = Float64List(12);
    if (x.length < fftSize) return total;
    final _Fft fft = _Fft(fftSize);
    final Float64List window = _hann(fftSize);
    final double binHz = sampleRate / fftSize;
    final int firstBin = (65 / binHz).ceil();
    final int lastBin = math.min(fftSize ~/ 2 - 1, (2100 / binHz).floor());
    // Each bin's pitch class and a weight that falls off away from the
    // semitone's center, so bins between two notes count for little.
    final Int32List pcOf = Int32List(lastBin + 1);
    final Float64List weightOf = Float64List(lastBin + 1);
    for (int b = firstBin; b <= lastBin; b++) {
      final double midi = 69 + 12 * math.log(b * binHz / 440) / math.ln2;
      final int nearest = midi.round();
      pcOf[b] = nearest % 12;
      weightOf[b] = math.max(0, 1 - 2 * (midi - nearest).abs());
    }
    // How much bin weight each pitch class gets in total: uneven, as the
    // bins are linear and the semitones logarithmic. Dividing by it makes
    // a flat spectrum (noise) give a flat chroma.
    final Float64List pcWeight = Float64List(12);
    for (int b = firstBin; b <= lastBin; b++) {
      pcWeight[pcOf[b]] += weightOf[b];
    }
    final Float64List re = Float64List(fftSize);
    final Float64List im = Float64List(fftSize);
    final Float64List frame = Float64List(12);
    final int frames = (x.length - fftSize) ~/ hop + 1;
    for (int f = 0; f < frames; f++) {
      final int start = f * hop;
      double energy = 0;
      for (int i = 0; i < fftSize; i++) {
        final double v = x[start + i];
        energy += v * v;
        re[i] = v * window[i];
        im[i] = 0;
      }
      // Skip near-silent frames (fades, gaps): noise there is no key.
      if (energy / fftSize < 1e-6) continue;
      fft.transform(re, im);
      frame.fillRange(0, 12, 0);
      double frameSum = 0;
      for (int b = firstBin; b <= lastBin; b++) {
        final double w = weightOf[b];
        if (w == 0) continue;
        final double mag = math.sqrt(re[b] * re[b] + im[b] * im[b]);
        final double v = math.sqrt(mag) * w;
        frame[pcOf[b]] += v;
        frameSum += v;
      }
      if (frameSum <= 0) continue;
      double norm = 0;
      for (int i = 0; i < 12; i++) {
        frame[i] = pcWeight[i] > 0 ? frame[i] / pcWeight[i] : 0;
        norm += frame[i];
      }
      for (int i = 0; i < 12; i++) {
        total[i] += frame[i] / norm;
      }
    }
    double s = 0;
    for (final v in total) {
      s += v;
    }
    if (s > 0) {
      for (int i = 0; i < 12; i++) {
        total[i] /= s;
      }
    }
    return total;
  }

  /// Best key for a [chromaVector] (12 bins, C first) and its confidence.
  static (CamelotKey?, double) keyFromChroma(List<double> chromaVector) {
    double sum = 0;
    for (final v in chromaVector) {
      sum += v;
    }
    if (sum <= 0) return (null, 0);
    double best = -2, second = -2;
    int bestIndex = -1;
    for (int mode = 0; mode < 2; mode++) {
      final List<double> profile = mode == 0 ? _major : _minor;
      for (int tonic = 0; tonic < 12; tonic++) {
        final double r = _pearson(chromaVector, profile, tonic);
        if (r > best) {
          second = best;
          best = r;
          bestIndex = mode * 12 + tonic;
        } else if (r > second) {
          second = r;
        }
      }
    }
    if (bestIndex < 0 || best <= 0) return (null, 0);
    // A nearly flat chroma (noise, drums, speech) still correlates with
    // some profile once normalised; scale confidence by how uneven the
    // chroma really is (coefficient of variation; tonal music is well
    // above 0.25, broadband noise well under 0.1).
    final double mean = sum / 12;
    double variance = 0;
    for (final v in chromaVector) {
      variance += (v - mean) * (v - mean);
    }
    final double cv = math.sqrt(variance / 12) / mean;
    final double tonal = ((cv - 0.08) / 0.17).clamp(0.0, 1.0);
    final double confidence = ((best - second) / 0.15).clamp(0.0, 1.0) * tonal;
    return (CamelotKey.fromIndex(bestIndex), confidence);
  }

  static (CamelotKey?, double) estimateKey(Float32List x, int sampleRate) =>
      keyFromChroma(chroma(x, sampleRate));

  /// Correlation of [c] with [profile] rotated so its tonic is [tonic].
  static double _pearson(List<double> c, List<double> profile, int tonic) {
    double mc = 0, mp = 0;
    for (int i = 0; i < 12; i++) {
      mc += c[i];
      mp += profile[i];
    }
    mc /= 12;
    mp /= 12;
    double num = 0, dc = 0, dp = 0;
    for (int i = 0; i < 12; i++) {
      final double a = c[(i + tonic) % 12] - mc;
      final double b = profile[i] - mp;
      num += a * b;
      dc += a * a;
      dp += b * b;
    }
    if (dc <= 0 || dp <= 0) return 0;
    return num / math.sqrt(dc * dp);
  }

  static Float64List _hann(int n) {
    final Float64List w = Float64List(n);
    for (int i = 0; i < n; i++) {
      w[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
    }
    return w;
  }
}

/// In-place iterative radix-2 FFT with precomputed tables.
class _Fft {
  _Fft(this.n)
    : assert(n > 0 && (n & (n - 1)) == 0),
      _rev = Int32List(n),
      _cos = Float64List(n ~/ 2),
      _sin = Float64List(n ~/ 2) {
    int bits = 0;
    while ((1 << bits) < n) {
      bits++;
    }
    for (int i = 0; i < n; i++) {
      int r = 0;
      for (int b = 0; b < bits; b++) {
        if ((i >> b) & 1 == 1) r |= 1 << (bits - 1 - b);
      }
      _rev[i] = r;
    }
    for (int i = 0; i < n ~/ 2; i++) {
      _cos[i] = math.cos(-2 * math.pi * i / n);
      _sin[i] = math.sin(-2 * math.pi * i / n);
    }
  }

  final int n;
  final Int32List _rev;
  final Float64List _cos;
  final Float64List _sin;

  void transform(Float64List re, Float64List im) {
    for (int i = 0; i < n; i++) {
      final int j = _rev[i];
      if (j > i) {
        final double tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final double ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    for (int size = 2; size <= n; size <<= 1) {
      final int halfSize = size >> 1;
      final int step = n ~/ size;
      for (int start = 0; start < n; start += size) {
        for (int k = 0; k < halfSize; k++) {
          final double wr = _cos[k * step];
          final double wi = _sin[k * step];
          final int a = start + k;
          final int b = a + halfSize;
          final double xr = re[b] * wr - im[b] * wi;
          final double xi = re[b] * wi + im[b] * wr;
          re[b] = re[a] - xr;
          im[b] = im[a] - xi;
          re[a] += xr;
          im[a] += xi;
        }
      }
    }
  }
}
