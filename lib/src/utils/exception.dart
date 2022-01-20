/// Throw a specialized exception for expected situations
/// where the tool should exit with a clear message to the user
/// and no stack trace unless the --verbose option is specified.
/// For example: network errors
void throwToolExit(String message, {int? exitCode}) {
  throw ToolExit(message, exitCode: exitCode);
}

class ToolExit implements Exception {
  ToolExit(this.message, {this.exitCode});

  final String message;
  final int? exitCode;

  @override
  String toString() => 'Exception: $message';
}

/// Indicates to the linter that the given future is intentionally not `await`-ed.
///
/// Has the same functionality as `unawaited` from `package:pedantic`.
///
/// In an async context, it is normally expected than all Futures are awaited,
/// and that is the basis of the lint unawaited_futures which is turned on for
/// the flutter_tools package. However, there are times where one or more
/// futures are intentionally not awaited. This function may be used to ignore a
/// particular future. It silences the unawaited_futures lint.
void unawaited(Future<void> future) {}
