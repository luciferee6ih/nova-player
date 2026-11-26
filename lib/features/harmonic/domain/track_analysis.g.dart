// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_analysis.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetTrackAnalysisCollection on Isar {
  IsarCollection<TrackAnalysis> get trackAnalysis => this.collection();
}

const TrackAnalysisSchema = CollectionSchema(
  name: r'TrackAnalysis',
  id: 3988381114529608715,
  properties: {
    r'analyzedAt': PropertySchema(
      id: 0,
      name: r'analyzedAt',
      type: IsarType.dateTime,
    ),
    r'analyzerVersion': PropertySchema(
      id: 1,
      name: r'analyzerVersion',
      type: IsarType.long,
    ),
    r'bpm': PropertySchema(id: 2, name: r'bpm', type: IsarType.double),
    r'bpmConfidence': PropertySchema(
      id: 3,
      name: r'bpmConfidence',
      type: IsarType.double,
    ),
    r'failed': PropertySchema(id: 4, name: r'failed', type: IsarType.bool),
    r'fileSize': PropertySchema(id: 5, name: r'fileSize', type: IsarType.long),
    r'keyConfidence': PropertySchema(
      id: 6,
      name: r'keyConfidence',
      type: IsarType.double,
    ),
    r'keyIndex': PropertySchema(id: 7, name: r'keyIndex', type: IsarType.int),
    r'modifiedMs': PropertySchema(
      id: 8,
      name: r'modifiedMs',
      type: IsarType.long,
    ),
    r'path': PropertySchema(id: 9, name: r'path', type: IsarType.string),
  },

  estimateSize: _trackAnalysisEstimateSize,
  serialize: _trackAnalysisSerialize,
  deserialize: _trackAnalysisDeserialize,
  deserializeProp: _trackAnalysisDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _trackAnalysisGetId,
  getLinks: _trackAnalysisGetLinks,
  attach: _trackAnalysisAttach,
  version: '3.4.1',
);

int _trackAnalysisEstimateSize(
  TrackAnalysis object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.path.length * 3;
  return bytesCount;
}

void _trackAnalysisSerialize(
  TrackAnalysis object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.analyzedAt);
  writer.writeLong(offsets[1], object.analyzerVersion);
  writer.writeDouble(offsets[2], object.bpm);
  writer.writeDouble(offsets[3], object.bpmConfidence);
  writer.writeBool(offsets[4], object.failed);
  writer.writeLong(offsets[5], object.fileSize);
  writer.writeDouble(offsets[6], object.keyConfidence);
  writer.writeInt(offsets[7], object.keyIndex);
  writer.writeLong(offsets[8], object.modifiedMs);
  writer.writeString(offsets[9], object.path);
}

TrackAnalysis _trackAnalysisDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TrackAnalysis();
  object.analyzedAt = reader.readDateTime(offsets[0]);
  object.analyzerVersion = reader.readLong(offsets[1]);
  object.bpm = reader.readDoubleOrNull(offsets[2]);
  object.bpmConfidence = reader.readDouble(offsets[3]);
  object.failed = reader.readBool(offsets[4]);
  object.fileSize = reader.readLong(offsets[5]);
  object.id = id;
  object.keyConfidence = reader.readDouble(offsets[6]);
  object.keyIndex = reader.readIntOrNull(offsets[7]);
  object.modifiedMs = reader.readLong(offsets[8]);
  object.path = reader.readString(offsets[9]);
  return object;
}

