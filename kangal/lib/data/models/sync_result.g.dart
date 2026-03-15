// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncResult _$SyncResultFromJson(Map<String, dynamic> json) => _SyncResult(
  uploaded: (json['uploaded'] as num).toInt(),
  downloaded: (json['downloaded'] as num).toInt(),
  conflictsResolved: (json['conflictsResolved'] as num).toInt(),
  success: json['success'] as bool,
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$SyncResultToJson(_SyncResult instance) =>
    <String, dynamic>{
      'uploaded': instance.uploaded,
      'downloaded': instance.downloaded,
      'conflictsResolved': instance.conflictsResolved,
      'success': instance.success,
      'errorMessage': instance.errorMessage,
    };
