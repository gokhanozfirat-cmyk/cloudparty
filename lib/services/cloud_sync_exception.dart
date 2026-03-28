class CloudSyncException implements Exception {
  CloudSyncException(this.message, {this.debugDetails});

  final String message;
  final String? debugDetails;

  @override
  String toString() {
    if (debugDetails == null || debugDetails!.isEmpty) {
      return message;
    }
    return '$message ($debugDetails)';
  }
}
