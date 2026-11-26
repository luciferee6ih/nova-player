import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nova_player/core/services/device_performance.dart';
import 'package:nova_player/core/services/storage/local_json_store.dart';

/// How the classic Now Playing background is drawn.
enum PlayerBackgroundStyle {
  /// Blurred artwork, the player gradient or the surface, as set by the
  /// other background options.
  standard,

  /// A liquid-glass surface tinted from the artwork with ripples that pulse
  /// on the beat.
  beatGlass;

  static PlayerBackgroundStyle fromName(Object? name) =>
      PlayerBackgroundStyle.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PlayerBackgroundStyle.standard,
      );
}

/// The bottom navigation bar on phones.
enum NavbarStyle {
  /// A floating liquid-glass pill with a separate round Search button.
  floatingGlass,

  /// The original sectioned bar.
  classic;

  static NavbarStyle fromName(Object? name) => NavbarStyle.values.firstWhere(
    (s) => s.name == name,
    orElse: () => NavbarStyle.floatingGlass,
  );
}

/// Settings of the newer optional features (Beat Glass, Reduce effects,
/// Harmonic Queue). Kept in [LocalJsonStore] like the crossfade settings,
/// so they never need an Isar schema migration. Everything is off by
/// default.
class NovaFeatureSettings {
  const NovaFeatureSettings({
    this.playerBackgroundStyle = PlayerBackgroundStyle.standard,
    this.reduceEffects,
    this.harmonicQueue = false,
    this.navbarStyle = NavbarStyle.floatingGlass,
  });

  final NavbarStyle navbarStyle;

  final PlayerBackgroundStyle playerBackgroundStyle;

  /// The user's "Reduce effects on slower phones" choice. Null = never
  /// touched: follows [DevicePerformance.isLowEnd].
  final bool? reduceEffects;

  /// Reorder the upcoming queue by key and tempo compatibility.
  final bool harmonicQueue;

  bool get beatGlass =>
      playerBackgroundStyle == PlayerBackgroundStyle.beatGlass;

  /// Whether effects run in their cheap, still form right now.
  bool get reduceEffectsActive => reduceEffects ?? DevicePerformance.isLowEnd;

  NovaFeatureSettings copyWith({
    PlayerBackgroundStyle? playerBackgroundStyle,
    Object? reduceEffects = _keep,
    bool? harmonicQueue,
    NavbarStyle? navbarStyle,
  }) => NovaFeatureSettings(
    playerBackgroundStyle: playerBackgroundStyle ?? this.playerBackgroundStyle,
    reduceEffects: identical(reduceEffects, _keep)
        ? this.reduceEffects
        : reduceEffects as bool?,
    harmonicQueue: harmonicQueue ?? this.harmonicQueue,
    navbarStyle: navbarStyle ?? this.navbarStyle,
  );

  Map<String, dynamic> toJson() => {
    'playerBackgroundStyle': playerBackgroundStyle.name,
    'reduceEffects': reduceEffects,
    'harmonicQueue': harmonicQueue,
    'navbarStyle': navbarStyle.name,
  };

  factory NovaFeatureSettings.fromJson(Map<String, dynamic> json) =>
      NovaFeatureSettings(
        playerBackgroundStyle: PlayerBackgroundStyle.fromName(
          json['playerBackgroundStyle'],
        ),
        reduceEffects: json['reduceEffects'] as bool?,
        harmonicQueue: json['harmonicQueue'] as bool? ?? false,
        navbarStyle: NavbarStyle.fromName(json['navbarStyle']),
      );

  @override
  bool operator ==(Object other) =>
      other is NovaFeatureSettings &&
      other.playerBackgroundStyle == playerBackgroundStyle &&
      other.reduceEffects == reduceEffects &&
      other.harmonicQueue == harmonicQueue &&
      other.navbarStyle == navbarStyle;

  @override
  int get hashCode => Object.hash(
    playerBackgroundStyle,
    reduceEffects,
    harmonicQueue,
    navbarStyle,
  );
}

const Object _keep = Object();

class NovaFeatureSettingsNotifier extends Notifier<NovaFeatureSettings> {
  static const storeKey = 'nova_feature_settings_v1';

  @override
  NovaFeatureSettings build() {
    final cached = LocalJsonStore.readSync(storeKey);
    if (cached is Map) {
      return NovaFeatureSettings.fromJson(Map<String, dynamic>.from(cached));
    }
    _load();
    return const NovaFeatureSettings();
  }

  Future<void> _load() async {
    final raw = await LocalJsonStore.read(storeKey);
    if (raw is Map) {
      state = NovaFeatureSettings.fromJson(Map<String, dynamic>.from(raw));
    }
  }

  Future<void> _update(
    NovaFeatureSettings Function(NovaFeatureSettings) transform,
  ) async {
    final next = transform(state);
    if (next == state) return;
    state = next;
    await LocalJsonStore.write(storeKey, next.toJson());
  }

  Future<void> setPlayerBackgroundStyle(PlayerBackgroundStyle style) =>
      _update((s) => s.copyWith(playerBackgroundStyle: style));

  Future<void> setReduceEffects(bool value) =>
      _update((s) => s.copyWith(reduceEffects: value));

  Future<void> setNavbarStyle(NavbarStyle style) =>
      _update((s) => s.copyWith(navbarStyle: style));

  Future<void> setHarmonicQueue(bool value) =>
      _update((s) => s.copyWith(harmonicQueue: value));
}

final novaFeatureSettingsProvider =
    NotifierProvider<NovaFeatureSettingsNotifier, NovaFeatureSettings>(
      NovaFeatureSettingsNotifier.new,
    );
