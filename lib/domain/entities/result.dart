import 'package:flutter/foundation.dart';
import '../failures/app_failure.dart';

/// Result type for async operations with built-in error handling
sealed class Result<T> {
  const Result();

  /// Map result to another type
  Result<R> map<R>(R Function(T) f) =>
      maybeMap(
        success: (value) => Success(f(value)),
        failure: (failure) => Failure(failure),
      );

  /// Map with handling both success and failure
  Result<R> maybeMap<R>({
    required R Function(T) success,
    required R Function(AppFailure) failure,
  }) =>
      switch (this) {
        Success(value: final value) => Success(success(value)),
        Failure(failure: final f) => Failure(failure(f)),
      };

  /// Fold result into a single value
  R fold<R>({
    required R Function(T) onSuccess,
    required R Function(AppFailure) onFailure,
  }) =>
      switch (this) {
        Success(value: final value) => onSuccess(value),
        Failure(failure: final failure) => onFailure(failure),
      };

  /// Get value or throw
  T getOrThrow() =>
      switch (this) {
        Success(value: final value) => value,
        Failure(failure: final failure) => throw failure,
      };

  /// Check if success
  bool get isSuccess => this is Success;

  /// Check if failure
  bool get isFailure => this is Failure;
}

/// Success result with value
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failure result with error
final class Failure<T> extends Result<T> {
  final AppFailure failure;

  const Failure(this.failure);

  @override
  String toString() => 'Failure($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}
