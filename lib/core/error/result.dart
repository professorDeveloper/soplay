sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Failure<T>;

  T? getOrNull() => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  Exception? getErrorOrNull() => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final Exception error;
  const Failure(this.error);
}
