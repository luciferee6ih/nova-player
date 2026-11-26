part of 'theme_settings_tiles.dart';

/// A row of choice chips under a title, like the lyric line transition.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<(T, String)> options;
  final T current;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: _tileTitleStyle()),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: _tileSubtitleStyle()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in options)
                  ChoiceChip(
                    label: Text(label),
                    selected: current == value,
                    showCheckmark: false,
                    selectedColor: Colors.white.withValues(alpha: 0.15),
                    onSelected: (_) {
                      if (current == value) return;
                      AppHaptics.selection();
                      onSelected(value);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Appearance > Navigation bar style: Floating glass or Classic.
class NavbarStyleTile extends ConsumerWidget {
  const NavbarStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(
      novaFeatureSettingsProvider.select((s) => s.navbarStyle),
    );
    return _ChoiceTile<NavbarStyle>(
      icon: LucideIcons.panelBottom,
      title: l10n.navbarStyle,
      subtitle: l10n.navbarStyleDesc,
      current: current,
      options: [
        (NavbarStyle.floatingGlass, l10n.navbarFloatingGlass),
        (NavbarStyle.classic, l10n.navbarClassic),
      ],
      onSelected: (v) =>
          ref.read(novaFeatureSettingsProvider.notifier).setNavbarStyle(v),
    );
  }
}

/// Reduce effects on slower phones: still, unblurred glass. Starts on by
/// itself on a phone [DevicePerformance] counts as slower.
class ReduceEffectsTile extends ConsumerWidget {
  const ReduceEffectsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final value = ref.watch(
      novaFeatureSettingsProvider.select((s) => s.reduceEffectsActive),
    );
    return SwitchListTile(
      secondary: const Icon(LucideIcons.gauge),
      title: Text(l10n.reduceEffects, style: _tileTitleStyle()),
      subtitle: Text(l10n.reduceEffectsDesc, style: _tileSubtitleStyle()),
      value: value,
      onChanged: (v) {
        AppHaptics.selection();
        ref.read(novaFeatureSettingsProvider.notifier).setReduceEffects(v);
      },
    );
  }
}

/// Now Playing > Player background > Background style: Standard or Beat
/// Glass (off by default).
class PlayerBackgroundStyleTile extends ConsumerWidget {
  const PlayerBackgroundStyleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(
      novaFeatureSettingsProvider.select((s) => s.playerBackgroundStyle),
    );
    return _ChoiceTile<PlayerBackgroundStyle>(
      icon: LucideIcons.droplets,
      title: l10n.playerBackgroundStyle,
      subtitle: l10n.playerBackgroundStyleDesc,
      current: current,
      options: [
        (PlayerBackgroundStyle.standard, l10n.playerBackgroundStandard),
        (PlayerBackgroundStyle.beatGlass, l10n.playerBackgroundBeatGlass),
      ],
      onSelected: (v) => ref
          .read(novaFeatureSettingsProvider.notifier)
          .setPlayerBackgroundStyle(v),
    );
  }
}

/// Appearance > App icon: Black (default), White or Colorful launcher icon.
class AppIconTile extends StatefulWidget {
  const AppIconTile({super.key});

  @override
  State<AppIconTile> createState() => _AppIconTileState();
}

class _AppIconTileState extends State<AppIconTile> {
  AppIconChoice _current = AppIconChoice.black;

  @override
  void initState() {
    super.initState();
    AppIconService.current().then((c) {
      if (mounted) setState(() => _current = c);
    });
  }

  Future<void> _select(AppIconChoice choice) async {
    final previous = _current;
    setState(() => _current = choice);
    final ok = await AppIconService.set(choice);
    if (!ok && mounted) setState(() => _current = previous);
  }

  @override
  Widget build(BuildContext context) {
    if (!AppIconService.isSupported) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _ChoiceTile<AppIconChoice>(
      icon: LucideIcons.appWindow,
      title: l10n.appIcon,
      subtitle: l10n.appIconDesc,
      current: _current,
      options: [
        (AppIconChoice.black, l10n.appIconBlack),
        (AppIconChoice.white, l10n.appIconWhite),
        (AppIconChoice.aurora, l10n.appIconAurora),
      ],
      onSelected: _select,
    );
  }
}
