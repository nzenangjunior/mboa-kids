// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_database.dart';

// ignore_for_file: type=lint
class $ItemProgressRowsTable extends ItemProgressRows
    with TableInfo<$ItemProgressRowsTable, ItemProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ItemState>($ItemProgressRowsTable.$converterstate);
  static const VerificationMeta _correctFirstTryCountMeta =
      const VerificationMeta('correctFirstTryCount');
  @override
  late final GeneratedColumn<int> correctFirstTryCount = GeneratedColumn<int>(
    'correct_first_try_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _consecutiveWrongMeta = const VerificationMeta(
    'consecutiveWrong',
  );
  @override
  late final GeneratedColumn<int> consecutiveWrong = GeneratedColumn<int>(
    'consecutive_wrong',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _acquiredAtMeta = const VerificationMeta(
    'acquiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> acquiredAt = GeneratedColumn<DateTime>(
    'acquired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewStageMeta = const VerificationMeta(
    'reviewStage',
  );
  @override
  late final GeneratedColumn<int> reviewStage = GeneratedColumn<int>(
    'review_stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextDueAtMeta = const VerificationMeta(
    'nextDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueAt = GeneratedColumn<DateTime>(
    'next_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    state,
    correctFirstTryCount,
    consecutiveWrong,
    acquiredAt,
    reviewStage,
    nextDueAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_progress_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('correct_first_try_count')) {
      context.handle(
        _correctFirstTryCountMeta,
        correctFirstTryCount.isAcceptableOrUnknown(
          data['correct_first_try_count']!,
          _correctFirstTryCountMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_wrong')) {
      context.handle(
        _consecutiveWrongMeta,
        consecutiveWrong.isAcceptableOrUnknown(
          data['consecutive_wrong']!,
          _consecutiveWrongMeta,
        ),
      );
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
        _acquiredAtMeta,
        acquiredAt.isAcceptableOrUnknown(data['acquired_at']!, _acquiredAtMeta),
      );
    }
    if (data.containsKey('review_stage')) {
      context.handle(
        _reviewStageMeta,
        reviewStage.isAcceptableOrUnknown(
          data['review_stage']!,
          _reviewStageMeta,
        ),
      );
    }
    if (data.containsKey('next_due_at')) {
      context.handle(
        _nextDueAtMeta,
        nextDueAt.isAcceptableOrUnknown(data['next_due_at']!, _nextDueAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  ItemProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemProgressRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      state: $ItemProgressRowsTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      correctFirstTryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_first_try_count'],
      )!,
      consecutiveWrong: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_wrong'],
      )!,
      acquiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acquired_at'],
      ),
      reviewStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_stage'],
      )!,
      nextDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_at'],
      ),
    );
  }

  @override
  $ItemProgressRowsTable createAlias(String alias) {
    return $ItemProgressRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemState, int, int> $converterstate =
      const EnumIndexConverter<ItemState>(ItemState.values);
}

