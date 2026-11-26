import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/core/services/device_performance.dart';
import 'package:nova_player/features/library/domain/models/models.dart';
import 'package:nova_player/features/settings/data/nova_feature_settings.dart';
import 'package:nova_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:nova_player/l10n/app_localizations.dart';
import 'package:nova_player/ui/android/shell/floating_glass_navbar.dart';

class _FakeSettings extends Settings {
  @override
  AppSettings build() => AppSettings();
}

class _FakeFeatures extends NovaFeatureSettingsNotifier {
  _FakeFeatures(this.initial);
  final NovaFeatureSettings initial;
  @override
  NovaFeatureSettings build() => initial;
}

Widget _host({
  required int index,
  required ValueChanged<int> onTap,
  VoidCallback? onSearch,
  TextDirection direction = TextDirection.ltr,
  NovaFeatureSettings features = const NovaFeatureSettings(),
  bool disableAnimations = false,
}) {
  return ProviderScope(
    // Overrides are fixed once a scope is mounted: a new scope per setup.
    key: ValueKey(features),
    overrides: [
      settingsProvider.overrideWith(_FakeSettings.new),
      novaFeatureSettingsProvider.overrideWith(() => _FakeFeatures(features)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          disableAnimations: disableAnimations,
        ),
        child: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: FloatingGlassNavbar(
                currentIndex: index,
                onTap: onTap,
                onSearch: onSearch ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('glassCapsuleOffset', () {
    test('moves left to right in LTR', () {
      for (int i = 0; i < 3; i++) {
        expect(
          glassCapsuleOffset(
            position: i.toDouble(),
            count: 3,
            slotWidth: 100,
            direction: TextDirection.ltr,
          ),
          i * 100,
        );
      }
    });

    test('mirrors in RTL: the first tab sits on the right', () {
      expect(
        glassCapsuleOffset(
          position: 0,
          count: 3,
          slotWidth: 100,
          direction: TextDirection.rtl,
        ),
        200,
      );
      expect(
        glassCapsuleOffset(
          position: 2,
          count: 3,
          slotWidth: 100,
          direction: TextDirection.rtl,
        ),
        0,
      );
    });

    test('is continuous mid-spring', () {
      expect(
        glassCapsuleOffset(
          position: 0.5,
          count: 3,
          slotWidth: 80,
          direction: TextDirection.ltr,
        ),
        40,
      );
    });
  });

  group('FloatingGlassNavbarMetrics', () {
    test('includes the system inset and is no taller than the classic bar', () {
      const inset = 24.0;
      final glass = FloatingGlassNavbarMetrics.totalHeight(
        compact: false,
        systemBottom: inset,
      );
      expect(glass, 2 + 64 + 16 + inset);
      // Classic slot: 72 + 18 + inset. Content padded for the classic bar
      // is therefore never hidden behind the glass one.
      expect(glass, lessThanOrEqualTo(72 + 18 + inset));
      expect(
        FloatingGlassNavbarMetrics.totalHeight(compact: true, systemBottom: 0),
        lessThanOrEqualTo(56 + 10),
      );
    });
  });

  group('GlassPalette', () {
    test('differs between dark, AMOLED and light', () {
      const accent = Color(0xFF3F8CFF);
      final dark = GlassPalette.resolve(
        accent: accent,
        surface: const Color(0xFF11110E),
        brightness: Brightness.dark,
      );
      final amoled = GlassPalette.resolve(
        accent: accent,
        surface: Colors.black,
        brightness: Brightness.dark,
      );
      final light = GlassPalette.resolve(
        accent: accent,
        surface: Colors.white,
        brightness: Brightness.light,
      );
      expect(dark == amoled, isFalse);
      expect(dark == light, isFalse);
      // The no-blur fill is near opaque so text stays legible.
      expect(dark.solidFill.a, greaterThan(0.9));
      expect(light.unselected.computeLuminance(), lessThan(0.2));
    });

    test('follows the accent', () {
      final a = GlassPalette.resolve(
        accent: Colors.red,
        surface: Colors.black,
        brightness: Brightness.dark,
      );
      final b = GlassPalette.resolve(
        accent: Colors.blue,
        surface: Colors.black,
        brightness: Brightness.dark,
      );
      expect(a.selected == b.selected, isFalse);
      expect(a.fill == b.fill, isFalse);
    });
  });

  group('FloatingGlassNavbar widget', () {
    testWidgets('taps report the tab and search', (tester) async {
      int? tapped;
      var searched = false;
      await tester.pumpWidget(
        _host(
          index: 0,
          onTap: (i) => tapped = i,
          onSearch: () => searched = true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('glass_nav_tab_2')));
      expect(tapped, 2);
      await tester.tap(find.byKey(const ValueKey('glass_nav_search')));
      expect(searched, isTrue);
    });

    testWidgets('one BackdropFilter per glass shape, none when reduced', (
      tester,
    ) async {
      await tester.pumpWidget(_host(index: 0, onTap: (_) {}));
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(find.byType(BackdropGroup), findsOneWidget);

      await tester.pumpWidget(
        _host(
          index: 0,
          onTap: (_) {},
          features: const NovaFeatureSettings(reduceEffects: true),
        ),
      );
      await tester.pump();
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('selection springs without relayout and settles', (
      tester,
    ) async {
      await tester.pumpWidget(_host(index: 0, onTap: (_) {}));
      await tester.pump();
      final strip = tester.getRect(
        find.byKey(const ValueKey('glass_nav_tab_0')),
      );
      final Finder capsule = find.descendant(
        of: find.byType(FloatingGlassNavbar),
        matching: find.byType(Transform),
      );
      double capsuleDx() =>
          tester.widget<Transform>(capsule.first).transform.getTranslation().x;
      expect(capsuleDx(), 0);

      await tester.pumpWidget(_host(index: 2, onTap: (_) {}));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = capsuleDx();
      expect(mid, greaterThan(0));
      expect(mid, lessThan(strip.width * 2));
      await tester.pumpAndSettle();
      expect(capsuleDx(), closeTo(strip.width * 2, 0.5));
      // The tabs themselves never moved.
      expect(
        tester.getRect(find.byKey(const ValueKey('glass_nav_tab_0'))),
        strip,
      );
    });

    testWidgets('RTL mirrors the order', (tester) async {
      await tester.pumpWidget(
        _host(index: 0, onTap: (_) {}, direction: TextDirection.rtl),
      );
      await tester.pump();
      final home = tester.getCenter(
        find.byKey(const ValueKey('glass_nav_tab_0')),
      );
      final library = tester.getCenter(
        find.byKey(const ValueKey('glass_nav_tab_2')),
      );
      final search = tester.getCenter(
        find.byKey(const ValueKey('glass_nav_search')),
      );
      expect(home.dx, greaterThan(library.dx));
      // Search sits at the trailing end: on the left in RTL.
      expect(search.dx, lessThan(library.dx));
    });

    testWidgets('reduced motion jumps straight to the tab', (tester) async {
      await tester.pumpWidget(
        _host(index: 0, onTap: (_) {}, disableAnimations: true),
      );
      await tester.pump();
      await tester.pumpWidget(
        _host(index: 1, onTap: (_) {}, disableAnimations: true),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      // And no blur with animations off.
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });

  group('DevicePerformance.classify', () {
    test('Redmi 12-class phones count as slower', () {
      // Helio G88: 2.0 GHz big cores, 4 GB.
      expect(
        DevicePerformance.classify(
          memTotalKb: 3800000,
          maxCpuKhz: 2000000,
          cores: 8,
        ),
        isTrue,
      );
      // 8 GB variant: still the 2.0 GHz chip.
      expect(
        DevicePerformance.classify(
          memTotalKb: 7700000,
          maxCpuKhz: 2000000,
          cores: 8,
        ),
        isTrue,
      );
    });

    test('flagships do not', () {
      expect(
        DevicePerformance.classify(
          memTotalKb: 11500000,
          maxCpuKhz: 3300000,
          cores: 8,
        ),
        isFalse,
      );
    });

    test('unknown numbers fall back to the core count', () {
      expect(DevicePerformance.classify(cores: 4), isTrue);
      expect(DevicePerformance.classify(cores: 8), isFalse);
    });
  });

  group('NovaFeatureSettings', () {
    test('defaults: glass navbar on, everything else off', () {
      const s = NovaFeatureSettings();
      expect(s.navbarStyle, NavbarStyle.floatingGlass);
      expect(s.beatGlass, isFalse);
      expect(s.harmonicQueue, isFalse);
      expect(s.reduceEffects, isNull);
    });

    test('round-trips through JSON and tolerates unknown values', () {
      const s = NovaFeatureSettings(
        playerBackgroundStyle: PlayerBackgroundStyle.beatGlass,
        reduceEffects: true,
        harmonicQueue: true,
        navbarStyle: NavbarStyle.classic,
      );
      expect(NovaFeatureSettings.fromJson(s.toJson()), s);
      final odd = NovaFeatureSettings.fromJson({
        'navbarStyle': 'nope',
        'playerBackgroundStyle': 7,
      });
      expect(odd, const NovaFeatureSettings());
    });
  });
}
