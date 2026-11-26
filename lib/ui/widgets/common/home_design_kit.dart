import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nova_player/core/theme/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pieces of the Home design (Figma "iPhone 17 - 617…621"), shared by the
/// hero and the local sections.

/// Secondary text on Home: song artists, card subtitles, section labels.
const kHomeGrey = Color(0xFF808080);

/// The pale pill / circle behind the hero's Play and dice buttons.
const kHomeHeroButton = Color(0xFFE9E9E9);
const kHomeHeroButtonInk = Color(0xFF1D1D1D);

// Icons traced from the design file, in their own boxes.
/// NOVA Player note mark (white), same glyph as the launcher logo.
const _logoSvg =
    '<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M1.19 9.32 L1.36 9.34 L1.57 9.36 L1.83 9.40 L2.11 9.43 L2.42 9.47 L2.74 9.50 L3.06 9.52 L3.37 9.53 L3.66 9.52 L3.93 9.49 L4.19 9.44 L4.44 9.37 L4.69 9.30 L4.93 9.21 L5.17 9.10 L5.41 8.99 L5.63 8.87 L5.85 8.73 L6.06 8.59 L6.25 8.43 L6.44 8.25 L6.62 8.03 L6.78 7.78 L6.94 7.52 L7.10 7.25 L7.24 6.99 L7.37 6.76 L7.50 6.56 L7.62 6.41 L7.73 6.33 L7.83 6.30 L7.93 6.31 L8.02 6.36 L8.10 6.45 L8.18 6.56 L8.24 6.70 L8.29 6.86 L8.33 7.02 L8.35 7.20 L8.36 7.38 L8.35 7.57 L8.34 7.79 L8.30 8.03 L8.26 8.29 L8.20 8.55 L8.13 8.83 L8.05 9.11 L7.96 9.38 L7.85 9.65 L7.73 9.91 L7.58 10.16 L7.41 10.42 L7.22 10.67 L7.00 10.92 L6.79 11.18 L6.57 11.43 L6.35 11.68 L6.16 11.93 L5.98 12.19 L5.83 12.44 L5.70 12.70 L5.58 12.96 L5.46 13.22 L5.36 13.48 L5.27 13.74 L5.20 14.00 L5.14 14.25 L5.11 14.50 L5.10 14.74 L5.11 14.97 L5.16 15.20 L5.23 15.44 L5.33 15.68 L5.45 15.91 L5.59 16.14 L5.74 16.35 L5.91 16.55 L6.08 16.72 L6.27 16.87 L6.46 17.00 L6.67 17.09 L6.91 17.17 L7.16 17.23 L7.43 17.26 L7.70 17.28 L7.98 17.28 L8.25 17.26 L8.52 17.22 L8.77 17.16 L8.99 17.08 L9.21 16.98 L9.42 16.86 L9.62 16.72 L9.82 16.56 L10.01 16.39 L10.19 16.19 L10.36 15.97 L10.51 15.73 L10.65 15.47 L10.77 15.18 L10.86 14.87 L10.94 14.54 L11.00 14.18 L11.05 13.80 L11.08 13.40 L11.11 12.99 L11.13 12.55 L11.15 12.11 L11.17 11.65 L11.19 11.18 L11.21 10.69 L11.22 10.17 L11.23 9.62 L11.23 9.06 L11.23 8.50 L11.23 7.92 L11.23 7.35 L11.23 6.78 L11.23 6.23 L11.23 5.69 L11.23 5.15 L11.24 4.59 L11.24 4.01 L11.25 3.43 L11.25 2.86 L11.26 2.32 L11.26 1.83 L11.27 1.39 L11.27 1.01 L11.27 0.72" stroke="white" stroke-width="1.43" stroke-linecap="round" stroke-linejoin="round" fill="none"/><path d="M11.27 0.72 L11.32 0.77 L11.38 0.83 L11.44 0.91 L11.51 0.99 L11.60 1.08 L11.69 1.19 L11.79 1.30 L11.90 1.42 L12.02 1.55 L12.16 1.69 L12.31 1.84 L12.47 2.01 L12.65 2.19 L12.84 2.38 L13.04 2.58 L13.25 2.78 L13.45 2.99 L13.66 3.19 L13.86 3.39 L14.05 3.58 L14.25 3.77 L14.45 3.96 L14.66 4.15 L14.86 4.34 L15.07 4.53 L15.27 4.72 L15.46 4.91 L15.64 5.10 L15.81 5.29 L15.95 5.48 L16.09 5.68 L16.21 5.87 L16.32 6.07 L16.43 6.27 L16.52 6.47 L16.60 6.67 L16.67 6.86 L16.73 7.04 L16.77 7.22 L16.80 7.38 L16.81 7.54 L16.80 7.69 L16.78 7.84 L16.75 7.98 L16.71 8.12 L16.66 8.25 L16.59 8.36 L16.52 8.47 L16.45 8.56 L16.37 8.65 L16.29 8.71 L16.18 8.77 L16.07 8.82 L15.95 8.86 L15.82 8.88 L15.69 8.90 L15.56 8.90 L15.44 8.90 L15.33 8.88 L15.24 8.86 L15.15 8.81 L15.07 8.74 L14.99 8.65 L14.92 8.55 L14.85 8.45 L14.79 8.34 L14.73 8.24 L14.68 8.14 L14.64 8.07 L14.60 8.01" stroke="white" stroke-width="1.43" stroke-linecap="round" stroke-linejoin="round" fill="none"/><circle cx="15.40" cy="8.14" r="1.10" fill="white"/></svg>';

