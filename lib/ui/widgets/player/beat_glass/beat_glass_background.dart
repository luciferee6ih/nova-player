import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:nova_player/core/providers/player_expand_provider.dart';
import 'package:nova_player/core/providers/providers.dart';
import 'package:nova_player/core/utils/artwork_colors.dart';
import 'package:nova_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:nova_player/features/settings/data/nova_feature_settings.dart';
import 'package:nova_player/ui/widgets/player/player_spectrum.dart';

import 'beat_glass_motion.dart';

/// Colors of the glass for one artwork.
@immutable
class BeatGlassPalette {
  const BeatGlassPalette({
    required this.deep,
    required this.mid,
    required this.glow,
    required this.ring,
  });

  /// From the artwork: its dominant color as the deep base, its primary as
  /// the glow, a lightened secondary for the rings.
  factory BeatGlassPalette.fromArtwork(ArtworkColors art) => BeatGlassPalette(
    deep: Color.lerp(art.dominant, Colors.black, 0.72)!,
    mid: Color.lerp(art.secondary, Colors.black, 0.45)!,
    glow: art.primary,
    ring: Color.lerp(art.secondary, Colors.white, 0.55)!,
  );

  factory BeatGlassPalette.fromScheme(ColorScheme scheme) => BeatGlassPalette(
    deep: Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.18),
      scheme.surface,
    ),
    mid: Color.alphaBlend(
      scheme.tertiary.withValues(alpha: 0.30),
      scheme.surface,
    ),
    glow: scheme.primary,
    ring: Color.lerp(scheme.primary, Colors.white, 0.6)!,
  );

  final Color deep;
  final Color mid;
  final Color glow;
  final Color ring;

  static BeatGlassPalette lerp(
    BeatGlassPalette a,
    BeatGlassPalette b,
    double t,
  ) => BeatGlassPalette(
    deep: Color.lerp(a.deep, b.deep, t)!,
    mid: Color.lerp(a.mid, b.mid, t)!,
    glow: Color.lerp(a.glow, b.glow, t)!,
    ring: Color.lerp(a.ring, b.ring, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is BeatGlassPalette &&
      other.deep == deep &&
      other.mid == mid &&
      other.glow == glow &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(deep, mid, glow, ring);
}

/// The "Beat Glass" Now Playing background: a liquid-glass surface tinted
/// from the artwork, with concentric ripples that pulse out on the beat.
///
/// Built to cost close to nothing:
/// * The glass itself (base, glow, sheen, Music Darkness) is one static
///   CustomPainter in its own RepaintBoundary; it repaints only during the
///   ~0.9 s cross-fade to a new artwork's colors.
/// * The ripples are a second CustomPainter in its own RepaintBoundary,
///   driven by a ValueNotifier: no setState, no widget rebuilds per frame,
///   and at most [BeatGlassMotion.maxRipples] + 1 shapes per frame. No
///   BackdropFilter, no blur.
/// * Repaints are capped at 60 fps (so a 120 Hz screen paints every other
///   vsync), and the ticker and the FFT subscription only run while it's
///   actually visible: tickers enabled, app resumed, (Fluid Player) fully
///   expanded, playing or ripples still fading out.
/// * With Reduce effects (default on slower phones) or system animations
///   off it is a still frame of the glass: no ticker, no FFT.
class BeatGlassBackground extends ConsumerStatefulWidget {
  const BeatGlassBackground({
    super.key,
    required this.artPath,
    required this.darkness,
    this.followExpandProgress = false,
  });

  /// The current song's artwork (local path or http URL), for the tint.
  final String? artPath;

  /// Music Darkness, `[0, 1]`.
  final double darkness;

  /// Hold the motion until the Fluid Player is fully expanded.
  final bool followExpandProgress;

  @override
  ConsumerState<BeatGlassBackground> createState() =>
      _BeatGlassBackgroundState();
}

class _BeatGlassBackgroundState extends ConsumerState<BeatGlassBackground>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  late final AnimationController _colorAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  final BeatGlassMotion _motion = BeatGlassMotion();

  late final _PaletteHolder _palette = _PaletteHolder();

  StreamSubscription<FftFrame>? _fftSub;
  ValueNotifier<double>? _expand;
  Duration? _lastElapsed;
  Duration _lastPaint = Duration.zero;

  BeatGlassPalette? _from;
  BeatGlassPalette? _to;
  int _artToken = 0;

  bool _playing = false;
  bool _tickerModeOn = true;
  bool _resumed = true;
  bool _expandAllows = true;
  bool _reduceMotion = false;
  bool _reduceEffects = false;

  bool get _still => _reduceMotion || _reduceEffects;

  bool get _active => !_still && _tickerModeOn && _resumed && _expandAllows;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _playing = ref.read(playbackProvider).isPlaying;
    ref.listenManual(playbackProvider.select((s) => s.isPlaying), (_, playing) {
      _playing = playing;
      _sync();
    });
    _reduceEffects = ref.read(novaFeatureSettingsProvider).reduceEffectsActive;
    ref.listenManual(
      novaFeatureSettingsProvider.select((s) => s.reduceEffectsActive),
      (_, reduce) {
        _reduceEffects = reduce;
        _onStillChanged();
        // A settings change, not a frame: rebuild once for the painter.
        if (mounted) setState(() {});
      },
    );
    if (widget.followExpandProgress) {
      final expand = ref.read(playerExpandProgressProvider)
        ..addListener(_onExpand);
      _expand = expand;
      _expandAllows = expand.value >= 0.99;
    }
    _colorAnim.addListener(() {
      _palette.value = BeatGlassPalette.lerp(
        _from!,
        _to!,
        Curves.easeInOut.transform(_colorAnim.value),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerModeOn = TickerMode.of(context);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      _onStillChanged();
    }
    if (_to == null) {
      _setPalette(BeatGlassPalette.fromScheme(Theme.of(context).colorScheme));
      _loadArtwork();
    }
    _sync();
  }

  @override
  void didUpdateWidget(covariant BeatGlassBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artPath != widget.artPath) _loadArtwork();
  }

  void _onStillChanged() {
    if (_still) _motion.clear();
    _frame.value++;
    _sync();
  }

  ImageProvider? get _artProvider {
    final String? art = widget.artPath;
    if (art == null || art.isEmpty) return null;
    if (art.startsWith('http')) return CachedNetworkImageProvider(art);
    return FileImage(File(art));
  }

  /// Colors are extracted off the UI isolate by [ArtworkColors] (and
  /// cached per artwork), then cross-faded in.
  Future<void> _loadArtwork() async {
    final int token = ++_artToken;
    final ImageProvider? provider = _artProvider;
    if (provider == null) {
      if (mounted) {
        _setPalette(BeatGlassPalette.fromScheme(Theme.of(context).colorScheme));
      }
      return;
    }
    try {
      final ArtworkColors? art = await ArtworkColors.fromProvider(provider);
      if (!mounted || token != _artToken || art == null) return;
      _setPalette(BeatGlassPalette.fromArtwork(art));
    } catch (_) {
      // Keep the colors that are showing.
    }
  }

  void _setPalette(BeatGlassPalette next) {
    if (_to == null) {
      _from = _to = _palette.value = next;
      return;
    }
    if (next == _to) return;
    _from = _palette.value;
    _to = next;
    if (_still) {
      _palette.value = next;
    } else {
      _colorAnim.forward(from: 0);
    }
  }

  void _onExpand() {
    final bool allows = _expand!.value >= 0.99;
    if (allows == _expandAllows) return;
    _expandAllows = allows;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  /// Starts or stops the FFT subscription and the ticker to match what is
  /// needed right now. Screen off / app in background = not resumed.
  void _sync() {
    if (!mounted) return;
    final bool wantFft = _active && _playing;
    if (wantFft && _fftSub == null) {
      final player = ref.read(audioServiceProvider).player;
      PlayerSpectrum.ensureConfigured(player);
      _fftSub = player.stream.fft.listen((frame) {
        _motion.addFrame(frame.bands, frame.bandLowHz, frame.bandHighHz);
      });
    } else if (!wantFft && _fftSub != null) {
      _fftSub!.cancel();
      _fftSub = null;
    }

    final bool wantTick = _active && (_playing || !_motion.settled);
    if (wantTick && !_ticker.isActive) {
      _lastElapsed = null;
      _lastPaint = Duration.zero;
      _ticker.start();
    } else if (!wantTick && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final Duration? last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;
    // Clamped so a long hitch never makes the rings jump.
    final double dt = ((elapsed - last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _motion.step(dt, playing: _playing);
    if (beatGlassFrameDue(elapsed, _lastPaint)) {
      _lastPaint = elapsed;
      _frame.value++;
    }
    if (!_playing && _motion.settled) {
      _frame.value++;
      _sync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expand?.removeListener(_onExpand);
    _fftSub?.cancel();
    _ticker.dispose();
    _colorAnim.dispose();
    _frame.dispose();
    _palette.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _GlassBasePainter(
              palette: _palette,
              darkness: widget.darkness.isNaN
                  ? 0.62
                  : widget.darkness.clamp(0.0, 1.0),
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(
            painter: _RipplePainter(
              motion: _motion,
              palette: _palette,
              still: _still,
              darkness: widget.darkness.isNaN
                  ? 0.62
                  : widget.darkness.clamp(0.0, 1.0),
              repaint: Listenable.merge([_frame, _palette]),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteHolder extends ValueNotifier<BeatGlassPalette> {
  _PaletteHolder()
    : super(
        const BeatGlassPalette(
          deep: Color(0xFF101014),
          mid: Color(0xFF1C1C24),
          glow: Color(0xFF6C7BFF),
          ring: Color(0xFFDDE2FF),
        ),
      );
}

/// Where the ripples start: behind the artwork in the classic layout.
const Alignment _rippleCenter = Alignment(0, -0.28);

/// The still glass: deep base, a soft glow behind the artwork, a lens
/// sheen across the top, a darker rim at the bottom, then Music Darkness.
class _GlassBasePainter extends CustomPainter {
  _GlassBasePainter({required this.palette, required this.darkness})
    : super(repaint: palette);

  final ValueNotifier<BeatGlassPalette> palette;
  final double darkness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final BeatGlassPalette p = palette.value;
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
          p.mid,
          p.deep,
        ]),
    );
    final Offset center = _rippleCenter.alongSize(size);
    final double reach = size.longestSide * 0.75;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(center, reach, [
          p.glow.withValues(alpha: 0.34),
          p.glow.withValues(alpha: 0.0),
        ]),
    );
    // Lens sheen: a diagonal band of light, as if the glass curves.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(size.width * 0.6, size.height * 0.45),
          [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: 0.0),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          const [0.55, 1.0],
        ),
    );
    if (darkness > 0) {
      // Lighter than the slider's full value: the glass is already dark,
      // and the rings need to stay visible.
      canvas.drawRect(
        rect,
        Paint()..color = Colors.black.withValues(alpha: darkness * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_GlassBasePainter old) =>
      old.palette != palette || old.darkness != darkness;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.motion,
    required this.palette,
    required this.still,
    required this.darkness,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final BeatGlassMotion motion;
  final ValueNotifier<BeatGlassPalette> palette;
  final bool still;
  final double darkness;

  // The still glass shows a few frozen rings so it still reads as glass.
  static const List<(double radius, double alpha)> _stillRings = [
    (0.28, 0.16),
    (0.52, 0.10),
    (0.80, 0.05),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final BeatGlassPalette p = palette.value;
    final Offset center = _rippleCenter.alongSize(size);
    final double maxRadius = size.longestSide * 0.85;
    final double fade = 1 - darkness * 0.45;
    final Paint ring = Paint()..style = PaintingStyle.stroke;

    if (still) {
      for (final (r, a) in _stillRings) {
        ring
          ..strokeWidth = 6
          ..color = p.ring.withValues(alpha: a * fade);
        canvas.drawCircle(center, maxRadius * r, ring);
      }
      return;
    }

    // The core breathes with the bass: one soft disc behind the artwork.
    final double bass = motion.levels.bass * motion.levels.presence;
    final double coreRadius = size.shortestSide * (0.42 + 0.10 * bass);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = ui.Gradient.radial(center, coreRadius, [
          p.glow.withValues(alpha: (0.10 + 0.22 * bass) * fade),
          p.glow.withValues(alpha: 0),
        ]),
    );

    for (final r in motion.ripples) {
      final double t = BeatGlassMotion.progressOf(r);
      final double radius =
          maxRadius * (0.12 + 0.88 * BeatGlassMotion.radiusOf(r));
      final double alpha = BeatGlassMotion.opacityOf(r) * 0.42 * fade;
      if (alpha <= 0.004) continue;
      ring
        ..strokeWidth = ui.lerpDouble(16, 2, t)!
        ..color = p.ring.withValues(alpha: math.min(alpha, 1.0));
      canvas.drawCircle(center, radius, ring);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.motion != motion ||
      old.palette != palette ||
      old.still != still ||
      old.darkness != darkness;
}
