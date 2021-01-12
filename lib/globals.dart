class RetroVMException implements Exception {
  RetroVMException(this.message);

  final String message;

  String toString() => 'Exception: $message';
}
