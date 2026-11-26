import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/core/utils/app_links.dart';

void main() {
  test('every repo URL derives from githubOwnerRepo', () {
    const repo = AppLinks.githubOwnerRepo;
    expect(repo, 'luciferee6ih/nova-player');
    expect(AppLinks.githubRepo, 'https://github.com/$repo');
    expect(AppLinks.githubReleasesApi,
        'https://api.github.com/repos/$repo/releases/latest');
    expect(AppLinks.githubReleasesWeb, 'https://github.com/$repo/releases');
    expect(AppLinks.githubStatsRepoApi, contains(repo));
  });

  test('donation links are empty; developer contact is set', () {
    expect(AppLinks.koFi, isEmpty);
    expect(AppLinks.playStoreWeb, isEmpty);
    expect(AppLinks.socialTelegram, 'https://t.me/theacproject');
    expect(AppLinks.developerName, 'theluciferee');
    expect(AppLinks.developerTelegram, 'https://t.me/theluciferee');
  });
}
