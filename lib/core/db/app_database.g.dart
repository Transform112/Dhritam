// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageRmssdMeta = const VerificationMeta(
    'averageRmssd',
  );
  @override
  late final GeneratedColumn<double> averageRmssd = GeneratedColumn<double>(
    'average_rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signalQualityMeta = const VerificationMeta(
    'signalQuality',
  );
  @override
  late final GeneratedColumn<double> signalQuality = GeneratedColumn<double>(
    'signal_quality',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startTime,
    endTime,
    averageRmssd,
    signalQuality,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('average_rmssd')) {
      context.handle(
        _averageRmssdMeta,
        averageRmssd.isAcceptableOrUnknown(
          data['average_rmssd']!,
          _averageRmssdMeta,
        ),
      );
    }
    if (data.containsKey('signal_quality')) {
      context.handle(
        _signalQualityMeta,
        signalQuality.isAcceptableOrUnknown(
          data['signal_quality']!,
          _signalQualityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      averageRmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_rmssd'],
      ),
      signalQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}signal_quality'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double? averageRmssd;
  final double? signalQuality;
  const Session({
    required this.id,
    required this.startTime,
    this.endTime,
    this.averageRmssd,
    this.signalQuality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || averageRmssd != null) {
      map['average_rmssd'] = Variable<double>(averageRmssd);
    }
    if (!nullToAbsent || signalQuality != null) {
      map['signal_quality'] = Variable<double>(signalQuality);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      averageRmssd: averageRmssd == null && nullToAbsent
          ? const Value.absent()
          : Value(averageRmssd),
      signalQuality: signalQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(signalQuality),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      averageRmssd: serializer.fromJson<double?>(json['averageRmssd']),
      signalQuality: serializer.fromJson<double?>(json['signalQuality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'averageRmssd': serializer.toJson<double?>(averageRmssd),
      'signalQuality': serializer.toJson<double?>(signalQuality),
    };
  }

  Session copyWith({
    String? id,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<double?> averageRmssd = const Value.absent(),
    Value<double?> signalQuality = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    averageRmssd: averageRmssd.present ? averageRmssd.value : this.averageRmssd,
    signalQuality: signalQuality.present
        ? signalQuality.value
        : this.signalQuality,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      averageRmssd: data.averageRmssd.present
          ? data.averageRmssd.value
          : this.averageRmssd,
      signalQuality: data.signalQuality.present
          ? data.signalQuality.value
          : this.signalQuality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('averageRmssd: $averageRmssd, ')
          ..write('signalQuality: $signalQuality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startTime, endTime, averageRmssd, signalQuality);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.averageRmssd == this.averageRmssd &&
          other.signalQuality == this.signalQuality);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<double?> averageRmssd;
  final Value<double?> signalQuality;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.averageRmssd = const Value.absent(),
    this.signalQuality = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.averageRmssd = const Value.absent(),
    this.signalQuality = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startTime = Value(startTime);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<double>? averageRmssd,
    Expression<double>? signalQuality,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (averageRmssd != null) 'average_rmssd': averageRmssd,
      if (signalQuality != null) 'signal_quality': signalQuality,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<double?>? averageRmssd,
    Value<double?>? signalQuality,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      averageRmssd: averageRmssd ?? this.averageRmssd,
      signalQuality: signalQuality ?? this.signalQuality,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (averageRmssd.present) {
      map['average_rmssd'] = Variable<double>(averageRmssd.value);
    }
    if (signalQuality.present) {
      map['signal_quality'] = Variable<double>(signalQuality.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('averageRmssd: $averageRmssd, ')
          ..write('signalQuality: $signalQuality, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HrvWindowsTable extends HrvWindows
    with TableInfo<$HrvWindowsTable, HrvWindow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HrvWindowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rmssdMeta = const VerificationMeta('rmssd');
  @override
  late final GeneratedColumn<double> rmssd = GeneratedColumn<double>(
    'rmssd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReliableMeta = const VerificationMeta(
    'isReliable',
  );
  @override
  late final GeneratedColumn<bool> isReliable = GeneratedColumn<bool>(
    'is_reliable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reliable" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    timestamp,
    rmssd,
    bpm,
    isReliable,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hrv_windows';
  @override
  VerificationContext validateIntegrity(
    Insertable<HrvWindow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('rmssd')) {
      context.handle(
        _rmssdMeta,
        rmssd.isAcceptableOrUnknown(data['rmssd']!, _rmssdMeta),
      );
    } else if (isInserting) {
      context.missing(_rmssdMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    if (data.containsKey('is_reliable')) {
      context.handle(
        _isReliableMeta,
        isReliable.isAcceptableOrUnknown(data['is_reliable']!, _isReliableMeta),
      );
    } else if (isInserting) {
      context.missing(_isReliableMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HrvWindow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HrvWindow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      rmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rmssd'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      isReliable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reliable'],
      )!,
    );
  }

  @override
  $HrvWindowsTable createAlias(String alias) {
    return $HrvWindowsTable(attachedDatabase, alias);
  }
}

class HrvWindow extends DataClass implements Insertable<HrvWindow> {
  final int id;
  final String sessionId;
  final DateTime timestamp;
  final double rmssd;
  final int bpm;
  final bool isReliable;
  const HrvWindow({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.rmssd,
    required this.bpm,
    required this.isReliable,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['rmssd'] = Variable<double>(rmssd);
    map['bpm'] = Variable<int>(bpm);
    map['is_reliable'] = Variable<bool>(isReliable);
    return map;
  }

  HrvWindowsCompanion toCompanion(bool nullToAbsent) {
    return HrvWindowsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      timestamp: Value(timestamp),
      rmssd: Value(rmssd),
      bpm: Value(bpm),
      isReliable: Value(isReliable),
    );
  }

  factory HrvWindow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HrvWindow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      rmssd: serializer.fromJson<double>(json['rmssd']),
      bpm: serializer.fromJson<int>(json['bpm']),
      isReliable: serializer.fromJson<bool>(json['isReliable']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'rmssd': serializer.toJson<double>(rmssd),
      'bpm': serializer.toJson<int>(bpm),
      'isReliable': serializer.toJson<bool>(isReliable),
    };
  }

  HrvWindow copyWith({
    int? id,
    String? sessionId,
    DateTime? timestamp,
    double? rmssd,
    int? bpm,
    bool? isReliable,
  }) => HrvWindow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    timestamp: timestamp ?? this.timestamp,
    rmssd: rmssd ?? this.rmssd,
    bpm: bpm ?? this.bpm,
    isReliable: isReliable ?? this.isReliable,
  );
  HrvWindow copyWithCompanion(HrvWindowsCompanion data) {
    return HrvWindow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      rmssd: data.rmssd.present ? data.rmssd.value : this.rmssd,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      isReliable: data.isReliable.present
          ? data.isReliable.value
          : this.isReliable,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HrvWindow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rmssd: $rmssd, ')
          ..write('bpm: $bpm, ')
          ..write('isReliable: $isReliable')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, timestamp, rmssd, bpm, isReliable);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HrvWindow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.timestamp == this.timestamp &&
          other.rmssd == this.rmssd &&
          other.bpm == this.bpm &&
          other.isReliable == this.isReliable);
}

class HrvWindowsCompanion extends UpdateCompanion<HrvWindow> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<DateTime> timestamp;
  final Value<double> rmssd;
  final Value<int> bpm;
  final Value<bool> isReliable;
  const HrvWindowsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rmssd = const Value.absent(),
    this.bpm = const Value.absent(),
    this.isReliable = const Value.absent(),
  });
  HrvWindowsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required DateTime timestamp,
    required double rmssd,
    required int bpm,
    required bool isReliable,
  }) : sessionId = Value(sessionId),
       timestamp = Value(timestamp),
       rmssd = Value(rmssd),
       bpm = Value(bpm),
       isReliable = Value(isReliable);
  static Insertable<HrvWindow> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<DateTime>? timestamp,
    Expression<double>? rmssd,
    Expression<int>? bpm,
    Expression<bool>? isReliable,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (timestamp != null) 'timestamp': timestamp,
      if (rmssd != null) 'rmssd': rmssd,
      if (bpm != null) 'bpm': bpm,
      if (isReliable != null) 'is_reliable': isReliable,
    });
  }

  HrvWindowsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<DateTime>? timestamp,
    Value<double>? rmssd,
    Value<int>? bpm,
    Value<bool>? isReliable,
  }) {
    return HrvWindowsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      rmssd: rmssd ?? this.rmssd,
      bpm: bpm ?? this.bpm,
      isReliable: isReliable ?? this.isReliable,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rmssd.present) {
      map['rmssd'] = Variable<double>(rmssd.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (isReliable.present) {
      map['is_reliable'] = Variable<bool>(isReliable.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HrvWindowsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('timestamp: $timestamp, ')
          ..write('rmssd: $rmssd, ')
          ..write('bpm: $bpm, ')
          ..write('isReliable: $isReliable')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $HrvWindowsTable hrvWindows = $HrvWindowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessions, hrvWindows];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<double?> averageRmssd,
      Value<double?> signalQuality,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<double?> averageRmssd,
      Value<double?> signalQuality,
      Value<int> rowid,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HrvWindowsTable, List<HrvWindow>>
  _hrvWindowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.hrvWindows,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.hrvWindows.sessionId),
  );

  $$HrvWindowsTableProcessedTableManager get hrvWindowsRefs {
    final manager = $$HrvWindowsTableTableManager(
      $_db,
      $_db.hrvWindows,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_hrvWindowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageRmssd => $composableBuilder(
    column: $table.averageRmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get signalQuality => $composableBuilder(
    column: $table.signalQuality,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> hrvWindowsRefs(
    Expression<bool> Function($$HrvWindowsTableFilterComposer f) f,
  ) {
    final $$HrvWindowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hrvWindows,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HrvWindowsTableFilterComposer(
            $db: $db,
            $table: $db.hrvWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageRmssd => $composableBuilder(
    column: $table.averageRmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get signalQuality => $composableBuilder(
    column: $table.signalQuality,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<double> get averageRmssd => $composableBuilder(
    column: $table.averageRmssd,
    builder: (column) => column,
  );

  GeneratedColumn<double> get signalQuality => $composableBuilder(
    column: $table.signalQuality,
    builder: (column) => column,
  );

  Expression<T> hrvWindowsRefs<T extends Object>(
    Expression<T> Function($$HrvWindowsTableAnnotationComposer a) f,
  ) {
    final $$HrvWindowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.hrvWindows,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HrvWindowsTableAnnotationComposer(
            $db: $db,
            $table: $db.hrvWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool hrvWindowsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<double?> averageRmssd = const Value.absent(),
                Value<double?> signalQuality = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startTime: startTime,
                endTime: endTime,
                averageRmssd: averageRmssd,
                signalQuality: signalQuality,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<double?> averageRmssd = const Value.absent(),
                Value<double?> signalQuality = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startTime: startTime,
                endTime: endTime,
                averageRmssd: averageRmssd,
                signalQuality: signalQuality,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({hrvWindowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (hrvWindowsRefs) db.hrvWindows],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (hrvWindowsRefs)
                    await $_getPrefetchedData<
                      Session,
                      $SessionsTable,
                      HrvWindow
                    >(
                      currentTable: table,
                      referencedTable: $$SessionsTableReferences
                          ._hrvWindowsRefsTable(db),
                      managerFromTypedResult: (p0) => $$SessionsTableReferences(
                        db,
                        table,
                        p0,
                      ).hrvWindowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool hrvWindowsRefs})
    >;
typedef $$HrvWindowsTableCreateCompanionBuilder =
    HrvWindowsCompanion Function({
      Value<int> id,
      required String sessionId,
      required DateTime timestamp,
      required double rmssd,
      required int bpm,
      required bool isReliable,
    });
typedef $$HrvWindowsTableUpdateCompanionBuilder =
    HrvWindowsCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<DateTime> timestamp,
      Value<double> rmssd,
      Value<int> bpm,
      Value<bool> isReliable,
    });

final class $$HrvWindowsTableReferences
    extends BaseReferences<_$AppDatabase, $HrvWindowsTable, HrvWindow> {
  $$HrvWindowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.hrvWindows.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HrvWindowsTableFilterComposer
    extends Composer<_$AppDatabase, $HrvWindowsTable> {
  $$HrvWindowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReliable => $composableBuilder(
    column: $table.isReliable,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HrvWindowsTableOrderingComposer
    extends Composer<_$AppDatabase, $HrvWindowsTable> {
  $$HrvWindowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rmssd => $composableBuilder(
    column: $table.rmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReliable => $composableBuilder(
    column: $table.isReliable,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HrvWindowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HrvWindowsTable> {
  $$HrvWindowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get rmssd =>
      $composableBuilder(column: $table.rmssd, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<bool> get isReliable => $composableBuilder(
    column: $table.isReliable,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HrvWindowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HrvWindowsTable,
          HrvWindow,
          $$HrvWindowsTableFilterComposer,
          $$HrvWindowsTableOrderingComposer,
          $$HrvWindowsTableAnnotationComposer,
          $$HrvWindowsTableCreateCompanionBuilder,
          $$HrvWindowsTableUpdateCompanionBuilder,
          (HrvWindow, $$HrvWindowsTableReferences),
          HrvWindow,
          PrefetchHooks Function({bool sessionId})
        > {
  $$HrvWindowsTableTableManager(_$AppDatabase db, $HrvWindowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HrvWindowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HrvWindowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HrvWindowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> rmssd = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<bool> isReliable = const Value.absent(),
              }) => HrvWindowsCompanion(
                id: id,
                sessionId: sessionId,
                timestamp: timestamp,
                rmssd: rmssd,
                bpm: bpm,
                isReliable: isReliable,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required DateTime timestamp,
                required double rmssd,
                required int bpm,
                required bool isReliable,
              }) => HrvWindowsCompanion.insert(
                id: id,
                sessionId: sessionId,
                timestamp: timestamp,
                rmssd: rmssd,
                bpm: bpm,
                isReliable: isReliable,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HrvWindowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$HrvWindowsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$HrvWindowsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HrvWindowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HrvWindowsTable,
      HrvWindow,
      $$HrvWindowsTableFilterComposer,
      $$HrvWindowsTableOrderingComposer,
      $$HrvWindowsTableAnnotationComposer,
      $$HrvWindowsTableCreateCompanionBuilder,
      $$HrvWindowsTableUpdateCompanionBuilder,
      (HrvWindow, $$HrvWindowsTableReferences),
      HrvWindow,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$HrvWindowsTableTableManager get hrvWindows =>
      $$HrvWindowsTableTableManager(_db, _db.hrvWindows);
}
