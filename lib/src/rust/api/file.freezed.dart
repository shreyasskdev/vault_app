// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VaultError {
  String get field0 => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VaultError_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VaultError_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VaultError_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $VaultErrorCopyWith<VaultError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultErrorCopyWith<$Res> {
  factory $VaultErrorCopyWith(
          VaultError value, $Res Function(VaultError) then) =
      _$VaultErrorCopyWithImpl<$Res, VaultError>;
  @useResult
  $Res call({String field0});
}

/// @nodoc
class _$VaultErrorCopyWithImpl<$Res, $Val extends VaultError>
    implements $VaultErrorCopyWith<$Res> {
  _$VaultErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_value.copyWith(
      field0: null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VaultError_ErrorImplCopyWith<$Res>
    implements $VaultErrorCopyWith<$Res> {
  factory _$$VaultError_ErrorImplCopyWith(_$VaultError_ErrorImpl value,
          $Res Function(_$VaultError_ErrorImpl) then) =
      __$$VaultError_ErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field0});
}

/// @nodoc
class __$$VaultError_ErrorImplCopyWithImpl<$Res>
    extends _$VaultErrorCopyWithImpl<$Res, _$VaultError_ErrorImpl>
    implements _$$VaultError_ErrorImplCopyWith<$Res> {
  __$$VaultError_ErrorImplCopyWithImpl(_$VaultError_ErrorImpl _value,
      $Res Function(_$VaultError_ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$VaultError_ErrorImpl(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$VaultError_ErrorImpl extends VaultError_Error {
  const _$VaultError_ErrorImpl(this.field0) : super._();

  @override
  final String field0;

  @override
  String toString() {
    return 'VaultError.error(field0: $field0)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultError_ErrorImpl &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultError_ErrorImplCopyWith<_$VaultError_ErrorImpl> get copyWith =>
      __$$VaultError_ErrorImplCopyWithImpl<_$VaultError_ErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) error,
  }) {
    return error(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? error,
  }) {
    return error?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VaultError_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VaultError_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VaultError_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class VaultError_Error extends VaultError {
  const factory VaultError_Error(final String field0) = _$VaultError_ErrorImpl;
  const VaultError_Error._() : super._();

  @override
  String get field0;
  @override
  @JsonKey(ignore: true)
  _$$VaultError_ErrorImplCopyWith<_$VaultError_ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
