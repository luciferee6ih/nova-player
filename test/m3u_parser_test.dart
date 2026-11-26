import 'package:flutter_test/flutter_test.dart';
import 'package:nova_player/features/playlists/data/m3u_parser.dart';

void main() {
  group('M3uParser.parse', () {
    test('reads extended M3U titles and artists', () {
      final entries = M3uParser.parse(
        '#EXTM3U\n'
        '#EXTINF:215,Some Artist - Some Title\n'
        'Music/song.mp3\n'
        '#EXTINF:100,Only Title\r\n'
        'C:\\Music\\other.flac\n',
      );
      expect(entries, hasLength(2));
      expect(entries[0].path, 'Music/song.mp3');
      expect(entries[0].artist, 'Some Artist');
      expect(entries[0].title, 'Some Title');
      expect(entries[1].path, 'C:/Music/other.flac');
      expect(entries[1].title, 'Only Title');
      expect(entries[1].artist, isNull);
    });

    test('skips network streams and decodes file URLs', () {
      final entries = M3uParser.parse(
        'http://radio.example/stream\n'
        'file:///home/me/My%20Song.mp3\n',
      );
      expect(entries.map((e) => e.path), ['/home/me/My Song.mp3']);
    });
  });

  group('uniquePlaylistName', () {
    test('adds the first free number', () {
      expect(uniquePlaylistName('Mix', {}), 'Mix');
      expect(uniquePlaylistName('Mix', {'Mix'}), 'Mix (2)');
      expect(uniquePlaylistName('Mix', {'Mix', 'Mix (2)'}), 'Mix (3)');
    });
  });
}
