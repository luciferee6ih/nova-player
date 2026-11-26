import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_player/core/services/storage/db_service.dart';
import 'package:nova_player/core/services/ui_activity.dart';
import 'package:nova_player/core/utils/logger_helper.dart';
import 'package:nova_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:nova_player/features/settings/data/nova_feature_settings.dart';

import '../domain/camelot.dart';
import '../domain/harmonic_ordering.dart';
import '../domain/track_analysis.dart';
import 'key_bpm_analyzer.dart';
import 'pcm_analysis.dart';

/// Harmonic Queue: tempo and key of the songs around the current one, and
/// the upcoming queue reordered by them while the toggle is on.
///
/// State: what is known so far, by song id (only songs whose analysis was
/// confident enough have a [TrackFeatures] entry with values).
///
/// Cost, by design:
/// * Nothing runs unless Harmonic Queue is on or a queue screen is open
///   ([acquire] / [release]).
/// * Only the current song and the next [lookahead] get analyzed, one at
///   a time, with a pause between, and each only once (cached in Isar with
///   the file's size and date, failures included).
/// * A job starts only when [UiActivity.isQuiet] (no scroll in the last
///   2 s, app in front); decoding runs natively at background priority or
///   in an ffmpeg process, and the analysis in a background isolate.
/// * The ordering itself is planned in a background isolate and applied
///   only if the queue hasn't changed meanwhile.
class HarmonicAnalysis extends Notifier<Map<int, TrackFeatures>> {
  static const int analyzerVersion = 1;
  static const int lookahead = 40;
  static const Duration _gap = Duration(milliseconds: 1500);
  static const Duration _busyRetry = Duration(seconds: 1);

  int _interest = 0;
  final Set<int> _checked = {};
  final List<int> _pending = [];
  bool _working = false;
  Timer? _pumpTimer;
  Timer? _queueDebounce;
  Timer? _reorderDebounce;
  bool _disposed = false;

  /// Order of the reorderable tail when Harmonic Queue was turned on, to
  /// put it back when it's turned off.
  List<String>? _originalTail;

  @override
  Map<int, TrackFeatures> build() {
    ref.onDispose(() {
      _disposed = true;
      _pumpTimer?.cancel();
      _queueDebounce?.cancel();
      _reorderDebounce?.cancel();
    });
    ref.listen(playbackProvider.select((s) => s.queue), (_, _) {
      _scheduleQueueScan();
    });
    ref.listen(playbackProvider.select((s) => s.currentSong?.path), (_, _) {
      _scheduleQueueScan();
      _scheduleReorder();
    });
    ref.listen(
      novaFeatureSettingsProvider.select((s) => s.harmonicQueue),
      (_, on) => _onToggle(on),
    );
    if (ref.read(novaFeatureSettingsProvider).harmonicQueue) {
      _scheduleQueueScan();
    }
    return const {};
  }

  bool get _harmonicOn => ref.read(novaFeatureSettingsProvider).harmonicQueue;

  bool get _active => _harmonicOn || _interest > 0;

  /// A queue screen is showing: analyze the songs it lists.
  void acquire() {
    _interest++;
    if (_interest == 1) _scheduleQueueScan();
  }

  void release() {
    if (_interest > 0) _interest--;
  }

  void _onToggle(bool on) {
    if (on) {
      final tail = ref.read(playbackProvider.notifier).harmonicTail();
      _originalTail = tail?.songs.map((s) => s.path).toList();
      _scheduleQueueScan();
      _scheduleReorder(immediate: true);
    } else {
      _reorderDebounce?.cancel();
      unawaited(_restoreOriginalOrder());
    }
  }

  // ------------------------------------------------------------ scanning

