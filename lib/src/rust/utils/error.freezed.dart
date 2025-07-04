// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VaultError {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) error,
    required TResult Function() incorrectPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? error,
    TResult? Function()? incorrectPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? error,
    TResult Function()? incorrectPassword,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VaultError_Error value) error,
    required TResult Function(VaultError_IncorrectPassword value)
        incorrectPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VaultError_Error value)? error,
    TResult? Function(VaultError_IncorrectPassword value)? incorrectPassword,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VaultError_Error value)? error,
    TResult Function(VaultError_IncorrectPassword value)? incorrectPassword,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VaultErrorCopyWith<$Res> {
  factory $VaultErrorCopyWith(
          VaultError value, $Res Function(VaultError) then) =
      _$VaultErrorCopyWithImpl<$Res, VaultError>;
}

/// @nodoc
class _$VaultErrorCopyWithImpl<$Res, $Val extends VaultError>
    implements $VaultErrorCopyWith<$Res> {
  _$VaultErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VaultError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$VaultError_ErrorImplCopyWith<$Res> {
  factory _$$VaultError_ErrorImplCopyWith(_$VaultError_ErrorImpl value,
          $Res Function(_$VaultError_ErrorImpl) then) =
      __$$VaultError_ErrorImplCopyWithImpl<$Res>;
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

  /// Create a copy of VaultError
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of VaultError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VaultError_ErrorImplCopyWith<_$VaultError_ErrorImpl> get copyWith =>
      __$$VaultError_ErrorImplCopyWithImpl<_$VaultError_ErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) error,
    required TResult Function() incorrectPassword,
  }) {
    return error(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? error,
    TResult? Function()? incorrectPassword,
  }) {
    return error?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? error,
    TResult Function()? incorrectPassword,
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
    required TResult Function(VaultError_IncorrectPassword value)
        incorrectPassword,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VaultError_Error value)? error,
    TResult? Function(VaultError_IncorrectPassword value)? incorrectPassword,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VaultError_Error value)? error,
    TResult Function(VaultError_IncorrectPassword value)? incorrectPassword,
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

  String get field0;

  /// Create a copy of VaultError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VaultError_ErrorImplCopyWith<_$VaultError_ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VaultError_IncorrectPasswordImplCopyWith<$Res> {
  factory _$$VaultError_IncorrectPasswordImplCopyWith(
          _$VaultError_IncorrectPasswordImpl value,
          $Res Function(_$VaultError_IncorrectPasswordImpl) then) =
      __$$VaultError_IncorrectPasswordImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VaultError_IncorrectPasswordImplCopyWithImpl<$Res>
    extends _$VaultErrorCopyWithImpl<$Res, _$VaultError_IncorrectPasswordImpl>
    implements _$$VaultError_IncorrectPasswordImplCopyWith<$Res> {
  __$$VaultError_IncorrectPasswordImplCopyWithImpl(
      _$VaultError_IncorrectPasswordImpl _value,
      $Res Function(_$VaultError_IncorrectPasswordImpl) _then)
      : super(_value, _then);

  /// Create a copy of VaultError
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$VaultError_IncorrectPasswordImpl extends VaultError_IncorrectPassword {
  const _$VaultError_IncorrectPasswordImpl() : super._();

  @override
  String toString() {
    return 'VaultError.incorrectPassword()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VaultError_IncorrectPasswordImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String field0) error,
    required TResult Function() incorrectPassword,
  }) {
    return incorrectPassword();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String field0)? error,
    TResult? Function()? incorrectPassword,
  }) {
    return incorrectPassword?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String field0)? error,
    TResult Function()? incorrectPassword,
    required TResult orElse(),
  }) {
    if (incorrectPassword != null) {
      return incorrectPassword();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(VaultError_Error value) error,
    required TResult Function(VaultError_IncorrectPassword value)
        incorrectPassword,
  }) {
    return incorrectPassword(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(VaultError_Error value)? error,
    TResult? Function(VaultError_IncorrectPassword value)? incorrectPassword,
  }) {
    return incorrectPassword?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(VaultError_Error value)? error,
    TResult Function(VaultError_IncorrectPassword value)? incorrectPassword,
    required TResult orElse(),
  }) {
    if (incorrectPassword != null) {
      return incorrectPassword(this);
    }
    return orElse();
  }
}

abstract class VaultError_IncorrectPassword extends VaultError {
  const factory VaultError_IncorrectPassword() =
      _$VaultError_IncorrectPasswordImpl;
  const VaultError_IncorrectPassword._() : super._();
}
