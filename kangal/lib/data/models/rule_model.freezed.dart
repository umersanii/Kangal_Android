// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RuleModel {

 int get id; String get keyword; int get categoryId;
/// Create a copy of RuleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleModelCopyWith<RuleModel> get copyWith => _$RuleModelCopyWithImpl<RuleModel>(this as RuleModel, _$identity);

  /// Serializes this RuleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,keyword,categoryId);

@override
String toString() {
  return 'RuleModel(id: $id, keyword: $keyword, categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class $RuleModelCopyWith<$Res>  {
  factory $RuleModelCopyWith(RuleModel value, $Res Function(RuleModel) _then) = _$RuleModelCopyWithImpl;
@useResult
$Res call({
 int id, String keyword, int categoryId
});




}
/// @nodoc
class _$RuleModelCopyWithImpl<$Res>
    implements $RuleModelCopyWith<$Res> {
  _$RuleModelCopyWithImpl(this._self, this._then);

  final RuleModel _self;
  final $Res Function(RuleModel) _then;

/// Create a copy of RuleModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? keyword = null,Object? categoryId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleModel].
extension RuleModelPatterns on RuleModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleModel value)  $default,){
final _that = this;
switch (_that) {
case _RuleModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleModel value)?  $default,){
final _that = this;
switch (_that) {
case _RuleModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String keyword,  int categoryId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleModel() when $default != null:
return $default(_that.id,_that.keyword,_that.categoryId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String keyword,  int categoryId)  $default,) {final _that = this;
switch (_that) {
case _RuleModel():
return $default(_that.id,_that.keyword,_that.categoryId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String keyword,  int categoryId)?  $default,) {final _that = this;
switch (_that) {
case _RuleModel() when $default != null:
return $default(_that.id,_that.keyword,_that.categoryId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuleModel implements RuleModel {
  const _RuleModel({required this.id, required this.keyword, required this.categoryId});
  factory _RuleModel.fromJson(Map<String, dynamic> json) => _$RuleModelFromJson(json);

@override final  int id;
@override final  String keyword;
@override final  int categoryId;

/// Create a copy of RuleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleModelCopyWith<_RuleModel> get copyWith => __$RuleModelCopyWithImpl<_RuleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,keyword,categoryId);

@override
String toString() {
  return 'RuleModel(id: $id, keyword: $keyword, categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class _$RuleModelCopyWith<$Res> implements $RuleModelCopyWith<$Res> {
  factory _$RuleModelCopyWith(_RuleModel value, $Res Function(_RuleModel) _then) = __$RuleModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String keyword, int categoryId
});




}
/// @nodoc
class __$RuleModelCopyWithImpl<$Res>
    implements _$RuleModelCopyWith<$Res> {
  __$RuleModelCopyWithImpl(this._self, this._then);

  final _RuleModel _self;
  final $Res Function(_RuleModel) _then;

/// Create a copy of RuleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? keyword = null,Object? categoryId = null,}) {
  return _then(_RuleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
