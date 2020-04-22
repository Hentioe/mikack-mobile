class UnknownException implements Exception {
  final String message;

  UnknownException(this.message);

  String toString() {
    return 'UnknownException: $message';
  }
}
