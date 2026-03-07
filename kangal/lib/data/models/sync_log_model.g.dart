// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncLogModel _$SyncLogModelFromJson(Map<String, dynamic> json) =>
    _SyncLogModel(
      id: (json['id'] as num).toInt(),
      tableName: json['tableName'] as String,
      lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      status: json['status'] as String,
    );

Map<String, dynamic> _$SyncLogModelToJson(_SyncLogModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tableName': instance.tableName,
      'lastSyncedAt': instance.lastSyncedAt.toIso8601String(),
      'status': instance.status,
    };