const _searchSvg =
    '<svg viewBox="303.3 73.8 15.4 14.4" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M317.461 86.9999L314.691 84.2305" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke="white" fill="none"/>'
    '<path d="M315.617 80.5389C315.617 83.5979 313.137 86.0778 310.078 86.0778C307.019 86.0778 304.539 83.5979 304.539 80.5389C304.539 77.4798 307.019 75 310.078 75C313.137 75 315.617 77.4798 315.617 80.5389Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" stroke="white" fill="none"/>'
    '</svg>';

const _profileSvg =
    '<svg viewBox="351.5 73.5 15 15" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M355.667 76.8333C355.667 75.9493 356.018 75.1014 356.643 74.4763C357.268 73.8512 358.116 73.5 359 73.5C359.884 73.5 360.732 73.8512 361.357 74.4763C361.982 75.1014 362.333 75.9493 362.333 76.8333C362.333 77.7174 361.982 78.5652 361.357 79.1904C360.732 79.8155 359.884 80.1667 359 80.1667C358.116 80.1667 357.268 79.8155 356.643 79.1904C356.018 78.5652 355.667 77.7174 355.667 76.8333ZM355.667 81.8333C354.562 81.8333 353.502 82.2723 352.72 83.0537C351.939 83.8351 351.5 84.8949 351.5 86C351.5 86.663 351.763 87.2989 352.232 87.7678C352.701 88.2366 353.337 88.5 354 88.5H364C364.663 88.5 365.299 88.2366 365.768 87.7678C366.237 87.2989 366.5 86.663 366.5 86C366.5 84.8949 366.061 83.8351 365.28 83.0537C364.498 82.2723 363.438 81.8333 362.333 81.8333H355.667Z" fill-rule="evenodd" fill="white"/>'
    '</svg>';

const _playSvg =
    '<svg viewBox="300 327.9 13 14.2" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M301.58 328.178C302.872 327.577 304.537 328.537 307.869 330.459C311.2 332.382 312.865 333.343 312.99 334.762C313.003 334.92 313.003 335.08 312.99 335.238C312.865 336.657 311.2 337.618 307.869 339.541C304.537 341.463 302.872 342.423 301.58 341.822C301.436 341.754 301.298 341.674 301.167 341.583C300 340.766 300 338.844 300 335C300 331.156 300 329.234 301.167 328.417C301.298 328.326 301.436 328.246 301.58 328.178Z" fill="#1D1D1D"/>'
    '</svg>';

const _diceSvg =
    '<svg viewBox="342.9 311.5 18.9 19" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M360.216 314.831L348.626 311.721C348.115 311.583 347.569 311.655 347.11 311.919C346.65 312.183 346.315 312.619 346.176 313.131L343.066 324.721C342.786 325.781 343.416 326.881 344.476 327.171L356.066 330.281C356.236 330.331 356.406 330.351 356.576 330.351C357.456 330.351 358.266 329.761 358.506 328.871L361.616 317.281C361.896 316.221 361.266 315.121 360.206 314.831H360.216ZM351.386 320.751C351.176 321.551 350.346 322.031 349.546 321.811C348.746 321.601 348.276 320.771 348.486 319.971C348.696 319.171 349.526 318.691 350.326 318.911C351.126 319.121 351.596 319.951 351.386 320.751ZM356.216 322.041C356.006 322.841 355.176 323.311 354.376 323.101C353.576 322.891 353.096 322.061 353.316 321.261C353.526 320.461 354.356 319.991 355.156 320.201C355.956 320.411 356.436 321.241 356.216 322.041Z" fill="black"/>'
    '</svg>';

class HomeIcons {
  static Widget logo({double width = 18}) =>
      SvgPicture.string(_logoSvg, width: width);
  static Widget search({double width = 15}) =>
      SvgPicture.string(_searchSvg, width: width);
  static Widget profile({double width = 15}) =>
      SvgPicture.string(_profileSvg, width: width);
  static Widget play({double width = 13}) =>
      SvgPicture.string(_playSvg, width: width);
  static Widget dice({double width = 19}) =>
      SvgPicture.string(_diceSvg, width: width);
}

