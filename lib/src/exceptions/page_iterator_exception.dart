class PageIteratorException implements Exception {
  final String message;

  PageIteratorException(this.message);

  String toString() {
    return 'PageIteratorException: $message';
  }
}
