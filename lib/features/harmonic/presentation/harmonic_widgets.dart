import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nova_player/core/services/haptics/app_haptics.dart';
import 'package:nova_player/core/theme/app_fonts.dart';
import 'package:nova_player/features/playback/presentation/providers/playback/playback_notifier.dart';
import 'package:nova_player/features/settings/data/nova_feature_settings.dart';
import 'package:nova_player/l10n/app_localizations.dart';

import '../data/harmonic_analysis_service.dart';
import '../domain/camelot.dart';
import '../domain/harmonic_ordering.dart';

/// Tempo and Camelot key chips for one queue row.
///
/// Watches only this song's entry (and the current song's key, for the
/// "fits" tint) through `select`, so a new analysis rebuilds just the
/// chips of the row it's about, never the list.
class HarmonicChips extends ConsumerWidget {
  const HarmonicChips({super.key, required this.songId, this.compact = false});

  final int songId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TrackFeatures? f = ref.watch(
      harmonicAnalysisProvider.select((m) => m[songId]),
    );
    if (f == null || f.isEmpty) return const SizedBox.shrink();
    final int? currentId = ref.watch(
      playbackProvider.select((s) => s.currentSong?.id),
    );
    final CamelotKey? currentKey = currentId == null || currentId == songId
        ? null
        : ref.watch(harmonicAnalysisProvider.select((m) => m[currentId]?.key));
    final l10n = AppLocalizations.of(context)!;
    final Color accent = Theme.of(context).colorScheme.primary;
    final double? bpm = f.bpm;
    final CamelotKey? key = f.key;
    final bool fits =
        key != null && currentKey != null && keysCompatible(key, currentKey);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bpm != null)
          _Chip(
            text: l10n.bpmValue(bpm.round().toString()),
            semantics: l10n.harmonicTempoLabel(bpm.round().toString()),
            compact: compact,
          ),
        if (bpm != null && key != null) const SizedBox(width: 4),
        if (key != null)
          _Chip(
            text: key.label,
            semantics: l10n.harmonicKeyLabel(key.label, key.musicalName),
            tint: fits ? accent : null,
            compact: compact,
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    required this.semantics,
    this.tint,
    required this.compact,
  });

  final String text;
  final String semantics;
  final Color? tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color fg = tint ?? Colors.white.withValues(alpha: 0.7);
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 0 : 1),
        decoration: BoxDecoration(
          color: (tint ?? Colors.white).withValues(
            alpha: tint == null ? 0.08 : 0.18,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        // Latin digits and letters either way, so RTL can't reorder "8A".
        child: Text(
          text,
          textDirection: TextDirection.ltr,
          style: AppFonts.jostStyle(
            color: fg,
            fontSize: compact ? 9.5 : 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

/// A queue row's subtitle: the artist line, then the chips.
class HarmonicSubtitle extends StatelessWidget {
  const HarmonicSubtitle({
    super.key,
    required this.songId,
    required this.child,
  });

  final int songId;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(child: child),
      const SizedBox(width: 6),
      HarmonicChips(songId: songId, compact: true),
    ],
  );
}

/// While mounted, lets Harmonic Queue analyze the songs a queue screen
/// shows (nothing runs for chips nobody sees).
class HarmonicQueueInterest extends ConsumerStatefulWidget {
  const HarmonicQueueInterest({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HarmonicQueueInterest> createState() =>
      _HarmonicQueueInterestState();
}

class _HarmonicQueueInterestState extends ConsumerState<HarmonicQueueInterest> {
  late final HarmonicAnalysis _service = ref.read(
    harmonicAnalysisProvider.notifier,
  );

  @override
  void initState() {
    super.initState();
    _service.acquire();
  }

  @override
  void dispose() {
    _service.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The Harmonic Queue switch as a small pill, for queue headers.
class HarmonicQueuePill extends ConsumerWidget {
  const HarmonicQueuePill({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool on = ref.watch(
      novaFeatureSettingsProvider.select((s) => s.harmonicQueue),
    );
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.harmonicQueueDesc,
      child: Semantics(
        toggled: on,
        button: true,
        label: l10n.harmonicQueue,
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('harmonic_queue_toggle'),
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            AppHaptics.selection();
            ref
                .read(novaFeatureSettingsProvider.notifier)
                .setHarmonicQueue(!on);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: on
                  ? accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: on ? accent : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.audioWaveform,
                  size: 13,
                  color: on ? accent : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.harmonicQueueShort,
                  style: AppFonts.jostStyle(
                    color: on ? accent : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