/// A round button: the 42px 20%-black header buttons over the hero, and the
/// 41px 10%-white play / arrow buttons beside section titles.
class HomeRoundButton extends StatelessWidget {
  const HomeRoundButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 41,
    this.color = const Color(0x1AFFFFFF),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// The "View All →" pill beside section titles: 41px, 10% white.
class HomeViewAllPill extends StatelessWidget {
  const HomeViewAllPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x1AFFFFFF),
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 41,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: homeDisplay(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

/// Card and row text in the design: DM Sans at its regular weight, white
/// titles over grey subtitles, whatever app font is picked.
TextStyle homeCardTitle({double size = 16}) => AppFonts.familyStyle(
  AppFonts.dmSans,
  weightDelta: 0,
  color: Colors.white,
  fontSize: size,
  letterSpacing: 0,
);

TextStyle homeCardSub({double size = 14}) => AppFonts.familyStyle(
  AppFonts.dmSans,
  weightDelta: 0,
  color: kHomeGrey,
  fontSize: size,
  letterSpacing: 0,
);

/// Headings, buttons and card titles in the design: Stack Sans, whatever
/// app font is picked (card and row text is DM Sans, [homeCardTitle]).
TextStyle homeDisplay({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) => AppFonts.familyStyle(
  AppFonts.stackSansText,
  weightDelta: 0,
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
  height: height,
  letterSpacing: AppFonts.spacingFor(fontSize),
);

/// A section title split the design's way: a grey label over a big title.
/// "Mixed for you" -> "Mixed" / "For You"; with [name] (an artist the
/// shelf is about) "More from Drake" -> "More From" / "Drake"; otherwise
/// the first word is the label: "Listen again" -> "Listen" / "Again".
/// One word stays a plain title.
(String?, String) splitShelfTitle(String title, {String? name}) {
  final t = title.trim();
  final n = name?.trim();
  if (n != null && n.isNotEmpty && t.length > n.length) {
    final i = t.toLowerCase().lastIndexOf(n.toLowerCase());
    if (i >= 0) {
      final label = (t.substring(0, i) + t.substring(i + n.length)).trim();
      if (label.isNotEmpty) {
        return (_titleCase(label), t.substring(i, i + n.length));
      }
    }
  }
  final forYou = RegExp(
    r'^(.+?)\s+for you$',
    caseSensitive: false,
  ).firstMatch(t);
  if (forYou != null) return (_titleCase(forYou[1]!), 'For You');
  final words = t.split(RegExp(r'\s+'));
  if (words.length < 2) return (null, t);
  final lead = words.first.toLowerCase() == 'from' && words.length > 2 ? 2 : 1;
  return (
    _titleCase(words.take(lead).join(' ')),
    _titleCase(words.skip(lead).join(' ')),
  );
}

String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// The small white play glyph in a 41px section button.
const homeSectionPlayIcon = Icon(
  Icons.play_arrow_rounded,
  size: 22,
  color: Colors.white,
);

/// A section title as in the design: a bold title (20px), or a grey
/// [label] over a larger title ("Picks" / "For You"), with [trailing]
/// buttons at the right.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.label,
    this.trailing,
    this.padding = const EdgeInsetsDirectional.fromSTEB(23, 36, 16, 16),
  });

  final String title;
  final String? label;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: homeDisplay(
        color: Colors.white,
        fontSize: label == null ? 20 : 28,
        fontWeight: FontWeight.bold,
        // Under a label the two lines sit tight, as in the design.
        height: label == null ? 1.15 : 1.0,
      ),
    );
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: label == null
                ? titleText
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: homeDisplay(
                          color: kHomeGrey,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      titleText,
                    ],
                  ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// ← → buttons that page a horizontal row, as on "Discover New Artists".
class HomeRowArrows extends StatelessWidget {
  const HomeRowArrows({super.key, required this.controller});

  final ScrollController controller;

  void _page(BuildContext context, int dir) {
    if (!controller.hasClients) return;
    final p = controller.position;
    final target = (p.pixels + dir * p.viewportDimension * 0.8).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = MaterialLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeRoundButton(
          semanticLabel: m.previousPageTooltip,
          onTap: () => _page(context, -1),
          child: const Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        HomeRoundButton(
          semanticLabel: m.nextPageTooltip,
          onTap: () => _page(context, 1),
          child: const Icon(
            LucideIcons.arrowRight,
            size: 18,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Owns a [ScrollController] for [builder]: lets a stateless row hand the
/// same controller to its list and to its [HomeRowArrows].
class ScrollControllerScope extends StatefulWidget {
  const ScrollControllerScope({super.key, required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<ScrollControllerScope> createState() => _ScrollControllerScopeState();
}

class _ScrollControllerScopeState extends State<ScrollControllerScope> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
