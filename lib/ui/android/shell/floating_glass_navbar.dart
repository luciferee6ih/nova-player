import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nova_player/core/services/haptics/app_haptics.dart';
import 'package:nova_player/core/theme/app_fonts.dart';
import 'package:nova_player/core/theme/app_icons.dart';
import 'package:nova_player/core/utils/motion.dart';
import 'package:nova_player/core/utils/responsive.dart';
import 'package:nova_player/features/settings/data/nova_feature_settings.dart';
import 'package:nova_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:nova_player/l10n/app_localizations.dart';

/// Sizes of the floating glass bar, shared with the shell so the mini
/// player rests exactly above it and its hide slide clears it.
abstract final class FloatingGlassNavbarMetrics {
  static const double horizontalMargin = 16;
  static const double gap = 10;
  static const double topPadding = 2;

  static double barHeight({required bool compact}) => compact ? 52 : 64;

  static double bottomMargin({required bool compact}) => compact ? 8 : 16;

  /// Total height of the bar's slot, the system navigation inset included.
  static double totalHeight({
    required bool compact,
    required double systemBottom,
  }) =>
      topPadding +
      barHeight(compact: compact) +
      bottomMargin(compact: compact) +
      systemBottom;
}

/// Glass colors for one look (dark / AMOLED / light) and tint.
@immutable
class GlassPalette {
  const GlassPalette({
    required this.fill,
    required this.solidFill,
    required this.rimTop,
    required this.rimBottom,
    required this.sheen,
    required this.capsuleFill,
    required this.capsuleRim,
    required this.selected,
    required this.unselected,
    required this.shadow,
  });

  /// Tint laid over the blurred backdrop.
  final Color fill;

  /// Fill used instead when there's no blur (Reduce effects): opaque
  /// enough that busy content under it can't hurt legibility.
  final Color solidFill;
  final Color rimTop;
  final Color rimBottom;
  final Color sheen;
  final Color capsuleFill;
  final Color capsuleRim;
  final Color selected;
  final Color unselected;
  final Color shadow;

  /// Builds the palette from the app surface and the accent (which follows
  /// the artwork when Dynamic Accent is on).
  factory GlassPalette.resolve({
    required Color accent,
    required Color surface,
    required Brightness brightness,
  }) {
    final bool light = brightness == Brightness.light;
    final bool amoled = !light && surface.computeLuminance() < 0.002;
    final Color base = light ? Colors.white : (amoled ? Colors.black : surface);
    // A little accent in the glass, more in the capsule.
    final Color tinted = Color.alphaBlend(
      accent.withValues(alpha: light ? 0.10 : 0.16),
      base,
    );
    final Color selected = light
        ? Color.lerp(accent, Colors.black, 0.25)!
        : Color.lerp(accent, Colors.white, 0.15)!;
    return GlassPalette(
      fill: tinted.withValues(alpha: light ? 0.55 : (amoled ? 0.50 : 0.42)),
      solidFill: tinted.withValues(alpha: light ? 0.94 : 0.92),
      rimTop: Colors.white.withValues(alpha: light ? 0.85 : 0.32),
      rimBottom: Colors.white.withValues(alpha: light ? 0.25 : 0.05),
      sheen: Colors.white.withValues(alpha: light ? 0.28 : 0.09),
      capsuleFill: Color.alphaBlend(
        accent.withValues(alpha: light ? 0.16 : 0.22),
        Colors.white.withValues(alpha: light ? 0.55 : 0.10),
      ),
      capsuleRim: Colors.white.withValues(alpha: light ? 0.9 : 0.38),
      selected: selected,
      unselected: light
          ? Colors.black.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.55),
      shadow: Colors.black.withValues(alpha: light ? 0.16 : 0.42),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GlassPalette &&
      other.fill == fill &&
      other.solidFill == solidFill &&
      other.rimTop == rimTop &&
      other.rimBottom == rimBottom &&
      other.sheen == sheen &&
      other.capsuleFill == capsuleFill &&
      other.capsuleRim == capsuleRim &&
      other.selected == selected &&
      other.unselected == unselected &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
    fill,
    solidFill,
    rimTop,
    rimBottom,
    sheen,
    capsuleFill,
    capsuleRim,
    selected,
    unselected,
    shadow,
  );
}

/// Horizontal offset of the selection capsule for a (possibly fractional,
/// mid-spring) tab [position] among [count] slots of [slotWidth]. Mirrors
/// in right-to-left layouts, where the first tab sits on the right.
double glassCapsuleOffset({
  required double position,
  required int count,
  required double slotWidth,
  required TextDirection direction,
}) {
  final double p = direction == TextDirection.rtl
      ? (count - 1) - position
      : position;
  return p * slotWidth;
}

