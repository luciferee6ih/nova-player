import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'key_bpm_analyzer.dart';

/// The stretch of a song that gets analyzed: up to two minutes, skipping
/// the intro of longer songs (intros are often beatless or in another key
/// than the body).
({int startMs, int durationMs}) analysisWindow(int songDurationMs) {
  const int maxMs = 120000;
  if (songDurationMs <= 0) return (startMs: 0, durationMs: maxMs);
  final int start = songDurationMs > 90000
      ? (songDurationMs * 0.2).round().clamp(0, 30000)
      : 0;
  final int length = (songDurationMs - start).clamp(0, maxMs);
  return (startMs: start, durationMs: length);
}

/// Decodes and analyzes one file without blocking the UI isolate:
///
/// * Android: the platform's MediaCodec decodes on a background-priority
///   thread into a temp file (PcmDecoder.kt); the file is then read and
///   analyzed in a background isolate.
/// * Desktop: an `ffmpeg` process (the app already relies on ffprobe on
///   Linux) is run *from* the background isolate, which analyzes its
///   output there too.
///
/// Returns null when no decoder is available or the file can't be decoded.
abstract final class PcmAnalysis {
  static const MethodChannel _channel = MethodChannel(
    'com.theluciferee.novaplayer/pcm_decode',
  );

  static Future<KeyBpmResult?> analyzeFile(
    String path, {
    required int songDurationMs,
  }) async {
    final w = analysisWindow(songDurationMs);
    if (w.durationMs < 8000) return null;
    if (Platform.isAndroid) {
      return _analyzeAndroid(path, w.startMs, w.durationMs);
    }
    if (path.startsWith('content://')) return null;
    final int start = w.startMs, length = w.durationMs;
    return Isolate.run(() => _analyzeWithFfmpeg(path, start, length));
  }

  static Future<KeyBpmResult?> _analyzeAndroid(
    String path,
    int startMs,
    int durationMs,
  ) async {
    final Map<Object?, Object?>? reply;
    try {
      reply = await _channel
          .invokeMapMethod<Object?, Object?>('decodeForAnalysis', {
            'path': path,
            'startMs': startMs,
            'durationMs': durationMs,
            'sampleRate': KeyBpmAnalyzer.analysisSampleRate,
          })
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      return null;
    }
    final Object? raw = reply?['path'];
    if (raw is! String) return null;
    return Isolate.run(() => _analyzeRawFile(raw));
  }

  /// Reads (and deletes) a mono s16le file at the analysis rate.
  static KeyBpmResult? _analyzeRawFile(String rawPath) {
    final File file = File(rawPath);
    try {
      final Uint8List bytes = file.readAsBytesSync();
      return KeyBpmAnalyzer.analyze(
        KeyBpmAnalyzer.pcm16ToFloat(bytes),
        KeyBpmAnalyzer.analysisSampleRate,
      );
    } catch (_) {
      return null;
    } finally {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }

  /// Runs in a background isolate.
  static Future<KeyBpmResult?> _analyzeWithFfmpeg(
    String path,
    int startMs,
    int durationMs,
  ) async {
    final Process process;
    try {
      process = await Process.start('ffmpeg', [
        '-nostdin',
        '-v',
        'error',
        '-ss',
        (startMs / 1000).toStringAsFixed(3),
        '-t',
        (durationMs / 1000).toStringAsFixed(3),
        '-i',
        path,
        '-vn',
        '-ac',
        '1',
        '-ar',
        '${KeyBpmAnalyzer.analysisSampleRate}',
        '-f',
        's16le',
        '-',
      ]);
    } on ProcessException {
      return null;
    }
    final BytesBuilder out = BytesBuilder(copy: false);
    final Future<void> stdoutDone = process.stdout.forEach(out.add);
    final Future<void> stderrDone = process.stderr.drain<void>();
    final int code;
    try {
      code = await process.exitCode.timeout(const Duration(seconds: 60));
      await stdoutDone;
      await stderrDone;
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      return null;
    }
    if (code != 0) return null;
    return KeyBpmAnalyzer.analyze(
      KeyBpmAnalyzer.pcm16ToFloat(out.takeBytes()),
      KeyBpmAnalyzer.analysisSampleRate,
    );
  }

  /// Test hook for the desktop path.
  static Future<KeyBpmResult?> analyzeWithFfmpegForTest(
    String path,
    int startMs,
    int durationMs,
  ) => _analyzeWithFfmpeg(path, startMs, durationMs);
}
