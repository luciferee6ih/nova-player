import 'package:isar_community/isar.dart';

part 'track_analysis.g.dart';

/// Cached tempo / key analysis of one library song, keyed by the song's
/// Isar id. [fileSize] and [modifiedMs] tell whether the file changed
/// since (then it's analyzed again). A song that couldn't be decoded is
/// cached too ([failed]), so it isn't retried on every queue change.
@collection
class TrackAnalysis {
  TrackAnalysis();

  /// The Song's id.
  Id id = Isar.autoIncrement;

  late String path;
  int fileSize = 0;
  int modifiedMs = 0;

  double? bpm;
  double bpmConfidence = 0;

  /// [CamelotKey.index] (0-23), null when unsure.
  short? keyIndex;
  double keyConfidence = 0;

  bool failed = false;

  /// Bumped when the analysis changes enough to redo old results.
  int analyzerVersion = 0;

  late DateTime analyzedAt;
}
