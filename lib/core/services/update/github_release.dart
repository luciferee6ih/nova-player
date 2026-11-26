/// Which APK set this app updates from: `offline` here, `online` in the
/// online build. Must match the release asset names.
const apkEdition = 'offline';

/// One APK attached to a GitHub release.
class ApkAsset {
  final String name;
  final String url;
  final int size;

  /// Lower-case hex SHA-256 as published by GitHub, or null for releases
  /// uploaded before GitHub started recording asset digests.
  final String? sha256;

  const ApkAsset({
    required this.name,
    required this.url,
    required this.size,
    this.sha256,
  });
}

/// The parts of a GitHub `releases/latest` response the updater uses.
class GithubRelease {
  final String tag;
  final String name;
  final String htmlUrl;
  final String notes;
  final String? publishedAt;
  final List<ApkAsset> apks;

  /// Every file on the release, including the Linux packages.
  final List<ApkAsset> assets;

  const GithubRelease({
    required this.tag,
    this.name = '',
    required this.htmlUrl,
    required this.notes,
    this.publishedAt,
    required this.apks,
    this.assets = const [],
  });

  factory GithubRelease.fromJson(
    Map<String, dynamic> json, {
    required String fallbackHtmlUrl,
  }) {
    final assets = <ApkAsset>[];
    for (final asset in (json['assets'] as List?) ?? const []) {
      if (asset is! Map) continue;
      final name = asset['name'];
      final url = asset['browser_download_url'];
      final size = asset['size'];
      if (name is! String || url is! String || size is! int) continue;
      final digest = asset['digest'];
      assets.add(
        ApkAsset(
          name: name,
          url: url,
          size: size,
          sha256: digest is String && digest.startsWith('sha256:')
              ? digest.substring(7).toLowerCase()
              : null,
        ),
      );
    }
    return GithubRelease(
      tag: (json['tag_name'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      htmlUrl: (json['html_url'] as String?) ?? fallbackHtmlUrl,
      notes: ((json['body'] as String?) ?? '').trim(),
      publishedAt: json['published_at'] as String?,
      apks: [
        for (final asset in assets)
          if (asset.name.toLowerCase().endsWith('.apk')) asset,
      ],
      assets: assets,
    );
  }

  /// The APK to install on a device whose ABIs are [abis], most preferred
  /// first (Android's `Build.SUPPORTED_ABIS`): the first per-ABI split that
  /// matches, else the universal APK, else null.
  ///
  /// Releases carry both editions (`...-arm64-v8a-online-release.apk` and
  /// `...-offline-release.apk`); only [apkEdition]'s APKs are considered.
  /// A release with no labelled APKs (before the split) uses its unlabelled ones.
  static bool _labelled(ApkAsset a, String edition) =>
      a.name.toLowerCase().contains('-$edition-');

  /// The release carries the other edition's APKs but not ours yet: the
  /// online APKs are uploaded by hand after the release workflow finishes.
  bool get waitingForMyApk =>
      apks.any((a) => _labelled(a, 'online') || _labelled(a, 'offline')) &&
      !apks.any((a) => _labelled(a, apkEdition));

  ApkAsset? apkFor(List<String> abis) {
    const labelled = _labelled;
    final mine = apks.where((a) => labelled(a, apkEdition)).toList();
    final pool = mine.isNotEmpty
        ? mine
        : apks
              .where((a) => !labelled(a, 'online') && !labelled(a, 'offline'))
              .toList();
    for (final abi in abis) {
      final marker = '-${abi.toLowerCase()}-';
      for (final apk in pool) {
        if (apk.name.toLowerCase().contains(marker)) return apk;
      }
    }
    for (final apk in pool) {
      if (apk.name.toLowerCase().contains('universal')) return apk;
    }
    return null;
  }
}

/// Whether version [latest] (a release tag such as `2.6` or `v2.7.1-rc.1`) is
/// newer than [current]. Compares the dotted numbers first; missing parts
/// count as zero, so `2.6` equals `2.6.0`. When the numbers are equal, a
/// final release is newer than a pre-release of it (`1.0.0` > `1.0.0-beta`)
/// and pre-releases compare by their dot-separated identifiers, numbers
/// numerically (`1.0.0-beta.2` > `1.0.0-beta`). Build metadata (`+12`) is
/// ignored.
bool isNewerVersion(String current, String latest) {
  // Start at the first number ('release-2.0.0' -> '2.0.0') and drop build
  // metadata.
  String core(String version) {
    final match = RegExp(r'^\D*(\d+(\..*)?)$').firstMatch(version.trim());
    return (match != null ? match.group(1)! : version).split('+')[0];
  }

  List<int> parts(String version) {
    var clean = core(version).split('-')[0];
    clean = clean.replaceAll(RegExp(r'[^0-9.]'), '');
    return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  String preRelease(String version) {
    final c = core(version);
    final dash = c.indexOf('-');
    return dash < 0 ? '' : c.substring(dash + 1);
  }

  final currentParts = parts(current);
  final latestParts = parts(latest);
  final length = currentParts.length > latestParts.length
      ? currentParts.length
      : latestParts.length;
  for (int i = 0; i < length; i++) {
    final c = i < currentParts.length ? currentParts[i] : 0;
    final l = i < latestParts.length ? latestParts[i] : 0;
    if (l > c) return true;
    if (l < c) return false;
  }

  final cPre = preRelease(current);
  final lPre = preRelease(latest);
  if (cPre == lPre) return false;
  if (lPre.isEmpty) return true; // final release of the same version
  if (cPre.isEmpty) return false;
  final cIds = cPre.split('.');
  final lIds = lPre.split('.');
  for (int i = 0; i < cIds.length && i < lIds.length; i++) {
    final cn = int.tryParse(cIds[i]);
    final ln = int.tryParse(lIds[i]);
    final int cmp;
    if (cn != null && ln != null) {
      cmp = ln.compareTo(cn);
    } else if (cn != null) {
      cmp = 1; // alphanumeric identifiers rank above numeric ones
    } else if (ln != null) {
      cmp = -1;
    } else {
      cmp = lIds[i].compareTo(cIds[i]);
    }
    if (cmp != 0) return cmp > 0;
  }
  return lIds.length > cIds.length;
}
