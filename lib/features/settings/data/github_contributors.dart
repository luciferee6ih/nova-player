import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nova_player/core/utils/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_contributors.g.dart';

/// One person in the About screen's developer row.
class GithubContributor {
  final String login;
  final String profileUrl;
  final String? avatarUrl;

  /// Optional bundled avatar.
  final String? avatarAsset;

  const GithubContributor({
    required this.login,
    required this.profileUrl,
    this.avatarUrl,
    this.avatarAsset,
  });

  Map<String, dynamic> toJson() => {
    'login': login,
    'html_url': profileUrl,
    'avatar_url': avatarUrl,
  };

  static GithubContributor? fromJson(Object? json) {
    if (json is! Map) return null;
    final login = json['login'];
    final url = json['html_url'];
    if (login is! String || url is! String) return null;
    final avatar = json['avatar_url'];
    return GithubContributor(
      login: login,
      profileUrl: url,
      avatarUrl: avatar is String ? avatar : null,
    );
  }
}

/// The developer credited on the About screen.
const developers = [
  GithubContributor(
    login: AppLinks.developerName,
    profileUrl: AppLinks.developerTelegram,
    avatarUrl: 'https://avatars.githubusercontent.com/luciferee6ih?v=4',
  ),
];

/// The About screen's developer row. A fixed list (no network): the app
/// credits its developer, not everyone in the repository history.
@Riverpod(keepAlive: true)
Stream<List<GithubContributor>> githubContributors(Ref ref) async* {
  yield developers;
}

/// Stargazer count of [AppLinks.githubStatsRepo]; null while loading/offline.
final githubStarsProvider = FutureProvider<int?>((ref) async {
  try {
    final response = await http
        .get(
          Uri.parse(AppLinks.githubStatsRepoApi),
          headers: const {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final stars = (jsonDecode(response.body) as Map)['stargazers_count'];
    return stars is int ? stars : null;
  } catch (e) {
    debugPrint('githubStars: $e');
    return null;
  }
});
