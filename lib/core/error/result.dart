class Result<T> {
  final T? value;
  final Exception? error;

  Result({this.value, this.error});

  bool get isSuccess => value != null && error == null;

  bool get isError => value == null && error != null;

  T? getOrNull() => isSuccess ? value : null;

  Exception? getErrorOrNull() => isError ? error : null;
}
