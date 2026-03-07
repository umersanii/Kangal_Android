import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_log_model.freezed.dart';
part 'sync_log_model.g.dart';

@freezed
class SyncLogModel with _$SyncLogModel {
  const factory SyncLogModel({
    required int id,
    required String tableName,
    required DateTime lastSyncedAt,
    required String status,
  }) = _SyncLogModel;

  factory SyncLogModel.fromJson(Map<String, dynamic> json) => _$SyncLogModelFromJson(json);
}