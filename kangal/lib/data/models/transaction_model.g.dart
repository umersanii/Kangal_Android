// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    _TransactionModel(
      id: (json['id'] as num).toInt(),
      remoteId: json['remoteId'] as String?,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      type: json['type'] as String?,
      transactionId: json['transactionId'] as String?,
      beneficiary: json['beneficiary'] as String?,
      subject: json['subject'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      note: json['note'] as String?,
      extra: json['extra'] as String?,
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TransactionModelToJson(_TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'remoteId': instance.remoteId,
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'source': instance.source,
      'type': instance.type,
      'transactionId': instance.transactionId,
      'beneficiary': instance.beneficiary,
      'subject': instance.subject,
      'categoryId': instance.categoryId,
      'note': instance.note,
      'extra': instance.extra,
      'syncedAt': instance.syncedAt?.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