class ItemProgressRow extends DataClass implements Insertable<ItemProgressRow> {
  final String itemId;
  final ItemState state;
  final int correctFirstTryCount;
  final int consecutiveWrong;
  final DateTime? acquiredAt;
  final int reviewStage;
  final DateTime? nextDueAt;
  const ItemProgressRow({
    required this.itemId,
    required this.state,
    required this.correctFirstTryCount,
    required this.consecutiveWrong,
    this.acquiredAt,
    required this.reviewStage,
    this.nextDueAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    {
      map['state'] = Variable<int>(
        $ItemProgressRowsTable.$converterstate.toSql(state),
      );
    }
    map['correct_first_try_count'] = Variable<int>(correctFirstTryCount);
    map['consecutive_wrong'] = Variable<int>(consecutiveWrong);
    if (!nullToAbsent || acquiredAt != null) {
      map['acquired_at'] = Variable<DateTime>(acquiredAt);
    }
    map['review_stage'] = Variable<int>(reviewStage);
    if (!nullToAbsent || nextDueAt != null) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt);
    }
    return map;
  }

  ItemProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return ItemProgressRowsCompanion(
      itemId: Value(itemId),
      state: Value(state),
      correctFirstTryCount: Value(correctFirstTryCount),
      consecutiveWrong: Value(consecutiveWrong),
      acquiredAt: acquiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acquiredAt),
      reviewStage: Value(reviewStage),
      nextDueAt: nextDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueAt),
    );
  }

  factory ItemProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemProgressRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      state: $ItemProgressRowsTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      correctFirstTryCount: serializer.fromJson<int>(
        json['correctFirstTryCount'],
      ),
      consecutiveWrong: serializer.fromJson<int>(json['consecutiveWrong']),
      acquiredAt: serializer.fromJson<DateTime?>(json['acquiredAt']),
      reviewStage: serializer.fromJson<int>(json['reviewStage']),
      nextDueAt: serializer.fromJson<DateTime?>(json['nextDueAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'state': serializer.toJson<int>(
        $ItemProgressRowsTable.$converterstate.toJson(state),
      ),
      'correctFirstTryCount': serializer.toJson<int>(correctFirstTryCount),
      'consecutiveWrong': serializer.toJson<int>(consecutiveWrong),
      'acquiredAt': serializer.toJson<DateTime?>(acquiredAt),
      'reviewStage': serializer.toJson<int>(reviewStage),
      'nextDueAt': serializer.toJson<DateTime?>(nextDueAt),
    };
  }

  ItemProgressRow copyWith({
    String? itemId,
    ItemState? state,
    int? correctFirstTryCount,
    int? consecutiveWrong,
    Value<DateTime?> acquiredAt = const Value.absent(),
    int? reviewStage,
    Value<DateTime?> nextDueAt = const Value.absent(),
  }) => ItemProgressRow(
    itemId: itemId ?? this.itemId,
    state: state ?? this.state,
    correctFirstTryCount: correctFirstTryCount ?? this.correctFirstTryCount,
    consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
    acquiredAt: acquiredAt.present ? acquiredAt.value : this.acquiredAt,
    reviewStage: reviewStage ?? this.reviewStage,
    nextDueAt: nextDueAt.present ? nextDueAt.value : this.nextDueAt,
  );
  ItemProgressRow copyWithCompanion(ItemProgressRowsCompanion data) {
    return ItemProgressRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      state: data.state.present ? data.state.value : this.state,
      correctFirstTryCount: data.correctFirstTryCount.present
          ? data.correctFirstTryCount.value
          : this.correctFirstTryCount,
      consecutiveWrong: data.consecutiveWrong.present
          ? data.consecutiveWrong.value
          : this.consecutiveWrong,
      acquiredAt: data.acquiredAt.present
          ? data.acquiredAt.value
          : this.acquiredAt,
      reviewStage: data.reviewStage.present
          ? data.reviewStage.value
          : this.reviewStage,
      nextDueAt: data.nextDueAt.present ? data.nextDueAt.value : this.nextDueAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemProgressRow(')
          ..write('itemId: $itemId, ')
          ..write('state: $state, ')
          ..write('correctFirstTryCount: $correctFirstTryCount, ')
          ..write('consecutiveWrong: $consecutiveWrong, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('reviewStage: $reviewStage, ')
          ..write('nextDueAt: $nextDueAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    itemId,
    state,
    correctFirstTryCount,
    consecutiveWrong,
    acquiredAt,
    reviewStage,
    nextDueAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemProgressRow &&
          other.itemId == this.itemId &&
          other.state == this.state &&
          other.correctFirstTryCount == this.correctFirstTryCount &&
          other.consecutiveWrong == this.consecutiveWrong &&
          other.acquiredAt == this.acquiredAt &&
          other.reviewStage == this.reviewStage &&
          other.nextDueAt == this.nextDueAt);
}

class ItemProgressRowsCompanion extends UpdateCompanion<ItemProgressRow> {
  final Value<String> itemId;
  final Value<ItemState> state;
  final Value<int> correctFirstTryCount;
  final Value<int> consecutiveWrong;
  final Value<DateTime?> acquiredAt;
  final Value<int> reviewStage;
  final Value<DateTime?> nextDueAt;
  final Value<int> rowid;
  const ItemProgressRowsCompanion({
    this.itemId = const Value.absent(),
    this.state = const Value.absent(),
    this.correctFirstTryCount = const Value.absent(),
    this.consecutiveWrong = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.reviewStage = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemProgressRowsCompanion.insert({
    required String itemId,
    required ItemState state,
    this.correctFirstTryCount = const Value.absent(),
    this.consecutiveWrong = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.reviewStage = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       state = Value(state);
  static Insertable<ItemProgressRow> custom({
    Expression<String>? itemId,
    Expression<int>? state,
    Expression<int>? correctFirstTryCount,
    Expression<int>? consecutiveWrong,
    Expression<DateTime>? acquiredAt,
    Expression<int>? reviewStage,
    Expression<DateTime>? nextDueAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (state != null) 'state': state,
      if (correctFirstTryCount != null)
        'correct_first_try_count': correctFirstTryCount,
      if (consecutiveWrong != null) 'consecutive_wrong': consecutiveWrong,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
      if (reviewStage != null) 'review_stage': reviewStage,
      if (nextDueAt != null) 'next_due_at': nextDueAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemProgressRowsCompanion copyWith({
    Value<String>? itemId,
    Value<ItemState>? state,
    Value<int>? correctFirstTryCount,
    Value<int>? consecutiveWrong,
    Value<DateTime?>? acquiredAt,
    Value<int>? reviewStage,
    Value<DateTime?>? nextDueAt,
    Value<int>? rowid,
  }) {
    return ItemProgressRowsCompanion(
      itemId: itemId ?? this.itemId,
      state: state ?? this.state,
      correctFirstTryCount: correctFirstTryCount ?? this.correctFirstTryCount,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      reviewStage: reviewStage ?? this.reviewStage,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $ItemProgressRowsTable.$converterstate.toSql(state.value),
      );
    }
    if (correctFirstTryCount.present) {
      map['correct_first_try_count'] = Variable<int>(
        correctFirstTryCount.value,
      );
    }
    if (consecutiveWrong.present) {
      map['consecutive_wrong'] = Variable<int>(consecutiveWrong.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<DateTime>(acquiredAt.value);
    }
    if (reviewStage.present) {
      map['review_stage'] = Variable<int>(reviewStage.value);
    }
    if (nextDueAt.present) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemProgressRowsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('state: $state, ')
          ..write('correctFirstTryCount: $correctFirstTryCount, ')
          ..write('consecutiveWrong: $consecutiveWrong, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('reviewStage: $reviewStage, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CorrectFirstTryDaysTable extends CorrectFirstTryDays
    with TableInfo<$CorrectFirstTryDaysTable, CorrectFirstTryDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CorrectFirstTryDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [itemId, day];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'correct_first_try_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<CorrectFirstTryDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, day};
  @override
  CorrectFirstTryDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CorrectFirstTryDay(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
    );
  }

  @override
  $CorrectFirstTryDaysTable createAlias(String alias) {
    return $CorrectFirstTryDaysTable(attachedDatabase, alias);
  }
}

class CorrectFirstTryDay extends DataClass
    implements Insertable<CorrectFirstTryDay> {
  final String itemId;
  final DateTime day;
  const CorrectFirstTryDay({required this.itemId, required this.day});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['day'] = Variable<DateTime>(day);
    return map;
  }

  CorrectFirstTryDaysCompanion toCompanion(bool nullToAbsent) {
    return CorrectFirstTryDaysCompanion(itemId: Value(itemId), day: Value(day));
  }

  factory CorrectFirstTryDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CorrectFirstTryDay(
      itemId: serializer.fromJson<String>(json['itemId']),
      day: serializer.fromJson<DateTime>(json['day']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'day': serializer.toJson<DateTime>(day),
    };
  }

  CorrectFirstTryDay copyWith({String? itemId, DateTime? day}) =>
      CorrectFirstTryDay(itemId: itemId ?? this.itemId, day: day ?? this.day);
  CorrectFirstTryDay copyWithCompanion(CorrectFirstTryDaysCompanion data) {
    return CorrectFirstTryDay(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      day: data.day.present ? data.day.value : this.day,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CorrectFirstTryDay(')
          ..write('itemId: $itemId, ')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, day);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CorrectFirstTryDay &&
          other.itemId == this.itemId &&
          other.day == this.day);
}

class CorrectFirstTryDaysCompanion extends UpdateCompanion<CorrectFirstTryDay> {
  final Value<String> itemId;
  final Value<DateTime> day;
  final Value<int> rowid;
  const CorrectFirstTryDaysCompanion({
    this.itemId = const Value.absent(),
    this.day = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CorrectFirstTryDaysCompanion.insert({
    required String itemId,
    required DateTime day,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       day = Value(day);
  static Insertable<CorrectFirstTryDay> custom({
    Expression<String>? itemId,
    Expression<DateTime>? day,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (day != null) 'day': day,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CorrectFirstTryDaysCompanion copyWith({
    Value<String>? itemId,
    Value<DateTime>? day,
    Value<int>? rowid,
  }) {
    return CorrectFirstTryDaysCompanion(
      itemId: itemId ?? this.itemId,
      day: day ?? this.day,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CorrectFirstTryDaysCompanion(')
          ..write('itemId: $itemId, ')
          ..write('day: $day, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProgressDatabase extends GeneratedDatabase {
  _$ProgressDatabase(QueryExecutor e) : super(e);
  $ProgressDatabaseManager get managers => $ProgressDatabaseManager(this);
  late final $ItemProgressRowsTable itemProgressRows = $ItemProgressRowsTable(
    this,
  );
  late final $CorrectFirstTryDaysTable correctFirstTryDays =
      $CorrectFirstTryDaysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    itemProgressRows,
    correctFirstTryDays,
  ];
}

typedef $$ItemProgressRowsTableCreateCompanionBuilder =
    ItemProgressRowsCompanion Function({
      required String itemId,
      required ItemState state,
      Value<int> correctFirstTryCount,
      Value<int> consecutiveWrong,
      Value<DateTime?> acquiredAt,
      Value<int> reviewStage,
      Value<DateTime?> nextDueAt,
      Value<int> rowid,
    });
typedef $$ItemProgressRowsTableUpdateCompanionBuilder =
    ItemProgressRowsCompanion Function({
      Value<String> itemId,
      Value<ItemState> state,
      Value<int> correctFirstTryCount,
      Value<int> consecutiveWrong,
      Value<DateTime?> acquiredAt,
      Value<int> reviewStage,
      Value<DateTime?> nextDueAt,
      Value<int> rowid,
    });

class $$ItemProgressRowsTableFilterComposer
    extends Composer<_$ProgressDatabase, $ItemProgressRowsTable> {
  $$ItemProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemState, ItemState, int> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get correctFirstTryCount => $composableBuilder(
    column: $table.correctFirstTryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveWrong => $composableBuilder(
    column: $table.consecutiveWrong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewStage => $composableBuilder(
    column: $table.reviewStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItemProgressRowsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $ItemProgressRowsTable> {
  $$ItemProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctFirstTryCount => $composableBuilder(
    column: $table.correctFirstTryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveWrong => $composableBuilder(
    column: $table.consecutiveWrong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewStage => $composableBuilder(
    column: $table.reviewStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItemProgressRowsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $ItemProgressRowsTable> {
  $$ItemProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get correctFirstTryCount => $composableBuilder(
    column: $table.correctFirstTryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveWrong => $composableBuilder(
    column: $table.consecutiveWrong,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewStage => $composableBuilder(
    column: $table.reviewStage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextDueAt =>
      $composableBuilder(column: $table.nextDueAt, builder: (column) => column);
}

class $$ItemProgressRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $ItemProgressRowsTable,
          ItemProgressRow,
          $$ItemProgressRowsTableFilterComposer,
          $$ItemProgressRowsTableOrderingComposer,
          $$ItemProgressRowsTableAnnotationComposer,
          $$ItemProgressRowsTableCreateCompanionBuilder,
          $$ItemProgressRowsTableUpdateCompanionBuilder,
          (
            ItemProgressRow,
            BaseReferences<
              _$ProgressDatabase,
              $ItemProgressRowsTable,
              ItemProgressRow
            >,
          ),
          ItemProgressRow,
          PrefetchHooks Function()
        > {
  $$ItemProgressRowsTableTableManager(
    _$ProgressDatabase db,
    $ItemProgressRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemProgressRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<ItemState> state = const Value.absent(),
                Value<int> correctFirstTryCount = const Value.absent(),
                Value<int> consecutiveWrong = const Value.absent(),
                Value<DateTime?> acquiredAt = const Value.absent(),
                Value<int> reviewStage = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemProgressRowsCompanion(
                itemId: itemId,
                state: state,
                correctFirstTryCount: correctFirstTryCount,
                consecutiveWrong: consecutiveWrong,
                acquiredAt: acquiredAt,
                reviewStage: reviewStage,
                nextDueAt: nextDueAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required ItemState state,
                Value<int> correctFirstTryCount = const Value.absent(),
                Value<int> consecutiveWrong = const Value.absent(),
                Value<DateTime?> acquiredAt = const Value.absent(),
                Value<int> reviewStage = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemProgressRowsCompanion.insert(
                itemId: itemId,
                state: state,
                correctFirstTryCount: correctFirstTryCount,
                consecutiveWrong: consecutiveWrong,
                acquiredAt: acquiredAt,
                reviewStage: reviewStage,
                nextDueAt: nextDueAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemProgressRowsTable, ItemProgressRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $ItemProgressRowsTable,
                    ItemProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItemProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $ItemProgressRowsTable,
      ItemProgressRow,
      $$ItemProgressRowsTableFilterComposer,
      $$ItemProgressRowsTableOrderingComposer,
      $$ItemProgressRowsTableAnnotationComposer,
      $$ItemProgressRowsTableCreateCompanionBuilder,
      $$ItemProgressRowsTableUpdateCompanionBuilder,
      (
        ItemProgressRow,
        BaseReferences<
          _$ProgressDatabase,
          $ItemProgressRowsTable,
          ItemProgressRow
        >,
      ),
      ItemProgressRow,
      PrefetchHooks Function()
    >;
typedef $$CorrectFirstTryDaysTableCreateCompanionBuilder =
    CorrectFirstTryDaysCompanion Function({
      required String itemId,
      required DateTime day,
      Value<int> rowid,
    });
typedef $$CorrectFirstTryDaysTableUpdateCompanionBuilder =
    CorrectFirstTryDaysCompanion Function({
      Value<String> itemId,
      Value<DateTime> day,
      Value<int> rowid,
    });

class $$CorrectFirstTryDaysTableFilterComposer
    extends Composer<_$ProgressDatabase, $CorrectFirstTryDaysTable> {
  $$CorrectFirstTryDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CorrectFirstTryDaysTableOrderingComposer
    extends Composer<_$ProgressDatabase, $CorrectFirstTryDaysTable> {
  $$CorrectFirstTryDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CorrectFirstTryDaysTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $CorrectFirstTryDaysTable> {
  $$CorrectFirstTryDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);
}

class $$CorrectFirstTryDaysTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $CorrectFirstTryDaysTable,
          CorrectFirstTryDay,
          $$CorrectFirstTryDaysTableFilterComposer,
          $$CorrectFirstTryDaysTableOrderingComposer,
          $$CorrectFirstTryDaysTableAnnotationComposer,
          $$CorrectFirstTryDaysTableCreateCompanionBuilder,
          $$CorrectFirstTryDaysTableUpdateCompanionBuilder,
          (
            CorrectFirstTryDay,
            BaseReferences<
              _$ProgressDatabase,
              $CorrectFirstTryDaysTable,
              CorrectFirstTryDay
            >,
          ),
          CorrectFirstTryDay,
          PrefetchHooks Function()
        > {
  $$CorrectFirstTryDaysTableTableManager(
    _$ProgressDatabase db,
    $CorrectFirstTryDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CorrectFirstTryDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CorrectFirstTryDaysTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CorrectFirstTryDaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CorrectFirstTryDaysCompanion(
                itemId: itemId,
                day: day,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required DateTime day,
                Value<int> rowid = const Value.absent(),
              }) => CorrectFirstTryDaysCompanion.insert(
                itemId: itemId,
                day: day,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CorrectFirstTryDaysTable, CorrectFirstTryDay>(
                    table,
                  ),
                  BaseReferences<
                    _$ProgressDatabase,
                    $CorrectFirstTryDaysTable,
                    CorrectFirstTryDay
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CorrectFirstTryDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $CorrectFirstTryDaysTable,
      CorrectFirstTryDay,
      $$CorrectFirstTryDaysTableFilterComposer,
      $$CorrectFirstTryDaysTableOrderingComposer,
      $$CorrectFirstTryDaysTableAnnotationComposer,
      $$CorrectFirstTryDaysTableCreateCompanionBuilder,
      $$CorrectFirstTryDaysTableUpdateCompanionBuilder,
      (
        CorrectFirstTryDay,
        BaseReferences<
          _$ProgressDatabase,
          $CorrectFirstTryDaysTable,
          CorrectFirstTryDay
        >,
      ),
      CorrectFirstTryDay,
      PrefetchHooks Function()
    >;

class $ProgressDatabaseManager {
  final _$ProgressDatabase _db;
  $ProgressDatabaseManager(this._db);
  $$ItemProgressRowsTableTableManager get itemProgressRows =>
      $$ItemProgressRowsTableTableManager(_db, _db.itemProgressRows);
  $$CorrectFirstTryDaysTableTableManager get correctFirstTryDays =>
      $$CorrectFirstTryDaysTableTableManager(_db, _db.correctFirstTryDays);
}
