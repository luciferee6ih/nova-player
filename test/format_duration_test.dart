import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/core/utils/ui_utils.dart';

void main() {
  group('UiUtils.formatPlaybackDuration', () {
    test('minutes and seconds are zero padded', () {
      expect(UiUtils.formatPlaybackDuration(const Duration(seconds: 5)), '00:05');
      expect(
        UiUtils.formatPlaybackDuration(const Duration(minutes: 3, seconds: 7)),
        '03:07',
      );
    });

    test('hours appear when needed or requested', () {
      expect(
        UiUtils.formatPlaybackDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
      expect(
        UiUtils.formatPlaybackDuration(
          const Duration(minutes: 4),
          showHours: true,
        ),
        '0:04:00',
      );
    });

    test('negative durations clamp to zero', () {
      expect(
        UiUtils.formatPlaybackDuration(const Duration(seconds: -10)),
        '00:00',
      );
    });
  });
}
