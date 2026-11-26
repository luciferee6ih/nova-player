import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/core/services/update/github_release.dart';

void main() {
  group('isNewerVersion', () {
    test('final release is newer than its beta', () {
      expect(isNewerVersion('1.0.0-beta', '1.0.0'), isTrue);
      expect(isNewerVersion('1.0.0', '1.0.0-beta'), isFalse);
    });

    test('later pre-releases are newer', () {
      expect(isNewerVersion('1.0.0-beta', 'v1.0.0-beta.2'), isTrue);
      expect(isNewerVersion('1.0.0-beta.2', '1.0.0-beta.10'), isTrue);
      expect(isNewerVersion('1.0.0-beta', '1.0.0-rc.1'), isTrue);
      expect(isNewerVersion('1.0.0-beta.2', '1.0.0-beta'), isFalse);
    });

    test('same version is not newer', () {
      expect(isNewerVersion('1.0.0-beta', '1.0.0-beta'), isFalse);
      expect(isNewerVersion('2.6', 'v2.6.0'), isFalse);
    });

    test('numbers win over pre-release tags', () {
      expect(isNewerVersion('1.0.0-beta', '0.9.9'), isFalse);
      expect(isNewerVersion('1.0.0-beta', '1.0.1-alpha'), isTrue);
      expect(isNewerVersion('2.6.0', 'release-2.7'), isTrue);
    });

    test('build metadata is ignored', () {
      expect(isNewerVersion('1.0.0-beta+1', '1.0.0-beta+5'), isFalse);
    });
  });
}
