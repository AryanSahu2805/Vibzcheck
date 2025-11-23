/// Simple logger utility to replace print statements
class Logger {
  static void debug(String message) {
    // ignore: avoid_print
    print('🔍 [DEBUG] $message');
  }

  static void info(String message) {
    // ignore: avoid_print
    print('ℹ️  [INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('❌ [ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print('   Error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('   StackTrace: $stackTrace');
    }
  }

  static void success(String message) {
    // ignore: avoid_print
    print('✅ [SUCCESS] $message');
  }

  static void warning(String message) {
    // ignore: avoid_print
    print('⚠️  [WARNING] $message');
  }
}