P _trackAnalysisDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readIntOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _trackAnalysisGetId(TrackAnalysis object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _trackAnalysisGetLinks(TrackAnalysis object) {
  return [];
}

void _trackAnalysisAttach(
  IsarCollection<dynamic> col,
  Id id,
  TrackAnalysis object,
) {
  object.id = id;
}

extension TrackAnalysisQueryWhereSort
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QWhere> {
  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TrackAnalysisQueryWhere
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QWhereClause> {
  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension TrackAnalysisQueryFilter
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QFilterCondition> {
  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'analyzedAt', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'analyzedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'analyzedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'analyzedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzerVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'analyzerVersion', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzerVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'analyzerVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzerVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'analyzerVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  analyzerVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'analyzerVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'bpm'),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'bpm'),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> bpmEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'bpm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bpm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> bpmLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bpm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> bpmBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bpm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmConfidenceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'bpmConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmConfidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bpmConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmConfidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bpmConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  bpmConfidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bpmConfidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  failedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'failed', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  fileSizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileSize', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  fileSizeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  fileSizeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  fileSizeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyConfidenceEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'keyConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyConfidenceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'keyConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyConfidenceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'keyConfidence',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyConfidenceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'keyConfidence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'keyIndex'),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'keyIndex'),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'keyIndex', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyIndexGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'keyIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyIndexLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'keyIndex',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  keyIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'keyIndex',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  modifiedMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'modifiedMs', value: value),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  modifiedMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'modifiedMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  modifiedMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'modifiedMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  modifiedMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'modifiedMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> pathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> pathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'path',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'path',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition> pathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'path',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'path', value: ''),
      );
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterFilterCondition>
  pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'path', value: ''),
      );
    });
  }
}

extension TrackAnalysisQueryObject
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QFilterCondition> {}

extension TrackAnalysisQueryLinks
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QFilterCondition> {}

extension TrackAnalysisQuerySortBy
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QSortBy> {
  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByAnalyzedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzedAt', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByAnalyzedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzedAt', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByAnalyzerVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzerVersion', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByAnalyzerVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzerVersion', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByBpmConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpmConfidence', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByBpmConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpmConfidence', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByKeyConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyConfidence', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByKeyConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyConfidence', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyIndex', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByKeyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyIndex', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByModifiedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedMs', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  sortByModifiedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedMs', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }
}

extension TrackAnalysisQuerySortThenBy
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QSortThenBy> {
  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByAnalyzedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzedAt', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByAnalyzedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzedAt', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByAnalyzerVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzerVersion', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByAnalyzerVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'analyzerVersion', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByBpmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpm', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByBpmConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpmConfidence', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByBpmConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bpmConfidence', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByFileSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileSize', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByKeyConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyConfidence', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByKeyConfidenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyConfidence', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyIndex', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByKeyIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'keyIndex', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByModifiedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedMs', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy>
  thenByModifiedMsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'modifiedMs', Sort.desc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QAfterSortBy> thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }
}

extension TrackAnalysisQueryWhereDistinct
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> {
  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByAnalyzedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'analyzedAt');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct>
  distinctByAnalyzerVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'analyzerVersion');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByBpm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bpm');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct>
  distinctByBpmConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bpmConfidence');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failed');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByFileSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileSize');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct>
  distinctByKeyConfidence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyConfidence');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByKeyIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'keyIndex');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByModifiedMs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'modifiedMs');
    });
  }

  QueryBuilder<TrackAnalysis, TrackAnalysis, QDistinct> distinctByPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }
}

extension TrackAnalysisQueryProperty
    on QueryBuilder<TrackAnalysis, TrackAnalysis, QQueryProperty> {
  QueryBuilder<TrackAnalysis, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TrackAnalysis, DateTime, QQueryOperations> analyzedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'analyzedAt');
    });
  }

  QueryBuilder<TrackAnalysis, int, QQueryOperations> analyzerVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'analyzerVersion');
    });
  }

  QueryBuilder<TrackAnalysis, double?, QQueryOperations> bpmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bpm');
    });
  }

  QueryBuilder<TrackAnalysis, double, QQueryOperations>
  bpmConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bpmConfidence');
    });
  }

  QueryBuilder<TrackAnalysis, bool, QQueryOperations> failedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failed');
    });
  }

  QueryBuilder<TrackAnalysis, int, QQueryOperations> fileSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileSize');
    });
  }

  QueryBuilder<TrackAnalysis, double, QQueryOperations>
  keyConfidenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyConfidence');
    });
  }

  QueryBuilder<TrackAnalysis, int?, QQueryOperations> keyIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'keyIndex');
    });
  }

  QueryBuilder<TrackAnalysis, int, QQueryOperations> modifiedMsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'modifiedMs');
    });
  }

  QueryBuilder<TrackAnalysis, String, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }
}
