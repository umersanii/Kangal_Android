import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required int id,
    String? remoteId,
    required DateTime date,
    required double amount,
    required String source,
    String? type,
    String? transactionId,
    String? beneficiary,
    String? subject,
    int? categoryId,
    String? note,
    String? extra,
    DateTime? syncedAt,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
