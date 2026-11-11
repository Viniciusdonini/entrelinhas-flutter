/// A recoverable data-layer failure with a message suitable for the interface.
class ServiceException implements Exception {
  const ServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
