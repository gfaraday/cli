library faraday;

import 'package:faraday/src/utils/log.dart';
import 'package:logging/logging.dart';

import 'src/runner/command_runner.dart';

const commonAnnotation = ['common'];
const routeAnnotation = ['entry'];

final log = Logger('faraday');

void main(List<String> arguments) {
  final verbose = arguments.contains('--verbose');

  // append logger
  Logger.root.onRecord.listen(recordAnsiLog);
  Logger.root.level = verbose ? Level.ALL : Level.WARNING;

  if (arguments.length == 1 && arguments.first == '--version') {
    print('1.0.4');
    return;
  }
  FaradayCommandRunner().run(arguments).then((v) {
    if (v != null && v is String && v.isNotEmpty) {
      print(v);
    }
  });
}
