// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: type=lint
class TransactionsTableData extends DataClass
    implements Insertable<TransactionsTableData> {
  final int id;
  final String? remoteId;
  final String date;
  final double amount;
  final String source;
  final String? type;
  final String? transactionId;
  final String? beneficiary;
  final String? subject;
  final int? categoryId;
  final String? note;
  final String? extra;
  final DateTime? syncedAt;
  final DateTime updatedAt;
  final DateTime createdAt;
  TransactionsTableData(
      {required this.id,
      this.remoteId,
      required this.date,
      required this.amount,
      required this.source,
      this.type,
      this.transactionId,
      this.beneficiary,
      this.subject,
      this.categoryId,
      this.note,
      this.extra,
      this.syncedAt,
      required this.updatedAt,
      required this.createdAt});
  factory TransactionsTableData.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return TransactionsTableData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      remoteId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}remote_id']),
      date: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}date'])!,
      amount: const RealType()
          .mapFromDatabaseResponse(data['${effectivePrefix}amount'])!,
      source: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}source'])!,
      type: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}type']),
      transactionId: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}transaction_id']),
      beneficiary: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}beneficiary']),
      subject: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}subject']),
      categoryId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}category_id']),
      note: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}note']),
      extra: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}extra']),
      syncedAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}synced_at']),
      updatedAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}updated_at'])!,
      createdAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}created_at'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String?>(remoteId);
    }
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<double>(amount);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String?>(type);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String?>(transactionId);
    }
    if (!nullToAbsent || beneficiary != null) {
      map['beneficiary'] = Variable<String?>(beneficiary);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String?>(subject);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int?>(categoryId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String?>(note);
    }
    if (!nullToAbsent || extra != null) {
      map['extra'] = Variable<String?>(extra);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime?>(syncedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionsTableCompanion toCompanion(bool nullToAbsent) {
    return TransactionsTableCompanion(
      id: Value(id),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      date: Value(date),
      amount: Value(amount),
      source: Value(source),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      beneficiary: beneficiary == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiary),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      extra:
          extra == null && nullToAbsent ? const Value.absent() : Value(extra),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionsTableData(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      source: serializer.fromJson<String>(json['source']),
      type: serializer.fromJson<String?>(json['type']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      beneficiary: serializer.fromJson<String?>(json['beneficiary']),
      subject: serializer.fromJson<String?>(json['subject']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      note: serializer.fromJson<String?>(json['note']),
      extra: serializer.fromJson<String?>(json['extra']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String?>(remoteId),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<double>(amount),
      'source': serializer.toJson<String>(source),
      'type': serializer.toJson<String?>(type),
      'transactionId': serializer.toJson<String?>(transactionId),
      'beneficiary': serializer.toJson<String?>(beneficiary),
      'subject': serializer.toJson<String?>(subject),
      'categoryId': serializer.toJson<int?>(categoryId),
      'note': serializer.toJson<String?>(note),
      'extra': serializer.toJson<String?>(extra),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionsTableData copyWith(
          {int? id,
          String? remoteId,
          String? date,
          double? amount,
          String? source,
          String? type,
          String? transactionId,
          String? beneficiary,
          String? subject,
          int? categoryId,
          String? note,
          String? extra,
          DateTime? syncedAt,
          DateTime? updatedAt,
          DateTime? createdAt}) =>
      TransactionsTableData(
        id: id ?? this.id,
        remoteId: remoteId ?? this.remoteId,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        source: source ?? this.source,
        type: type ?? this.type,
        transactionId: transactionId ?? this.transactionId,
        beneficiary: beneficiary ?? this.beneficiary,
        subject: subject ?? this.subject,
        categoryId: categoryId ?? this.categoryId,
        note: note ?? this.note,
        extra: extra ?? this.extra,
        syncedAt: syncedAt ?? this.syncedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  @override
  String toString() {
    return (StringBuffer('TransactionsTableData(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('transactionId: $transactionId, ')
          ..write('beneficiary: $beneficiary, ')
          ..write('subject: $subject, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('extra: $extra, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      remoteId,
      date,
      amount,
      source,
      type,
      transactionId,
      beneficiary,
      subject,
      categoryId,
      note,
      extra,
      syncedAt,
      updatedAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionsTableData &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.source == this.source &&
          other.type == this.type &&
          other.transactionId == this.transactionId &&
          other.beneficiary == this.beneficiary &&
          other.subject == this.subject &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.extra == this.extra &&
          other.syncedAt == this.syncedAt &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class TransactionsTableCompanion
    extends UpdateCompanion<TransactionsTableData> {
  final Value<int> id;
  final Value<String?> remoteId;
  final Value<String> date;
  final Value<double> amount;
  final Value<String> source;
  final Value<String?> type;
  final Value<String?> transactionId;
  final Value<String?> beneficiary;
  final Value<String?> subject;
  final Value<int?> categoryId;
  final Value<String?> note;
  final Value<String?> extra;
  final Value<DateTime?> syncedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  const TransactionsTableCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.source = const Value.absent(),
    this.type = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.beneficiary = const Value.absent(),
    this.subject = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.extra = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsTableCompanion.insert({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String date,
    required double amount,
    required String source,
    this.type = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.beneficiary = const Value.absent(),
    this.subject = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.extra = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : date = Value(date),
        amount = Value(amount),
        source = Value(source);
  static Insertable<TransactionsTableData> custom({
    Expression<int>? id,
    Expression<String?>? remoteId,
    Expression<String>? date,
    Expression<double>? amount,
    Expression<String>? source,
    Expression<String?>? type,
    Expression<String?>? transactionId,
    Expression<String?>? beneficiary,
    Expression<String?>? subject,
    Expression<int?>? categoryId,
    Expression<String?>? note,
    Expression<String?>? extra,
    Expression<DateTime?>? syncedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (source != null) 'source': source,
      if (type != null) 'type': type,
      if (transactionId != null) 'transaction_id': transactionId,
      if (beneficiary != null) 'beneficiary': beneficiary,
      if (subject != null) 'subject': subject,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (extra != null) 'extra': extra,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsTableCompanion copyWith(
      {Value<int>? id,
      Value<String?>? remoteId,
      Value<String>? date,
      Value<double>? amount,
      Value<String>? source,
      Value<String?>? type,
      Value<String?>? transactionId,
      Value<String?>? beneficiary,
      Value<String?>? subject,
      Value<int?>? categoryId,
      Value<String?>? note,
      Value<String?>? extra,
      Value<DateTime?>? syncedAt,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt}) {
    return TransactionsTableCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      type: type ?? this.type,
      transactionId: transactionId ?? this.transactionId,
      beneficiary: beneficiary ?? this.beneficiary,
      subject: subject ?? this.subject,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      extra: extra ?? this.extra,
      syncedAt: syncedAt ?? this.syncedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String?>(remoteId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (type.present) {
      map['type'] = Variable<String?>(type.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String?>(transactionId.value);
    }
    if (beneficiary.present) {
      map['beneficiary'] = Variable<String?>(beneficiary.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String?>(subject.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int?>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String?>(note.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String?>(extra.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime?>(syncedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsTableCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('source: $source, ')
          ..write('type: $type, ')
          ..write('transactionId: $transactionId, ')
          ..write('beneficiary: $beneficiary, ')
          ..write('subject: $subject, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('extra: $extra, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTableTable extends TransactionsTable
    with TableInfo<$TransactionsTableTable, TransactionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTableTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _remoteIdMeta = const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String?> remoteId = GeneratedColumn<String?>(
      'remote_id', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String?> date = GeneratedColumn<String?>(
      'date', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double?> amount = GeneratedColumn<double?>(
      'amount', aliasedName, false,
      type: const RealType(), requiredDuringInsert: true);
  final VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String?> source = GeneratedColumn<String?>(
      'source', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String?> type = GeneratedColumn<String?>(
      'type', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String?> transactionId = GeneratedColumn<String?>(
      'transaction_id', aliasedName, true,
      type: const StringType(),
      requiredDuringInsert: false,
      defaultConstraints: 'UNIQUE');
  final VerificationMeta _beneficiaryMeta =
      const VerificationMeta('beneficiary');
  @override
  late final GeneratedColumn<String?> beneficiary = GeneratedColumn<String?>(
      'beneficiary', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _subjectMeta = const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String?> subject = GeneratedColumn<String?>(
      'subject', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int?> categoryId = GeneratedColumn<int?>(
      'category_id', aliasedName, true,
      type: const IntType(),
      requiredDuringInsert: false,
      $customConstraints: 'REFERENCES categories(id)');
  final VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String?> note = GeneratedColumn<String?>(
      'note', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String?> extra = GeneratedColumn<String?>(
      'extra', aliasedName, true,
      type: const StringType(), requiredDuringInsert: false);
  final VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime?> syncedAt = GeneratedColumn<DateTime?>(
      'synced_at', aliasedName, true,
      type: const IntType(), requiredDuringInsert: false);
  final VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime?> updatedAt = GeneratedColumn<DateTime?>(
      'updated_at', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  final VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime?> createdAt = GeneratedColumn<DateTime?>(
      'created_at', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        remoteId,
        date,
        amount,
        source,
        type,
        transactionId,
        beneficiary,
        subject,
        categoryId,
        note,
        extra,
        syncedAt,
        updatedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? 'transactions_table';
  @override
  String get actualTableName => 'transactions_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<TransactionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    }
    if (data.containsKey('beneficiary')) {
      context.handle(
          _beneficiaryMeta,
          beneficiary.isAcceptableOrUnknown(
              data['beneficiary']!, _beneficiaryMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('extra')) {
      context.handle(
          _extraMeta, extra.isAcceptableOrUnknown(data['extra']!, _extraMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return TransactionsTableData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $TransactionsTableTable createAlias(String alias) {
    return $TransactionsTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  final int id;
  final String name;
  final String emoji;
  final String color;
  final bool isDefault;
  CategoriesTableData(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.color,
      required this.isDefault});
  factory CategoriesTableData.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return CategoriesTableData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      emoji: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}emoji'])!,
      color: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}color'])!,
      isDefault: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}is_default'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['color'] = Variable<String>(color);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      color: Value(color),
      isDefault: Value(isDefault),
    );
  }

  factory CategoriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      color: serializer.fromJson<String>(json['color']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'color': serializer.toJson<String>(color),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  CategoriesTableData copyWith(
          {int? id,
          String? name,
          String? emoji,
          String? color,
          bool? isDefault}) =>
      CategoriesTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        isDefault: isDefault ?? this.isDefault,
      );
  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emoji, color, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.color == this.color &&
          other.isDefault == this.isDefault);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<String> color;
  final Value<bool> isDefault;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.color = const Value.absent(),
    this.isDefault = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String emoji,
    required String color,
    this.isDefault = const Value.absent(),
  })  : name = Value(name),
        emoji = Value(emoji),
        color = Value(color);
  static Insertable<CategoriesTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<String>? color,
    Expression<bool>? isDefault,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
      if (isDefault != null) 'is_default': isDefault,
    });
  }

  CategoriesTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? emoji,
      Value<String>? color,
      Value<bool>? isDefault}) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('color: $color, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String?> emoji = GeneratedColumn<String?>(
      'emoji', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String?> color = GeneratedColumn<String?>(
      'color', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _isDefaultMeta = const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool?> isDefault = GeneratedColumn<bool?>(
      'is_default', aliasedName, false,
      type: const BoolType(),
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (is_default IN (0, 1))',
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, name, emoji, color, isDefault];
  @override
  String get aliasedName => _alias ?? 'categories_table';
  @override
  String get actualTableName => 'categories_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return CategoriesTableData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class RulesTableData extends DataClass implements Insertable<RulesTableData> {
  final int id;
  final String keyword;
  final int categoryId;
  RulesTableData(
      {required this.id, required this.keyword, required this.categoryId});
  factory RulesTableData.fromData(Map<String, dynamic> data, {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return RulesTableData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      keyword: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}keyword'])!,
      categoryId: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}category_id'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['keyword'] = Variable<String>(keyword);
    map['category_id'] = Variable<int>(categoryId);
    return map;
  }

  RulesTableCompanion toCompanion(bool nullToAbsent) {
    return RulesTableCompanion(
      id: Value(id),
      keyword: Value(keyword),
      categoryId: Value(categoryId),
    );
  }

  factory RulesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RulesTableData(
      id: serializer.fromJson<int>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyword': serializer.toJson<String>(keyword),
      'categoryId': serializer.toJson<int>(categoryId),
    };
  }

  RulesTableData copyWith({int? id, String? keyword, int? categoryId}) =>
      RulesTableData(
        id: id ?? this.id,
        keyword: keyword ?? this.keyword,
        categoryId: categoryId ?? this.categoryId,
      );
  @override
  String toString() {
    return (StringBuffer('RulesTableData(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RulesTableData &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.categoryId == this.categoryId);
}

class RulesTableCompanion extends UpdateCompanion<RulesTableData> {
  final Value<int> id;
  final Value<String> keyword;
  final Value<int> categoryId;
  const RulesTableCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  RulesTableCompanion.insert({
    this.id = const Value.absent(),
    required String keyword,
    required int categoryId,
  })  : keyword = Value(keyword),
        categoryId = Value(categoryId);
  static Insertable<RulesTableData> custom({
    Expression<int>? id,
    Expression<String>? keyword,
    Expression<int>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  RulesTableCompanion copyWith(
      {Value<int>? id, Value<String>? keyword, Value<int>? categoryId}) {
    return RulesTableCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulesTableCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

class $RulesTableTable extends RulesTable
    with TableInfo<$RulesTableTable, RulesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulesTableTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _keywordMeta = const VerificationMeta('keyword');
  @override
  late final GeneratedColumn<String?> keyword = GeneratedColumn<String?>(
      'keyword', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  final VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int?> categoryId = GeneratedColumn<int?>(
      'category_id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES categories(id)');
  @override
  List<GeneratedColumn> get $columns => [id, keyword, categoryId];
  @override
  String get aliasedName => _alias ?? 'rules_table';
  @override
  String get actualTableName => 'rules_table';
  @override
  VerificationContext validateIntegrity(Insertable<RulesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('keyword')) {
      context.handle(_keywordMeta,
          keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta));
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RulesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return RulesTableData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $RulesTableTable createAlias(String alias) {
    return $RulesTableTable(attachedDatabase, alias);
  }
}

class SyncLogTableData extends DataClass
    implements Insertable<SyncLogTableData> {
  final int id;
  final DateTime lastSyncedAt;
  final String status;
  SyncLogTableData(
      {required this.id, required this.lastSyncedAt, required this.status});
  factory SyncLogTableData.fromData(Map<String, dynamic> data,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return SyncLogTableData(
      id: const IntType()
          .mapFromDatabaseResponse(data['${effectivePrefix}id'])!,
      lastSyncedAt: const DateTimeType()
          .mapFromDatabaseResponse(data['${effectivePrefix}last_synced_at'])!,
      status: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}status'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncLogTableCompanion toCompanion(bool nullToAbsent) {
    return SyncLogTableCompanion(
      id: Value(id),
      lastSyncedAt: Value(lastSyncedAt),
      status: Value(status),
    );
  }

  factory SyncLogTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogTableData(
      id: serializer.fromJson<int>(json['id']),
      lastSyncedAt: serializer.fromJson<DateTime>(json['lastSyncedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastSyncedAt': serializer.toJson<DateTime>(lastSyncedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncLogTableData copyWith(
          {int? id, DateTime? lastSyncedAt, String? status}) =>
      SyncLogTableData(
        id: id ?? this.id,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        status: status ?? this.status,
      );
  @override
  String toString() {
    return (StringBuffer('SyncLogTableData(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastSyncedAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogTableData &&
          other.id == this.id &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.status == this.status);
}

class SyncLogTableCompanion extends UpdateCompanion<SyncLogTableData> {
  final Value<int> id;
  final Value<DateTime> lastSyncedAt;
  final Value<String> status;
  const SyncLogTableCompanion({
    this.id = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncLogTableCompanion.insert({
    this.id = const Value.absent(),
    required DateTime lastSyncedAt,
    required String status,
  })  : lastSyncedAt = Value(lastSyncedAt),
        status = Value(status);
  static Insertable<SyncLogTableData> custom({
    Expression<int>? id,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (status != null) 'status': status,
    });
  }

  SyncLogTableCompanion copyWith(
      {Value<int>? id, Value<DateTime>? lastSyncedAt, Value<String>? status}) {
    return SyncLogTableCompanion(
      id: id ?? this.id,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogTableCompanion(')
          ..write('id: $id, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTableTable extends SyncLogTable
    with TableInfo<$SyncLogTableTable, SyncLogTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTableTable(this.attachedDatabase, [this._alias]);
  final VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int?> id = GeneratedColumn<int?>(
      'id', aliasedName, false,
      type: const IntType(),
      requiredDuringInsert: false,
      defaultConstraints: 'PRIMARY KEY AUTOINCREMENT');
  final VerificationMeta _lastSyncedAtMeta =
      const VerificationMeta('lastSyncedAt');
  @override
  late final GeneratedColumn<DateTime?> lastSyncedAt =
      GeneratedColumn<DateTime?>('last_synced_at', aliasedName, false,
          type: const IntType(), requiredDuringInsert: true);
  final VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String?> status = GeneratedColumn<String?>(
      'status', aliasedName, false,
      type: const StringType(), requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, lastSyncedAt, status];
  @override
  String get aliasedName => _alias ?? 'sync_log';
  @override
  String get actualTableName => 'sync_log';
  @override
  VerificationContext validateIntegrity(Insertable<SyncLogTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
          _lastSyncedAtMeta,
          lastSyncedAt.isAcceptableOrUnknown(
              data['last_synced_at']!, _lastSyncedAtMeta));
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    return SyncLogTableData.fromData(data,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $SyncLogTableTable createAlias(String alias) {
    return $SyncLogTableTable(attachedDatabase, alias);
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $TransactionsTableTable transactionsTable =
      $TransactionsTableTable(this);
  late final $CategoriesTableTable categoriesTable =
      $CategoriesTableTable(this);
  late final $RulesTableTable rulesTable = $RulesTableTable(this);
  late final $SyncLogTableTable syncLogTable = $SyncLogTableTable(this);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [transactionsTable, categoriesTable, rulesTable, syncLogTable];
}
