import 'dart:io';

/// A rough, cheap guess of whether this phone is a slower one, so new
/// visual effects can start in their still form there (Settings > Reduce
/// effects on slower phones overrides it).
///
/// Android only; desktops are never treated as slow. Reads the kernel's
/// memory total and the fastest CPU core's top clock once at startup. A
/// Redmi 12-class phone (Helio G88, 2.0 GHz, 4-8 GB) counts as slow; so
/// does anything whose numbers can't be read but has under 6 cores.
abstract final class DevicePerformance {
  static bool _lowEnd = false;
  static bool _initialized = false;

  /// Slower than about a 2.4 GHz big core, or under ~5 GB of RAM.
  static bool get isLowEnd => _lowEnd;

  /// Fastest core clock below this counts as slow (kHz).
  static const int slowCpuKhz = 2400000;

  /// Memory below this counts as slow (kB). 6 GB phones report ~5.4 GB.
  static const int lowMemKb = 5 * 1024 * 1024;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (!Platform.isAndroid) return;
    try {
      _lowEnd = classify(
        memTotalKb: await _memTotalKb(),
        maxCpuKhz: await _maxCpuKhz(),
        cores: Platform.numberOfProcessors,
      );
    } catch (_) {
      _lowEnd = false;
    }
  }

  /// The decision on its own, for tests.
  static bool classify({int? memTotalKb, int? maxCpuKhz, required int cores}) {
    if (memTotalKb != null && memTotalKb < lowMemKb) return true;
    if (maxCpuKhz != null && maxCpuKhz < slowCpuKhz) return true;
    if (memTotalKb == null && maxCpuKhz == null) return cores < 6;
    return false;
  }

  static Future<int?> _memTotalKb() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          return int.tryParse(line.replaceAll(RegExp(r'[^0-9]'), ''));
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<int?> _maxCpuKhz() async {
    int? best;
    for (int i = 0; i < Platform.numberOfProcessors && i < 16; i++) {
      try {
        final f = File(
          '/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq',
        );
        final v = int.tryParse((await f.readAsString()).trim());
        if (v != null && (best == null || v > best)) best = v;
      } catch (_) {}
    }
    return best;
  }
}
