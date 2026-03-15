import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_result.freezed.dart';
part 'sync_result.g.dart';

@freezed
abstract class SyncResult with _$SyncResult {
  const factory SyncResult({
    required int uploaded,
    required int downloaded,
    required int conflictsResolved,
    required bool success,
    String? errorMessage,
  }) = _SyncResult;

  factory SyncResult.fromJson(Map<String, dynamic> json) =>
      _$SyncResultFromJson(json);
}