/// The phone's floating liquid-glass navigation: a pill with the three
/// main tabs, the selected one in a raised glass capsule that springs
/// between them, and a round glass Search button beside it.
///
/// Built to cost no more than the classic bar:
/// * one grouped BackdropFilter per glass shape (pill, circle), both under
///   one BackdropGroup so they share a single backdrop read, and no blur
///   anywhere inside them;
/// * the capsule moves with a Transform driven by an AnimationController,
///   so a tab change never lays the bar out again;
/// * the glass, rim and capsule are static CustomPainters that repaint only
///   when the tint changes;
/// * with Reduce effects (default on slower phones), Disable Blur Effects
///   (Dynamic Theming), or system animations off, it draws a translucent fill and
///   no backdrop blur.
class FloatingGlassNavbar extends ConsumerStatefulWidget {
  const FloatingGlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onSearch,
  });

  static const int tabCount = 3;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSearch;

  @override
  ConsumerState<FloatingGlassNavbar> createState() =>
      _FloatingGlassNavbarState();
}

class _FloatingGlassNavbarState extends ConsumerState<FloatingGlassNavbar>
    with SingleTickerProviderStateMixin {
  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 34,
  );

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.currentIndex.toDouble(),
  );

  @override
  void didUpdateWidget(covariant FloatingGlassNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final double target = widget.currentIndex.toDouble();
      if (Motion.reducedOf(context)) {
        _position.value = target;
      } else {
        _position.animateWith(
          SpringSimulation(
            _spring,
            _position.value,
            target,
            _position.velocity,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = ref.watch(settingsProvider.select((s) => s.accent));
    // "Disable Blur Effects" only exists (and only applies) while Dynamic
    // Theming is on; its stored default is true otherwise.
    final bool disableBlur = ref.watch(
      settingsProvider.select((s) => s.enableDynamicTheming && s.disableBlur),
    );
    final bool reduceEffects = ref.watch(
      novaFeatureSettingsProvider.select((s) => s.reduceEffectsActive),
    );
    final ThemeData theme = Theme.of(context);
    final GlassPalette palette = GlassPalette.resolve(
      accent: accent,
      surface: theme.colorScheme.surface,
      brightness: theme.brightness,
    );
    final bool blur =
        !reduceEffects &&
        !disableBlur &&
        !MediaQuery.disableAnimationsOf(context);
    final l10n = AppLocalizations.of(context)!;
    final bool compact = Responsive.isShort(MediaQuery.sizeOf(context));
    final double barHeight = FloatingGlassNavbarMetrics.barHeight(
      compact: compact,
    );
    final double systemBottom = MediaQuery.paddingOf(context).bottom;

    final tabs = <({String icon, String label})>[
      (icon: AppIcons.home, label: l10n.home),
      (icon: AppIcons.songs, label: l10n.songs),
      (icon: AppIcons.library, label: l10n.library),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FloatingGlassNavbarMetrics.horizontalMargin,
        FloatingGlassNavbarMetrics.topPadding,
        FloatingGlassNavbarMetrics.horizontalMargin,
        FloatingGlassNavbarMetrics.bottomMargin(compact: compact) +
            systemBottom,
      ),
      child: SizedBox(
        height: barHeight,
        child: RepaintBoundary(
          child: BackdropGroup(
            child: Row(
              children: [
                Expanded(
                  child: _GlassShape(
                    circle: false,
                    blur: blur,
                    palette: palette,
                    child: _TabStrip(
                      position: _position,
                      tabs: tabs,
                      currentIndex: widget.currentIndex,
                      palette: palette,
                      compact: compact,
                      onTap: (index) {
                        AppHaptics.tick();
                        widget.onTap(index);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: FloatingGlassNavbarMetrics.gap),
                SizedBox.square(
                  dimension: barHeight,
                  child: _GlassShape(
                    circle: true,
                    blur: blur,
                    palette: palette,
                    child: Semantics(
                      button: true,
                      label: l10n.search,
                      child: InkWell(
                        key: const ValueKey('glass_nav_search'),
                        customBorder: const CircleBorder(),
                        onTap: () {
                          AppHaptics.tick();
                          widget.onSearch();
                        },
                        child: Center(
                          child: Icon(
                            LucideIcons.search,
                            size: compact ? 20 : 24,
                            color: palette.selected,
                          ),
                        ),
                      ),
                    ),
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

/// One glass surface: soft shadow, then (clipped to the shape) the blurred
/// backdrop, the tint, sheen and rim, then [child].
class _GlassShape extends StatelessWidget {
  const _GlassShape({
    required this.circle,
    required this.blur,
    required this.palette,
    required this.child,
  });

  final bool circle;
  final bool blur;
  final GlassPalette palette;
  final Widget child;

  static final ui.ImageFilter _filter = ui.ImageFilter.compose(
    // A touch more saturation, so colors under the glass read as "seen
    // through" it rather than washed out.
    outer: const ColorFilter.matrix(_saturate125),
    inner: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
  );

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = circle
        ? const CircleBorder()
        : const StadiumBorder();
    final Widget surface = CustomPaint(
      painter: _GlassPainter(palette: palette, circle: circle, blur: blur),
      child: Material(type: MaterialType.transparency, child: child),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: blur
            ? BackdropFilter.grouped(filter: _filter, child: surface)
            : surface,
      ),
    );
  }
}

/// Saturation 1.25 (Rec. 709 luma weights).
const List<double> _saturate125 = [
  1.1968, -0.1788, -0.0180, 0, 0, //
  -0.0532, 1.1462, -0.0180, 0, 0, //
  -0.0532, -0.1788, 1.2320, 0, 0, //
  0, 0, 0, 1, 0, //
];

class _GlassPainter extends CustomPainter {
  const _GlassPainter({
    required this.palette,
    required this.circle,
    required this.blur,
  });

  final GlassPalette palette;
  final bool circle;
  final bool blur;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide / 2),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = blur ? palette.fill : palette.solidFill,
    );
    // Lens sheen: light along the top, a faint darkening at the bottom,
    // which reads as the glass bending the light near its edges.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          [
            palette.sheen,
            palette.sheen.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.06),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    // Thin rim, brightest on the top edge.
    final RRect rim = rrect.deflate(0.5);
    canvas.drawRRect(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          palette.rimTop,
          palette.rimBottom,
        ]),
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) =>
      old.palette != palette || old.circle != circle || old.blur != blur;
}

/// The three tabs over the sliding capsule.
class _TabStrip extends StatelessWidget {
  const _TabStrip({
    required this.position,
    required this.tabs,
    required this.currentIndex,
    required this.palette,
    required this.compact,
    required this.onTap,
  });

  final AnimationController position;
  final List<({String icon, String label})> tabs;
  final int currentIndex;
  final GlassPalette palette;
  final bool compact;
  final ValueChanged<int> onTap;

  static const double _capsuleInset = 5;

  @override
  Widget build(BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final double slotWidth = constraints.maxWidth / tabs.length;
        final Widget capsule = SizedBox(
          width: slotWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: const EdgeInsets.all(_capsuleInset),
            child: RepaintBoundary(
              child: CustomPaint(painter: _CapsulePainter(palette)),
            ),
          ),
        );
        return Stack(
          children: [
            // Only this Transform changes while the capsule springs.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                // Its own layer, so a spring frame only moves it and never
                // re-records the glass around it.
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: position,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        glassCapsuleOffset(
                          position: position.value,
                          count: tabs.length,
                          slotWidth: slotWidth,
                          direction: direction,
                        ),
                        0,
                      ),
                      child: child,
                    ),
                    child: capsule,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _GlassTab(
                      key: ValueKey('glass_nav_tab_$i'),
                      icon: tabs[i].icon,
                      label: tabs[i].label,
                      selected: i == currentIndex,
                      palette: palette,
                      compact: compact,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _CapsulePainter extends CustomPainter {
  const _CapsulePainter(this.palette);

  final GlassPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );
    // A hard, low-alpha drop below the capsule instead of a blurred
    // shadow: it reads as raised and costs a single fill.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()..color = palette.shadow.withValues(alpha: 0.18),
    );
    canvas.drawRRect(rrect, Paint()..color = palette.capsuleFill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          Colors.white.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0),
        ]),
    );
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          palette.capsuleRim,
          palette.capsuleRim.withValues(alpha: 0.08),
        ]),
    );
  }

  @override
  bool shouldRepaint(_CapsulePainter old) => old.palette != palette;
}

class _GlassTab extends StatelessWidget {
  const _GlassTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.palette,
    required this.compact,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final GlassPalette palette;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Color only (same weight and size either way), so a tab change only
    // repaints the labels; it never lays them out again.
    final Color color = selected ? palette.selected : palette.unselected;
    final double iconSize = compact ? 18 : 22;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            if (!compact) const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.jostStyle(
                  textStyle: const TextStyle(inherit: false),
                  color: color,
                  fontSize: compact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
