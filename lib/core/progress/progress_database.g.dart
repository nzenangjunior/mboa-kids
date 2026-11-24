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
  static const VerificationMeta _firstAcquiredAtMeta = const VerificationMeta(
    'firstAcquiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstAcquiredAt =
      GeneratedColumn<DateTime>(
        'first_acquired_at',
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
    firstAcquiredAt,
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
    if (data.containsKey('first_acquired_at')) {
      context.handle(
        _firstAcquiredAtMeta,
        firstAcquiredAt.isAcceptableOrUnknown(
          data['first_acquired_at']!,
          _firstAcquiredAtMeta,
        ),
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
      firstAcquiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_acquired_at'],
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
  final DateTime? firstAcquiredAt;
  final int reviewStage;
  final DateTime? nextDueAt;
  const ItemProgressRow({
    required this.itemId,
    required this.state,
    required this.correctFirstTryCount,
    required this.consecutiveWrong,
    this.firstAcquiredAt,
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
    if (!nullToAbsent || firstAcquiredAt != null) {
      map['first_acquired_at'] = Variable<DateTime>(firstAcquiredAt);
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
      firstAcquiredAt: firstAcquiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstAcquiredAt),
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
      firstAcquiredAt: serializer.fromJson<DateTime?>(json['firstAcquiredAt']),
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
      'firstAcquiredAt': serializer.toJson<DateTime?>(firstAcquiredAt),
      'reviewStage': serializer.toJson<int>(reviewStage),
      'nextDueAt': serializer.toJson<DateTime?>(nextDueAt),
    };
  }

  ItemProgressRow copyWith({
    String? itemId,
    ItemState? state,
    int? correctFirstTryCount,
    int? consecutiveWrong,
    Value<DateTime?> firstAcquiredAt = const Value.absent(),
    int? reviewStage,
    Value<DateTime?> nextDueAt = const Value.absent(),
  }) => ItemProgressRow(
    itemId: itemId ?? this.itemId,
    state: state ?? this.state,
    correctFirstTryCount: correctFirstTryCount ?? this.correctFirstTryCount,
    consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
    firstAcquiredAt: firstAcquiredAt.present
        ? firstAcquiredAt.value
        : this.firstAcquiredAt,
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
      firstAcquiredAt: data.firstAcquiredAt.present
          ? data.firstAcquiredAt.value
          : this.firstAcquiredAt,
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
          ..write('firstAcquiredAt: $firstAcquiredAt, ')
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
    firstAcquiredAt,
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
          other.firstAcquiredAt == this.firstAcquiredAt &&
          other.reviewStage == this.reviewStage &&
          other.nextDueAt == this.nextDueAt);
}

class ItemProgressRowsCompanion extends UpdateCompanion<ItemProgressRow> {
  final Value<String> itemId;
  final Value<ItemState> state;
  final Value<int> correctFirstTryCount;
  final Value<int> consecutiveWrong;
  final Value<DateTime?> firstAcquiredAt;
  final Value<int> reviewStage;
  final Value<DateTime?> nextDueAt;
  final Value<int> rowid;
  const ItemProgressRowsCompanion({
    this.itemId = const Value.absent(),
    this.state = const Value.absent(),
    this.correctFirstTryCount = const Value.absent(),
    this.consecutiveWrong = const Value.absent(),
    this.firstAcquiredAt = const Value.absent(),
    this.reviewStage = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemProgressRowsCompanion.insert({
    required String itemId,
    required ItemState state,
    this.correctFirstTryCount = const Value.absent(),
    this.consecutiveWrong = const Value.absent(),
    this.firstAcquiredAt = const Value.absent(),
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
    Expression<DateTime>? firstAcquiredAt,
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
      if (firstAcquiredAt != null) 'first_acquired_at': firstAcquiredAt,
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
    Value<DateTime?>? firstAcquiredAt,
    Value<int>? reviewStage,
    Value<DateTime?>? nextDueAt,
    Value<int>? rowid,
  }) {
    return ItemProgressRowsCompanion(
      itemId: itemId ?? this.itemId,
      state: state ?? this.state,
      correctFirstTryCount: correctFirstTryCount ?? this.correctFirstTryCount,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      firstAcquiredAt: firstAcquiredAt ?? this.firstAcquiredAt,
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
    if (firstAcquiredAt.present) {
      map['first_acquired_at'] = Variable<DateTime>(firstAcquiredAt.value);
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
          ..write('firstAcquiredAt: $firstAcquiredAt, ')
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

class $EarnedStickerRowsTable extends EarnedStickerRows
    with TableInfo<$EarnedStickerRowsTable, EarnedStickerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EarnedStickerRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _stickerIdMeta = const VerificationMeta(
    'stickerId',
  );
  @override
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
    'sticker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnedAtMeta = const VerificationMeta(
    'earnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> earnedAt = GeneratedColumn<DateTime>(
    'earned_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, stickerId, earnedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'earned_sticker_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<EarnedStickerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sticker_id')) {
      context.handle(
        _stickerIdMeta,
        stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stickerIdMeta);
    }
    if (data.containsKey('earned_at')) {
      context.handle(
        _earnedAtMeta,
        earnedAt.isAcceptableOrUnknown(data['earned_at']!, _earnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_earnedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EarnedStickerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EarnedStickerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticker_id'],
      )!,
      earnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}earned_at'],
      )!,
    );
  }

  @override
  $EarnedStickerRowsTable createAlias(String alias) {
    return $EarnedStickerRowsTable(attachedDatabase, alias);
  }
}

class EarnedStickerRow extends DataClass
    implements Insertable<EarnedStickerRow> {
  final int id;
  final String stickerId;
  final DateTime earnedAt;
  const EarnedStickerRow({
    required this.id,
    required this.stickerId,
    required this.earnedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sticker_id'] = Variable<String>(stickerId);
    map['earned_at'] = Variable<DateTime>(earnedAt);
    return map;
  }

  EarnedStickerRowsCompanion toCompanion(bool nullToAbsent) {
    return EarnedStickerRowsCompanion(
      id: Value(id),
      stickerId: Value(stickerId),
      earnedAt: Value(earnedAt),
    );
  }

  factory EarnedStickerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EarnedStickerRow(
      id: serializer.fromJson<int>(json['id']),
      stickerId: serializer.fromJson<String>(json['stickerId']),
      earnedAt: serializer.fromJson<DateTime>(json['earnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stickerId': serializer.toJson<String>(stickerId),
      'earnedAt': serializer.toJson<DateTime>(earnedAt),
    };
  }

  EarnedStickerRow copyWith({int? id, String? stickerId, DateTime? earnedAt}) =>
      EarnedStickerRow(
        id: id ?? this.id,
        stickerId: stickerId ?? this.stickerId,
        earnedAt: earnedAt ?? this.earnedAt,
      );
  EarnedStickerRow copyWithCompanion(EarnedStickerRowsCompanion data) {
    return EarnedStickerRow(
      id: data.id.present ? data.id.value : this.id,
      stickerId: data.stickerId.present ? data.stickerId.value : this.stickerId,
      earnedAt: data.earnedAt.present ? data.earnedAt.value : this.earnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EarnedStickerRow(')
          ..write('id: $id, ')
          ..write('stickerId: $stickerId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stickerId, earnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarnedStickerRow &&
          other.id == this.id &&
          other.stickerId == this.stickerId &&
          other.earnedAt == this.earnedAt);
}

class EarnedStickerRowsCompanion extends UpdateCompanion<EarnedStickerRow> {
  final Value<int> id;
  final Value<String> stickerId;
  final Value<DateTime> earnedAt;
  const EarnedStickerRowsCompanion({
    this.id = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.earnedAt = const Value.absent(),
  });
  EarnedStickerRowsCompanion.insert({
    this.id = const Value.absent(),
    required String stickerId,
    required DateTime earnedAt,
  }) : stickerId = Value(stickerId),
       earnedAt = Value(earnedAt);
  static Insertable<EarnedStickerRow> custom({
    Expression<int>? id,
    Expression<String>? stickerId,
    Expression<DateTime>? earnedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stickerId != null) 'sticker_id': stickerId,
      if (earnedAt != null) 'earned_at': earnedAt,
    });
  }

  EarnedStickerRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? stickerId,
    Value<DateTime>? earnedAt,
  }) {
    return EarnedStickerRowsCompanion(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (earnedAt.present) {
      map['earned_at'] = Variable<DateTime>(earnedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EarnedStickerRowsCompanion(')
          ..write('id: $id, ')
          ..write('stickerId: $stickerId, ')
          ..write('earnedAt: $earnedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsRowsTable extends SettingsRows
    with TableInfo<$SettingsRowsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<String> intensity = GeneratedColumn<String>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _tracingQueueCursorMeta =
      const VerificationMeta('tracingQueueCursor');
  @override
  late final GeneratedColumn<String> tracingQueueCursor =
      GeneratedColumn<String>(
        'tracing_queue_cursor',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _worldMeta = const VerificationMeta('world');
  @override
  late final GeneratedColumn<String> world = GeneratedColumn<String>(
    'world',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumLastSeenCountMeta =
      const VerificationMeta('albumLastSeenCount');
  @override
  late final GeneratedColumn<int> albumLastSeenCount = GeneratedColumn<int>(
    'album_last_seen_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    intensity,
    tracingQueueCursor,
    world,
    albumLastSeenCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    }
    if (data.containsKey('tracing_queue_cursor')) {
      context.handle(
        _tracingQueueCursorMeta,
        tracingQueueCursor.isAcceptableOrUnknown(
          data['tracing_queue_cursor']!,
          _tracingQueueCursorMeta,
        ),
      );
    }
    if (data.containsKey('world')) {
      context.handle(
        _worldMeta,
        world.isAcceptableOrUnknown(data['world']!, _worldMeta),
      );
    }
    if (data.containsKey('album_last_seen_count')) {
      context.handle(
        _albumLastSeenCountMeta,
        albumLastSeenCount.isAcceptableOrUnknown(
          data['album_last_seen_count']!,
          _albumLastSeenCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intensity'],
      )!,
      tracingQueueCursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracing_queue_cursor'],
      ),
      world: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}world'],
      ),
      albumLastSeenCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_last_seen_count'],
      )!,
    );
  }

  @override
  $SettingsRowsTable createAlias(String alias) {
    return $SettingsRowsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String intensity;

  /// Opaque cursor (an "id#occurrence" key, see `tracing_queue.dart`) for
  /// the last tracing queue item completed, across all sessions (CLAUDE.md
  /// section 10: at most 5 traces per session, resuming where it left off
  /// rather than restarting from the first name every time). An occurrence
  /// number is needed, not just the id, because a repeated letter in the
  /// name (e.g. the two E's in ESTRELLA) would otherwise be ambiguous.
  final String? tracingQueueCursor;

  /// The last chosen world ('fr'/'en'), remembered across launches
  /// (CLAUDE.md section 10: "le monde choisi est mémorisé"). Null means
  /// never chosen yet — the app falls back to its own default then.
  final String? world;

  /// How many stickers + golden letters were earned the last time the
  /// album was opened (CLAUDE.md section 10, Refonte visuelle: the home
  /// screen's album icon shows a badge when this is lower than the
  /// current total).
  final int albumLastSeenCount;
  const SettingsRow({
    required this.id,
    required this.intensity,
    this.tracingQueueCursor,
    this.world,
    required this.albumLastSeenCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['intensity'] = Variable<String>(intensity);
    if (!nullToAbsent || tracingQueueCursor != null) {
      map['tracing_queue_cursor'] = Variable<String>(tracingQueueCursor);
    }
    if (!nullToAbsent || world != null) {
      map['world'] = Variable<String>(world);
    }
    map['album_last_seen_count'] = Variable<int>(albumLastSeenCount);
    return map;
  }

  SettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return SettingsRowsCompanion(
      id: Value(id),
      intensity: Value(intensity),
      tracingQueueCursor: tracingQueueCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(tracingQueueCursor),
      world: world == null && nullToAbsent
          ? const Value.absent()
          : Value(world),
      albumLastSeenCount: Value(albumLastSeenCount),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      intensity: serializer.fromJson<String>(json['intensity']),
      tracingQueueCursor: serializer.fromJson<String?>(
        json['tracingQueueCursor'],
      ),
      world: serializer.fromJson<String?>(json['world']),
      albumLastSeenCount: serializer.fromJson<int>(json['albumLastSeenCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'intensity': serializer.toJson<String>(intensity),
      'tracingQueueCursor': serializer.toJson<String?>(tracingQueueCursor),
      'world': serializer.toJson<String?>(world),
      'albumLastSeenCount': serializer.toJson<int>(albumLastSeenCount),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? intensity,
    Value<String?> tracingQueueCursor = const Value.absent(),
    Value<String?> world = const Value.absent(),
    int? albumLastSeenCount,
  }) => SettingsRow(
    id: id ?? this.id,
    intensity: intensity ?? this.intensity,
    tracingQueueCursor: tracingQueueCursor.present
        ? tracingQueueCursor.value
        : this.tracingQueueCursor,
    world: world.present ? world.value : this.world,
    albumLastSeenCount: albumLastSeenCount ?? this.albumLastSeenCount,
  );
  SettingsRow copyWithCompanion(SettingsRowsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      tracingQueueCursor: data.tracingQueueCursor.present
          ? data.tracingQueueCursor.value
          : this.tracingQueueCursor,
      world: data.world.present ? data.world.value : this.world,
      albumLastSeenCount: data.albumLastSeenCount.present
          ? data.albumLastSeenCount.value
          : this.albumLastSeenCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('intensity: $intensity, ')
          ..write('tracingQueueCursor: $tracingQueueCursor, ')
          ..write('world: $world, ')
          ..write('albumLastSeenCount: $albumLastSeenCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, intensity, tracingQueueCursor, world, albumLastSeenCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.intensity == this.intensity &&
          other.tracingQueueCursor == this.tracingQueueCursor &&
          other.world == this.world &&
          other.albumLastSeenCount == this.albumLastSeenCount);
}

class SettingsRowsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> intensity;
  final Value<String?> tracingQueueCursor;
  final Value<String?> world;
  final Value<int> albumLastSeenCount;
  const SettingsRowsCompanion({
    this.id = const Value.absent(),
    this.intensity = const Value.absent(),
    this.tracingQueueCursor = const Value.absent(),
    this.world = const Value.absent(),
    this.albumLastSeenCount = const Value.absent(),
  });
  SettingsRowsCompanion.insert({
    this.id = const Value.absent(),
    this.intensity = const Value.absent(),
    this.tracingQueueCursor = const Value.absent(),
    this.world = const Value.absent(),
    this.albumLastSeenCount = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? intensity,
    Expression<String>? tracingQueueCursor,
    Expression<String>? world,
    Expression<int>? albumLastSeenCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (intensity != null) 'intensity': intensity,
      if (tracingQueueCursor != null)
        'tracing_queue_cursor': tracingQueueCursor,
      if (world != null) 'world': world,
      if (albumLastSeenCount != null)
        'album_last_seen_count': albumLastSeenCount,
    });
  }

  SettingsRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? intensity,
    Value<String?>? tracingQueueCursor,
    Value<String?>? world,
    Value<int>? albumLastSeenCount,
  }) {
    return SettingsRowsCompanion(
      id: id ?? this.id,
      intensity: intensity ?? this.intensity,
      tracingQueueCursor: tracingQueueCursor ?? this.tracingQueueCursor,
      world: world ?? this.world,
      albumLastSeenCount: albumLastSeenCount ?? this.albumLastSeenCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<String>(intensity.value);
    }
    if (tracingQueueCursor.present) {
      map['tracing_queue_cursor'] = Variable<String>(tracingQueueCursor.value);
    }
    if (world.present) {
      map['world'] = Variable<String>(world.value);
    }
    if (albumLastSeenCount.present) {
      map['album_last_seen_count'] = Variable<int>(albumLastSeenCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('intensity: $intensity, ')
          ..write('tracingQueueCursor: $tracingQueueCursor, ')
          ..write('world: $world, ')
          ..write('albumLastSeenCount: $albumLastSeenCount')
          ..write(')'))
        .toString();
  }
}

class $TracingGuidedSuccessDaysTable extends TracingGuidedSuccessDays
    with TableInfo<$TracingGuidedSuccessDaysTable, TracingGuidedSuccessDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracingGuidedSuccessDaysTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'tracing_guided_success_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<TracingGuidedSuccessDay> instance, {
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
  TracingGuidedSuccessDay map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TracingGuidedSuccessDay(
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
  $TracingGuidedSuccessDaysTable createAlias(String alias) {
    return $TracingGuidedSuccessDaysTable(attachedDatabase, alias);
  }
}

class TracingGuidedSuccessDay extends DataClass
    implements Insertable<TracingGuidedSuccessDay> {
  final String itemId;
  final DateTime day;
  const TracingGuidedSuccessDay({required this.itemId, required this.day});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['day'] = Variable<DateTime>(day);
    return map;
  }

  TracingGuidedSuccessDaysCompanion toCompanion(bool nullToAbsent) {
    return TracingGuidedSuccessDaysCompanion(
      itemId: Value(itemId),
      day: Value(day),
    );
  }

  factory TracingGuidedSuccessDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TracingGuidedSuccessDay(
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

  TracingGuidedSuccessDay copyWith({String? itemId, DateTime? day}) =>
      TracingGuidedSuccessDay(
        itemId: itemId ?? this.itemId,
        day: day ?? this.day,
      );
  TracingGuidedSuccessDay copyWithCompanion(
    TracingGuidedSuccessDaysCompanion data,
  ) {
    return TracingGuidedSuccessDay(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      day: data.day.present ? data.day.value : this.day,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TracingGuidedSuccessDay(')
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
      (other is TracingGuidedSuccessDay &&
          other.itemId == this.itemId &&
          other.day == this.day);
}

class TracingGuidedSuccessDaysCompanion
    extends UpdateCompanion<TracingGuidedSuccessDay> {
  final Value<String> itemId;
  final Value<DateTime> day;
  final Value<int> rowid;
  const TracingGuidedSuccessDaysCompanion({
    this.itemId = const Value.absent(),
    this.day = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracingGuidedSuccessDaysCompanion.insert({
    required String itemId,
    required DateTime day,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       day = Value(day);
  static Insertable<TracingGuidedSuccessDay> custom({
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

  TracingGuidedSuccessDaysCompanion copyWith({
    Value<String>? itemId,
    Value<DateTime>? day,
    Value<int>? rowid,
  }) {
    return TracingGuidedSuccessDaysCompanion(
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
    return (StringBuffer('TracingGuidedSuccessDaysCompanion(')
          ..write('itemId: $itemId, ')
          ..write('day: $day, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelBestStarRowsTable extends LevelBestStarRows
    with TableInfo<$LevelBestStarRowsTable, LevelBestStarRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelBestStarRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
    'level_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestStarsMeta = const VerificationMeta(
    'bestStars',
  );
  @override
  late final GeneratedColumn<int> bestStars = GeneratedColumn<int>(
    'best_stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [levelId, bestStars];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_best_star_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelBestStarRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('best_stars')) {
      context.handle(
        _bestStarsMeta,
        bestStars.isAcceptableOrUnknown(data['best_stars']!, _bestStarsMeta),
      );
    } else if (isInserting) {
      context.missing(_bestStarsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {levelId};
  @override
  LevelBestStarRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelBestStarRow(
      levelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level_id'],
      )!,
      bestStars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_stars'],
      )!,
    );
  }

  @override
  $LevelBestStarRowsTable createAlias(String alias) {
    return $LevelBestStarRowsTable(attachedDatabase, alias);
  }
}

class LevelBestStarRow extends DataClass
    implements Insertable<LevelBestStarRow> {
  final String levelId;
  final int bestStars;
  const LevelBestStarRow({required this.levelId, required this.bestStars});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['level_id'] = Variable<String>(levelId);
    map['best_stars'] = Variable<int>(bestStars);
    return map;
  }

  LevelBestStarRowsCompanion toCompanion(bool nullToAbsent) {
    return LevelBestStarRowsCompanion(
      levelId: Value(levelId),
      bestStars: Value(bestStars),
    );
  }

  factory LevelBestStarRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelBestStarRow(
      levelId: serializer.fromJson<String>(json['levelId']),
      bestStars: serializer.fromJson<int>(json['bestStars']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'levelId': serializer.toJson<String>(levelId),
      'bestStars': serializer.toJson<int>(bestStars),
    };
  }

  LevelBestStarRow copyWith({String? levelId, int? bestStars}) =>
      LevelBestStarRow(
        levelId: levelId ?? this.levelId,
        bestStars: bestStars ?? this.bestStars,
      );
  LevelBestStarRow copyWithCompanion(LevelBestStarRowsCompanion data) {
    return LevelBestStarRow(
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      bestStars: data.bestStars.present ? data.bestStars.value : this.bestStars,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelBestStarRow(')
          ..write('levelId: $levelId, ')
          ..write('bestStars: $bestStars')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(levelId, bestStars);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelBestStarRow &&
          other.levelId == this.levelId &&
          other.bestStars == this.bestStars);
}

class LevelBestStarRowsCompanion extends UpdateCompanion<LevelBestStarRow> {
  final Value<String> levelId;
  final Value<int> bestStars;
  final Value<int> rowid;
  const LevelBestStarRowsCompanion({
    this.levelId = const Value.absent(),
    this.bestStars = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelBestStarRowsCompanion.insert({
    required String levelId,
    required int bestStars,
    this.rowid = const Value.absent(),
  }) : levelId = Value(levelId),
       bestStars = Value(bestStars);
  static Insertable<LevelBestStarRow> custom({
    Expression<String>? levelId,
    Expression<int>? bestStars,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (levelId != null) 'level_id': levelId,
      if (bestStars != null) 'best_stars': bestStars,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelBestStarRowsCompanion copyWith({
    Value<String>? levelId,
    Value<int>? bestStars,
    Value<int>? rowid,
  }) {
    return LevelBestStarRowsCompanion(
      levelId: levelId ?? this.levelId,
      bestStars: bestStars ?? this.bestStars,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (bestStars.present) {
      map['best_stars'] = Variable<int>(bestStars.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelBestStarRowsCompanion(')
          ..write('levelId: $levelId, ')
          ..write('bestStars: $bestStars, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StickerPositionRowsTable extends StickerPositionRows
    with TableInfo<$StickerPositionRowsTable, StickerPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickerPositionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stickerIdMeta = const VerificationMeta(
    'stickerId',
  );
  @override
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
    'sticker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dxMeta = const VerificationMeta('dx');
  @override
  late final GeneratedColumn<double> dx = GeneratedColumn<double>(
    'dx',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dyMeta = const VerificationMeta('dy');
  @override
  late final GeneratedColumn<double> dy = GeneratedColumn<double>(
    'dy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [stickerId, dx, dy];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sticker_position_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<StickerPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sticker_id')) {
      context.handle(
        _stickerIdMeta,
        stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stickerIdMeta);
    }
    if (data.containsKey('dx')) {
      context.handle(_dxMeta, dx.isAcceptableOrUnknown(data['dx']!, _dxMeta));
    } else if (isInserting) {
      context.missing(_dxMeta);
    }
    if (data.containsKey('dy')) {
      context.handle(_dyMeta, dy.isAcceptableOrUnknown(data['dy']!, _dyMeta));
    } else if (isInserting) {
      context.missing(_dyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stickerId};
  @override
  StickerPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickerPositionRow(
      stickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticker_id'],
      )!,
      dx: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dx'],
      )!,
      dy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dy'],
      )!,
    );
  }

  @override
  $StickerPositionRowsTable createAlias(String alias) {
    return $StickerPositionRowsTable(attachedDatabase, alias);
  }
}

class StickerPositionRow extends DataClass
    implements Insertable<StickerPositionRow> {
  final String stickerId;
  final double dx;
  final double dy;
  const StickerPositionRow({
    required this.stickerId,
    required this.dx,
    required this.dy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sticker_id'] = Variable<String>(stickerId);
    map['dx'] = Variable<double>(dx);
    map['dy'] = Variable<double>(dy);
    return map;
  }

  StickerPositionRowsCompanion toCompanion(bool nullToAbsent) {
    return StickerPositionRowsCompanion(
      stickerId: Value(stickerId),
      dx: Value(dx),
      dy: Value(dy),
    );
  }

  factory StickerPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickerPositionRow(
      stickerId: serializer.fromJson<String>(json['stickerId']),
      dx: serializer.fromJson<double>(json['dx']),
      dy: serializer.fromJson<double>(json['dy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stickerId': serializer.toJson<String>(stickerId),
      'dx': serializer.toJson<double>(dx),
      'dy': serializer.toJson<double>(dy),
    };
  }

  StickerPositionRow copyWith({String? stickerId, double? dx, double? dy}) =>
      StickerPositionRow(
        stickerId: stickerId ?? this.stickerId,
        dx: dx ?? this.dx,
        dy: dy ?? this.dy,
      );
  StickerPositionRow copyWithCompanion(StickerPositionRowsCompanion data) {
    return StickerPositionRow(
      stickerId: data.stickerId.present ? data.stickerId.value : this.stickerId,
      dx: data.dx.present ? data.dx.value : this.dx,
      dy: data.dy.present ? data.dy.value : this.dy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StickerPositionRow(')
          ..write('stickerId: $stickerId, ')
          ..write('dx: $dx, ')
          ..write('dy: $dy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stickerId, dx, dy);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickerPositionRow &&
          other.stickerId == this.stickerId &&
          other.dx == this.dx &&
          other.dy == this.dy);
}

class StickerPositionRowsCompanion extends UpdateCompanion<StickerPositionRow> {
  final Value<String> stickerId;
  final Value<double> dx;
  final Value<double> dy;
  final Value<int> rowid;
  const StickerPositionRowsCompanion({
    this.stickerId = const Value.absent(),
    this.dx = const Value.absent(),
    this.dy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickerPositionRowsCompanion.insert({
    required String stickerId,
    required double dx,
    required double dy,
    this.rowid = const Value.absent(),
  }) : stickerId = Value(stickerId),
       dx = Value(dx),
       dy = Value(dy);
  static Insertable<StickerPositionRow> custom({
    Expression<String>? stickerId,
    Expression<double>? dx,
    Expression<double>? dy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stickerId != null) 'sticker_id': stickerId,
      if (dx != null) 'dx': dx,
      if (dy != null) 'dy': dy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickerPositionRowsCompanion copyWith({
    Value<String>? stickerId,
    Value<double>? dx,
    Value<double>? dy,
    Value<int>? rowid,
  }) {
    return StickerPositionRowsCompanion(
      stickerId: stickerId ?? this.stickerId,
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (dx.present) {
      map['dx'] = Variable<double>(dx.value);
    }
    if (dy.present) {
      map['dy'] = Variable<double>(dy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickerPositionRowsCompanion(')
          ..write('stickerId: $stickerId, ')
          ..write('dx: $dx, ')
          ..write('dy: $dy, ')
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
  late final $EarnedStickerRowsTable earnedStickerRows =
      $EarnedStickerRowsTable(this);
  late final $SettingsRowsTable settingsRows = $SettingsRowsTable(this);
  late final $TracingGuidedSuccessDaysTable tracingGuidedSuccessDays =
      $TracingGuidedSuccessDaysTable(this);
  late final $LevelBestStarRowsTable levelBestStarRows =
      $LevelBestStarRowsTable(this);
  late final $StickerPositionRowsTable stickerPositionRows =
      $StickerPositionRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    itemProgressRows,
    correctFirstTryDays,
    earnedStickerRows,
    settingsRows,
    tracingGuidedSuccessDays,
    levelBestStarRows,
    stickerPositionRows,
  ];
}

typedef $$ItemProgressRowsTableCreateCompanionBuilder =
    ItemProgressRowsCompanion Function({
      required String itemId,
      required ItemState state,
      Value<int> correctFirstTryCount,
      Value<int> consecutiveWrong,
      Value<DateTime?> firstAcquiredAt,
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
      Value<DateTime?> firstAcquiredAt,
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

  ColumnFilters<DateTime> get firstAcquiredAt => $composableBuilder(
    column: $table.firstAcquiredAt,
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

  ColumnOrderings<DateTime> get firstAcquiredAt => $composableBuilder(
    column: $table.firstAcquiredAt,
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

  GeneratedColumn<DateTime> get firstAcquiredAt => $composableBuilder(
    column: $table.firstAcquiredAt,
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
                Value<DateTime?> firstAcquiredAt = const Value.absent(),
                Value<int> reviewStage = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemProgressRowsCompanion(
                itemId: itemId,
                state: state,
                correctFirstTryCount: correctFirstTryCount,
                consecutiveWrong: consecutiveWrong,
                firstAcquiredAt: firstAcquiredAt,
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
                Value<DateTime?> firstAcquiredAt = const Value.absent(),
                Value<int> reviewStage = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemProgressRowsCompanion.insert(
                itemId: itemId,
                state: state,
                correctFirstTryCount: correctFirstTryCount,
                consecutiveWrong: consecutiveWrong,
                firstAcquiredAt: firstAcquiredAt,
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
typedef $$EarnedStickerRowsTableCreateCompanionBuilder =
    EarnedStickerRowsCompanion Function({
      Value<int> id,
      required String stickerId,
      required DateTime earnedAt,
    });
typedef $$EarnedStickerRowsTableUpdateCompanionBuilder =
    EarnedStickerRowsCompanion Function({
      Value<int> id,
      Value<String> stickerId,
      Value<DateTime> earnedAt,
    });

class $$EarnedStickerRowsTableFilterComposer
    extends Composer<_$ProgressDatabase, $EarnedStickerRowsTable> {
  $$EarnedStickerRowsTableFilterComposer({
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

  ColumnFilters<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EarnedStickerRowsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $EarnedStickerRowsTable> {
  $$EarnedStickerRowsTableOrderingComposer({
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

  ColumnOrderings<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get earnedAt => $composableBuilder(
    column: $table.earnedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EarnedStickerRowsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $EarnedStickerRowsTable> {
  $$EarnedStickerRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stickerId =>
      $composableBuilder(column: $table.stickerId, builder: (column) => column);

  GeneratedColumn<DateTime> get earnedAt =>
      $composableBuilder(column: $table.earnedAt, builder: (column) => column);
}

class $$EarnedStickerRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $EarnedStickerRowsTable,
          EarnedStickerRow,
          $$EarnedStickerRowsTableFilterComposer,
          $$EarnedStickerRowsTableOrderingComposer,
          $$EarnedStickerRowsTableAnnotationComposer,
          $$EarnedStickerRowsTableCreateCompanionBuilder,
          $$EarnedStickerRowsTableUpdateCompanionBuilder,
          (
            EarnedStickerRow,
            BaseReferences<
              _$ProgressDatabase,
              $EarnedStickerRowsTable,
              EarnedStickerRow
            >,
          ),
          EarnedStickerRow,
          PrefetchHooks Function()
        > {
  $$EarnedStickerRowsTableTableManager(
    _$ProgressDatabase db,
    $EarnedStickerRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EarnedStickerRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EarnedStickerRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EarnedStickerRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stickerId = const Value.absent(),
                Value<DateTime> earnedAt = const Value.absent(),
              }) => EarnedStickerRowsCompanion(
                id: id,
                stickerId: stickerId,
                earnedAt: earnedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String stickerId,
                required DateTime earnedAt,
              }) => EarnedStickerRowsCompanion.insert(
                id: id,
                stickerId: stickerId,
                earnedAt: earnedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EarnedStickerRowsTable, EarnedStickerRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $EarnedStickerRowsTable,
                    EarnedStickerRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EarnedStickerRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $EarnedStickerRowsTable,
      EarnedStickerRow,
      $$EarnedStickerRowsTableFilterComposer,
      $$EarnedStickerRowsTableOrderingComposer,
      $$EarnedStickerRowsTableAnnotationComposer,
      $$EarnedStickerRowsTableCreateCompanionBuilder,
      $$EarnedStickerRowsTableUpdateCompanionBuilder,
      (
        EarnedStickerRow,
        BaseReferences<
          _$ProgressDatabase,
          $EarnedStickerRowsTable,
          EarnedStickerRow
        >,
      ),
      EarnedStickerRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsRowsTableCreateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<String> intensity,
      Value<String?> tracingQueueCursor,
      Value<String?> world,
      Value<int> albumLastSeenCount,
    });
typedef $$SettingsRowsTableUpdateCompanionBuilder =
    SettingsRowsCompanion Function({
      Value<int> id,
      Value<String> intensity,
      Value<String?> tracingQueueCursor,
      Value<String?> world,
      Value<int> albumLastSeenCount,
    });

class $$SettingsRowsTableFilterComposer
    extends Composer<_$ProgressDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableFilterComposer({
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

  ColumnFilters<String> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tracingQueueCursor => $composableBuilder(
    column: $table.tracingQueueCursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get world => $composableBuilder(
    column: $table.world,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get albumLastSeenCount => $composableBuilder(
    column: $table.albumLastSeenCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsRowsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableOrderingComposer({
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

  ColumnOrderings<String> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tracingQueueCursor => $composableBuilder(
    column: $table.tracingQueueCursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get world => $composableBuilder(
    column: $table.world,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get albumLastSeenCount => $composableBuilder(
    column: $table.albumLastSeenCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsRowsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $SettingsRowsTable> {
  $$SettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<String> get tracingQueueCursor => $composableBuilder(
    column: $table.tracingQueueCursor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get world =>
      $composableBuilder(column: $table.world, builder: (column) => column);

  GeneratedColumn<int> get albumLastSeenCount => $composableBuilder(
    column: $table.albumLastSeenCount,
    builder: (column) => column,
  );
}

class $$SettingsRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $SettingsRowsTable,
          SettingsRow,
          $$SettingsRowsTableFilterComposer,
          $$SettingsRowsTableOrderingComposer,
          $$SettingsRowsTableAnnotationComposer,
          $$SettingsRowsTableCreateCompanionBuilder,
          $$SettingsRowsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$ProgressDatabase, $SettingsRowsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsRowsTableTableManager(
    _$ProgressDatabase db,
    $SettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> intensity = const Value.absent(),
                Value<String?> tracingQueueCursor = const Value.absent(),
                Value<String?> world = const Value.absent(),
                Value<int> albumLastSeenCount = const Value.absent(),
              }) => SettingsRowsCompanion(
                id: id,
                intensity: intensity,
                tracingQueueCursor: tracingQueueCursor,
                world: world,
                albumLastSeenCount: albumLastSeenCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> intensity = const Value.absent(),
                Value<String?> tracingQueueCursor = const Value.absent(),
                Value<String?> world = const Value.absent(),
                Value<int> albumLastSeenCount = const Value.absent(),
              }) => SettingsRowsCompanion.insert(
                id: id,
                intensity: intensity,
                tracingQueueCursor: tracingQueueCursor,
                world: world,
                albumLastSeenCount: albumLastSeenCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsRowsTable, SettingsRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $SettingsRowsTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $SettingsRowsTable,
      SettingsRow,
      $$SettingsRowsTableFilterComposer,
      $$SettingsRowsTableOrderingComposer,
      $$SettingsRowsTableAnnotationComposer,
      $$SettingsRowsTableCreateCompanionBuilder,
      $$SettingsRowsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$ProgressDatabase, $SettingsRowsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$TracingGuidedSuccessDaysTableCreateCompanionBuilder =
    TracingGuidedSuccessDaysCompanion Function({
      required String itemId,
      required DateTime day,
      Value<int> rowid,
    });
typedef $$TracingGuidedSuccessDaysTableUpdateCompanionBuilder =
    TracingGuidedSuccessDaysCompanion Function({
      Value<String> itemId,
      Value<DateTime> day,
      Value<int> rowid,
    });

class $$TracingGuidedSuccessDaysTableFilterComposer
    extends Composer<_$ProgressDatabase, $TracingGuidedSuccessDaysTable> {
  $$TracingGuidedSuccessDaysTableFilterComposer({
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

class $$TracingGuidedSuccessDaysTableOrderingComposer
    extends Composer<_$ProgressDatabase, $TracingGuidedSuccessDaysTable> {
  $$TracingGuidedSuccessDaysTableOrderingComposer({
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

class $$TracingGuidedSuccessDaysTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $TracingGuidedSuccessDaysTable> {
  $$TracingGuidedSuccessDaysTableAnnotationComposer({
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

class $$TracingGuidedSuccessDaysTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $TracingGuidedSuccessDaysTable,
          TracingGuidedSuccessDay,
          $$TracingGuidedSuccessDaysTableFilterComposer,
          $$TracingGuidedSuccessDaysTableOrderingComposer,
          $$TracingGuidedSuccessDaysTableAnnotationComposer,
          $$TracingGuidedSuccessDaysTableCreateCompanionBuilder,
          $$TracingGuidedSuccessDaysTableUpdateCompanionBuilder,
          (
            TracingGuidedSuccessDay,
            BaseReferences<
              _$ProgressDatabase,
              $TracingGuidedSuccessDaysTable,
              TracingGuidedSuccessDay
            >,
          ),
          TracingGuidedSuccessDay,
          PrefetchHooks Function()
        > {
  $$TracingGuidedSuccessDaysTableTableManager(
    _$ProgressDatabase db,
    $TracingGuidedSuccessDaysTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracingGuidedSuccessDaysTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TracingGuidedSuccessDaysTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TracingGuidedSuccessDaysTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracingGuidedSuccessDaysCompanion(
                itemId: itemId,
                day: day,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required DateTime day,
                Value<int> rowid = const Value.absent(),
              }) => TracingGuidedSuccessDaysCompanion.insert(
                itemId: itemId,
                day: day,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $TracingGuidedSuccessDaysTable,
                    TracingGuidedSuccessDay
                  >(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $TracingGuidedSuccessDaysTable,
                    TracingGuidedSuccessDay
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracingGuidedSuccessDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $TracingGuidedSuccessDaysTable,
      TracingGuidedSuccessDay,
      $$TracingGuidedSuccessDaysTableFilterComposer,
      $$TracingGuidedSuccessDaysTableOrderingComposer,
      $$TracingGuidedSuccessDaysTableAnnotationComposer,
      $$TracingGuidedSuccessDaysTableCreateCompanionBuilder,
      $$TracingGuidedSuccessDaysTableUpdateCompanionBuilder,
      (
        TracingGuidedSuccessDay,
        BaseReferences<
          _$ProgressDatabase,
          $TracingGuidedSuccessDaysTable,
          TracingGuidedSuccessDay
        >,
      ),
      TracingGuidedSuccessDay,
      PrefetchHooks Function()
    >;
typedef $$LevelBestStarRowsTableCreateCompanionBuilder =
    LevelBestStarRowsCompanion Function({
      required String levelId,
      required int bestStars,
      Value<int> rowid,
    });
typedef $$LevelBestStarRowsTableUpdateCompanionBuilder =
    LevelBestStarRowsCompanion Function({
      Value<String> levelId,
      Value<int> bestStars,
      Value<int> rowid,
    });

class $$LevelBestStarRowsTableFilterComposer
    extends Composer<_$ProgressDatabase, $LevelBestStarRowsTable> {
  $$LevelBestStarRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestStars => $composableBuilder(
    column: $table.bestStars,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelBestStarRowsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $LevelBestStarRowsTable> {
  $$LevelBestStarRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestStars => $composableBuilder(
    column: $table.bestStars,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelBestStarRowsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $LevelBestStarRowsTable> {
  $$LevelBestStarRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<int> get bestStars =>
      $composableBuilder(column: $table.bestStars, builder: (column) => column);
}

class $$LevelBestStarRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $LevelBestStarRowsTable,
          LevelBestStarRow,
          $$LevelBestStarRowsTableFilterComposer,
          $$LevelBestStarRowsTableOrderingComposer,
          $$LevelBestStarRowsTableAnnotationComposer,
          $$LevelBestStarRowsTableCreateCompanionBuilder,
          $$LevelBestStarRowsTableUpdateCompanionBuilder,
          (
            LevelBestStarRow,
            BaseReferences<
              _$ProgressDatabase,
              $LevelBestStarRowsTable,
              LevelBestStarRow
            >,
          ),
          LevelBestStarRow,
          PrefetchHooks Function()
        > {
  $$LevelBestStarRowsTableTableManager(
    _$ProgressDatabase db,
    $LevelBestStarRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelBestStarRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelBestStarRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelBestStarRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> levelId = const Value.absent(),
                Value<int> bestStars = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelBestStarRowsCompanion(
                levelId: levelId,
                bestStars: bestStars,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String levelId,
                required int bestStars,
                Value<int> rowid = const Value.absent(),
              }) => LevelBestStarRowsCompanion.insert(
                levelId: levelId,
                bestStars: bestStars,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LevelBestStarRowsTable, LevelBestStarRow>(table),
                  BaseReferences<
                    _$ProgressDatabase,
                    $LevelBestStarRowsTable,
                    LevelBestStarRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelBestStarRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $LevelBestStarRowsTable,
      LevelBestStarRow,
      $$LevelBestStarRowsTableFilterComposer,
      $$LevelBestStarRowsTableOrderingComposer,
      $$LevelBestStarRowsTableAnnotationComposer,
      $$LevelBestStarRowsTableCreateCompanionBuilder,
      $$LevelBestStarRowsTableUpdateCompanionBuilder,
      (
        LevelBestStarRow,
        BaseReferences<
          _$ProgressDatabase,
          $LevelBestStarRowsTable,
          LevelBestStarRow
        >,
      ),
      LevelBestStarRow,
      PrefetchHooks Function()
    >;
typedef $$StickerPositionRowsTableCreateCompanionBuilder =
    StickerPositionRowsCompanion Function({
      required String stickerId,
      required double dx,
      required double dy,
      Value<int> rowid,
    });
typedef $$StickerPositionRowsTableUpdateCompanionBuilder =
    StickerPositionRowsCompanion Function({
      Value<String> stickerId,
      Value<double> dx,
      Value<double> dy,
      Value<int> rowid,
    });

class $$StickerPositionRowsTableFilterComposer
    extends Composer<_$ProgressDatabase, $StickerPositionRowsTable> {
  $$StickerPositionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dx => $composableBuilder(
    column: $table.dx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dy => $composableBuilder(
    column: $table.dy,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StickerPositionRowsTableOrderingComposer
    extends Composer<_$ProgressDatabase, $StickerPositionRowsTable> {
  $$StickerPositionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dx => $composableBuilder(
    column: $table.dx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dy => $composableBuilder(
    column: $table.dy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StickerPositionRowsTableAnnotationComposer
    extends Composer<_$ProgressDatabase, $StickerPositionRowsTable> {
  $$StickerPositionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stickerId =>
      $composableBuilder(column: $table.stickerId, builder: (column) => column);

  GeneratedColumn<double> get dx =>
      $composableBuilder(column: $table.dx, builder: (column) => column);

  GeneratedColumn<double> get dy =>
      $composableBuilder(column: $table.dy, builder: (column) => column);
}

class $$StickerPositionRowsTableTableManager
    extends
        RootTableManager<
          _$ProgressDatabase,
          $StickerPositionRowsTable,
          StickerPositionRow,
          $$StickerPositionRowsTableFilterComposer,
          $$StickerPositionRowsTableOrderingComposer,
          $$StickerPositionRowsTableAnnotationComposer,
          $$StickerPositionRowsTableCreateCompanionBuilder,
          $$StickerPositionRowsTableUpdateCompanionBuilder,
          (
            StickerPositionRow,
            BaseReferences<
              _$ProgressDatabase,
              $StickerPositionRowsTable,
              StickerPositionRow
            >,
          ),
          StickerPositionRow,
          PrefetchHooks Function()
        > {
  $$StickerPositionRowsTableTableManager(
    _$ProgressDatabase db,
    $StickerPositionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StickerPositionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StickerPositionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StickerPositionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> stickerId = const Value.absent(),
                Value<double> dx = const Value.absent(),
                Value<double> dy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickerPositionRowsCompanion(
                stickerId: stickerId,
                dx: dx,
                dy: dy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stickerId,
                required double dx,
                required double dy,
                Value<int> rowid = const Value.absent(),
              }) => StickerPositionRowsCompanion.insert(
                stickerId: stickerId,
                dx: dx,
                dy: dy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StickerPositionRowsTable, StickerPositionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$ProgressDatabase,
                    $StickerPositionRowsTable,
                    StickerPositionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StickerPositionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProgressDatabase,
      $StickerPositionRowsTable,
      StickerPositionRow,
      $$StickerPositionRowsTableFilterComposer,
      $$StickerPositionRowsTableOrderingComposer,
      $$StickerPositionRowsTableAnnotationComposer,
      $$StickerPositionRowsTableCreateCompanionBuilder,
      $$StickerPositionRowsTableUpdateCompanionBuilder,
      (
        StickerPositionRow,
        BaseReferences<
          _$ProgressDatabase,
          $StickerPositionRowsTable,
          StickerPositionRow
        >,
      ),
      StickerPositionRow,
      PrefetchHooks Function()
    >;

class $ProgressDatabaseManager {
  final _$ProgressDatabase _db;
  $ProgressDatabaseManager(this._db);
  $$ItemProgressRowsTableTableManager get itemProgressRows =>
      $$ItemProgressRowsTableTableManager(_db, _db.itemProgressRows);
  $$CorrectFirstTryDaysTableTableManager get correctFirstTryDays =>
      $$CorrectFirstTryDaysTableTableManager(_db, _db.correctFirstTryDays);
  $$EarnedStickerRowsTableTableManager get earnedStickerRows =>
      $$EarnedStickerRowsTableTableManager(_db, _db.earnedStickerRows);
  $$SettingsRowsTableTableManager get settingsRows =>
      $$SettingsRowsTableTableManager(_db, _db.settingsRows);
  $$TracingGuidedSuccessDaysTableTableManager get tracingGuidedSuccessDays =>
      $$TracingGuidedSuccessDaysTableTableManager(
        _db,
        _db.tracingGuidedSuccessDays,
      );
  $$LevelBestStarRowsTableTableManager get levelBestStarRows =>
      $$LevelBestStarRowsTableTableManager(_db, _db.levelBestStarRows);
  $$StickerPositionRowsTableTableManager get stickerPositionRows =>
      $$StickerPositionRowsTableTableManager(_db, _db.stickerPositionRows);
}
