// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RuleModel _$RuleModelFromJson(Map<String, dynamic> json) => _RuleModel(
  id: (json['id'] as num).toInt(),
  keyword: json['keyword'] as String,
  categoryId: (json['categoryId'] as num).toInt(),
);

Map<String, dynamic> _$RuleModelToJson(_RuleModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'keyword': instance.keyword,
      'categoryId': instance.categoryId,
    };