  void _scheduleQueueScan() {
    if (!_active) return;
    _queueDebounce?.cancel();
    _queueDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_scanQueue());
    });
  }

  /// The current song and the next [lookahead] after it.
  List<Song> _targets() {
    final playback = ref.read(playbackProvider);
    final queue = playback.queue;
    final current = playback.currentSong;
    if (queue.isEmpty) return const [];
    final int at = current == null
        ? -1
        : queue.indexWhere((s) => s.path == current.path);
    return [
      ?current,
      for (int i = at + 1; i < queue.length && i <= at + lookahead; i++)
        queue[i],
    ];
  }

  static bool _analyzable(Song s) =>
      s.id > 0 && s.path.isNotEmpty && !s.path.startsWith('http');

  Future<void> _scanQueue() async {
    if (_disposed || !_active) return;
    final targets = _targets().where(_analyzable).toList();
    final toLoad = [
      for (final s in targets)
        if (!_checked.contains(s.id)) s,
    ];
    if (toLoad.isNotEmpty) {
      final List<TrackAnalysis?> cached;
      try {
        cached = await DbService.isar.trackAnalysis.getAll(
          toLoad.map((s) => s.id).toList(),
        );
      } catch (e) {
        LoggerHelper.write('HarmonicAnalysis: cache read failed', e);
        return;
      }
      final Map<int, TrackFeatures> found = {};
      for (int i = 0; i < toLoad.length; i++) {
        final song = toLoad[i];
        final entry = cached[i];
        _checked.add(song.id);
        if (entry != null && await _stillValid(song, entry)) {
          found[song.id] = _featuresOf(entry);
        } else {
          _pending.add(song.id);
        }
      }
      if (_disposed) return;
      if (found.isNotEmpty) _publish(found);
    }
    // Analyze in queue order: nearest songs first.
    final rank = {for (int i = 0; i < targets.length; i++) targets[i].id: i};
    // Songs that left the window are forgotten, so they're looked at
    // again if they come back.
    _pending.removeWhere((id) {
      if (rank.containsKey(id)) return false;
      _checked.remove(id);
      return true;
    });
    _pending.sort((a, b) => rank[a]!.compareTo(rank[b]!));
    _pump();
  }

  static Future<({int size, int modifiedMs})> _signature(String path) async {
    if (path.startsWith('content://')) return (size: 0, modifiedMs: 0);
    final stat = await FileStat.stat(path);
    if (stat.type == FileSystemEntityType.notFound) {
      return (size: -1, modifiedMs: -1);
    }
    return (size: stat.size, modifiedMs: stat.modified.millisecondsSinceEpoch);
  }

  Future<bool> _stillValid(Song song, TrackAnalysis entry) async {
    if (entry.analyzerVersion != analyzerVersion || entry.path != song.path) {
      return false;
    }
    final sig = await _signature(song.path);
    return sig.size == entry.fileSize && sig.modifiedMs == entry.modifiedMs;
  }

  static TrackFeatures _featuresOf(TrackAnalysis a) => TrackFeatures(
    bpm: a.bpm != null && a.bpmConfidence >= KeyBpmAnalyzer.minBpmConfidence
        ? a.bpm
        : null,
    key:
        a.keyIndex != null && a.keyConfidence >= KeyBpmAnalyzer.minKeyConfidence
        ? CamelotKey.fromIndex(a.keyIndex!)
        : null,
  );

  void _publish(Map<int, TrackFeatures> found) {
    state = {...state, ...found};
    // Only new knowledge about upcoming songs is worth a reorder.
    final tail = ref.read(playbackProvider.notifier).harmonicTail();
    final current = ref.read(playbackProvider).currentSong?.id;
    if (tail != null &&
        (found.containsKey(current) ||
            tail.songs.any((s) => found.containsKey(s.id)))) {
      _scheduleReorder();
    }
  }

  // ------------------------------------------------------------- worker

  void _pump([Duration delay = Duration.zero]) {
    if (_working || _disposed) return;
    _pumpTimer?.cancel();
    _pumpTimer = Timer(delay, _runNext);
  }

  Future<void> _runNext() async {
    if (_working || _disposed || !_active || _pending.isEmpty) return;
    if (!UiActivity.isQuiet) {
      _pump(_busyRetry);
      return;
    }
    final int id = _pending.removeAt(0);
    final Song? song = _targets().where((s) => s.id == id).firstOrNull;
    if (song == null) {
      _pump();
      return;
    }
    _working = true;
    try {
      final sig = await _signature(song.path);
      final KeyBpmResult? result = sig.size < 0
          ? null
          : await PcmAnalysis.analyzeFile(
              song.path,
              songDurationMs: song.duration ?? 0,
            );
      final entry = TrackAnalysis()
        ..id = song.id
        ..path = song.path
        ..fileSize = sig.size
        ..modifiedMs = sig.modifiedMs
        ..bpm = result?.bpm
        ..bpmConfidence = result?.bpmConfidence ?? 0
        ..keyIndex = result?.key?.index
        ..keyConfidence = result?.keyConfidence ?? 0
        ..failed = result == null
        ..analyzerVersion = analyzerVersion
        ..analyzedAt = DateTime.now();
      if (sig.size >= 0) {
        await DbService.isar.writeTxn(
          () => DbService.isar.trackAnalysis.put(entry),
        );
      }
      if (!_disposed) _publish({song.id: _featuresOf(entry)});
    } catch (e) {
      LoggerHelper.write('HarmonicAnalysis: analysis failed', e);
    } finally {
      _working = false;
    }
    if (_pending.isNotEmpty) _pump(_gap);
  }

  // ----------------------------------------------------------- ordering

  void _scheduleReorder({bool immediate = false}) {
    if (!_harmonicOn) return;
    _reorderDebounce?.cancel();
    _reorderDebounce = Timer(
      immediate ? const Duration(milliseconds: 50) : const Duration(seconds: 2),
      () => unawaited(_reorder()),
    );
  }

  Future<void> _reorder() async {
    if (_disposed || !_harmonicOn) return;
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final tail = playbackNotifier.harmonicTail();
    final current = ref.read(playbackProvider).currentSong;
    if (tail == null || current == null) return;
    final known = state;
    final currentFeatures = known[current.id] ?? const TrackFeatures();
    final upcoming = [
      for (final s in tail.songs) known[s.id] ?? const TrackFeatures(),
    ];
    if (upcoming.every((f) => f.isEmpty)) return;
    final List<int> order = await Isolate.run(
      () => harmonicOrder(current: currentFeatures, upcoming: upcoming),
    );
    if (_disposed || !_harmonicOn) return;
    await playbackNotifier.applyHarmonicOrder(
      start: tail.start,
      expectedPaths: [for (final s in tail.songs) s.path],
      order: order,
    );
  }

  Future<void> _restoreOriginalOrder() async {
    final original = _originalTail;
    _originalTail = null;
    if (original == null || _disposed) return;
    final playbackNotifier = ref.read(playbackProvider.notifier);
    final tail = playbackNotifier.harmonicTail();
    if (tail == null) return;
    final order = restoreOrder(
      current: [for (final s in tail.songs) s.path],
      original: original,
    );
    await playbackNotifier.applyHarmonicOrder(
      start: tail.start,
      expectedPaths: [for (final s in tail.songs) s.path],
      order: order,
    );
  }
}

/// Indexes into [current] that put its items back in their [original]
/// order; items that weren't there originally keep their relative order
/// after them. Cheap (n log n) and stable.
List<int> restoreOrder({
  required List<String> current,
  required List<String> original,
}) {
  final Map<String, int> rank = {};
  for (int i = 0; i < original.length; i++) {
    rank.putIfAbsent(original[i], () => i);
  }
  final idx = List<int>.generate(current.length, (i) => i);
  idx.sort((a, b) {
    final ra = rank[current[a]] ?? (original.length + a);
    final rb = rank[current[b]] ?? (original.length + b);
    final c = ra.compareTo(rb);
    return c != 0 ? c : a.compareTo(b);
  });
  return idx;
}

final harmonicAnalysisProvider =
    NotifierProvider<HarmonicAnalysis, Map<int, TrackFeatures>>(
      HarmonicAnalysis.new,
    );
