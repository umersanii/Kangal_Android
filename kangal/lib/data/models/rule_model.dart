import 'package:freezed_annotation/freezed_annotation.dart';

part 'rule_model.freezed.dart';
part 'rule_model.g.dart';

@freezed
abstract class RuleModel with _$RuleModel {
  const factory RuleModel({
    required int id,
    required String keyword,
    required int categoryId,
  }) = _RuleModel;

  factory RuleModel.fromJson(Map<String, dynamic> json) =>
      _$RuleModelFromJson(json);
}
