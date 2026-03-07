// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_log_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncLogModel {

 int get id; String get tableName; DateTime get lastSyncedAt; String get status;
/// Create a copy of SyncLogModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncLogModelCopyWith<SyncLogModel> get copyWith => _$SyncLogModelCopyWithImpl<SyncLogModel>(this as SyncLogModel, _$identity);

  /// Serializes this SyncLogModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncLogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tableName, tableName) || other.tableName == tableName)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableName,lastSyncedAt,status);

@override
String toString() {
  return 'SyncLogModel(id: $id, tableName: $tableName, lastSyncedAt: $lastSyncedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $SyncLogModelCopyWith<$Res>  {
  factory $SyncLogModelCopyWith(SyncLogModel value, $Res Function(SyncLogModel) _then) = _$SyncLogModelCopyWithImpl;
@useResult
$Res call({
 int id, String tableName, DateTime lastSyncedAt, String status
});




}
/// @nodoc
class _$SyncLogModelCopyWithImpl<$Res>
    implements $SyncLogModelCopyWith<$Res> {
  _$SyncLogModelCopyWithImpl(this._self, this._then);

  final SyncLogModel _self;
  final $Res Function(SyncLogModel) _then;

/// Create a copy of SyncLogModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tableName = null,Object? lastSyncedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tableName: null == tableName ? _self.tableName : tableName // ignore: cast_nullable_to_non_nullable
as String,lastSyncedAt: null == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncLogModel].
extension SyncLogModelPatterns on SyncLogModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncLogModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncLogModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncLogModel value)  $default,){
final _that = this;
switch (_that) {
case _SyncLogModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncLogModel value)?  $default,){
final _that = this;
switch (_that) {
case _SyncLogModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String tableName,  DateTime lastSyncedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncLogModel() when $default != null:
return $default(_that.id,_that.tableName,_that.lastSyncedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String tableName,  DateTime lastSyncedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _SyncLogModel():
return $default(_that.id,_that.tableName,_that.lastSyncedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String tableName,  DateTime lastSyncedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _SyncLogModel() when $default != null:
return $default(_that.id,_that.tableName,_that.lastSyncedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncLogModel implements SyncLogModel {
  const _SyncLogModel({required this.id, required this.tableName, required this.lastSyncedAt, required this.status});
  factory _SyncLogModel.fromJson(Map<String, dynamic> json) => _$SyncLogModelFromJson(json);

@override final  int id;
@override final  String tableName;
@override final  DateTime lastSyncedAt;
@override final  String status;

/// Create a copy of SyncLogModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncLogModelCopyWith<_SyncLogModel> get copyWith => __$SyncLogModelCopyWithImpl<_SyncLogModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncLogModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncLogModel&&(identical(other.id, id) || other.id == id)&&(identical(other.tableName, tableName) || other.tableName == tableName)&&(identical(other.lastSyncedAt, lastSyncedAt) || other.lastSyncedAt == lastSyncedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tableName,lastSyncedAt,status);

@override
String toString() {
  return 'SyncLogModel(id: $id, tableName: $tableName, lastSyncedAt: $lastSyncedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SyncLogModelCopyWith<$Res> implements $SyncLogModelCopyWith<$Res> {
  factory _$SyncLogModelCopyWith(_SyncLogModel value, $Res Function(_SyncLogModel) _then) = __$SyncLogModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String tableName, DateTime lastSyncedAt, String status
});




}
/// @nodoc
class __$SyncLogModelCopyWithImpl<$Res>
    implements _$SyncLogModelCopyWith<$Res> {
  __$SyncLogModelCopyWithImpl(this._self, this._then);

  final _SyncLogModel _self;
  final $Res Function(_SyncLogModel) _then;

/// Create a copy of SyncLogModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tableName = null,Object? lastSyncedAt = null,Object? status = null,}) {
  return _then(_SyncLogModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,tableName: null == tableName ? _self.tableName : tableName // ignore: cast_nullable_to_non_nullable
as String,lastSyncedAt: null == lastSyncedAt ? _self.lastSyncedAt : lastSyncedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
