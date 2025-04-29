import 'dart:developer';

class Logger {
  static void logInfo(String message) {
    log('INFO: $message');
  }

  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    log('ERROR: $message', error: error, stackTrace: stackTrace);
  }

  static void logWarning(String message) {
    log('WARNING: $message');
  }
}