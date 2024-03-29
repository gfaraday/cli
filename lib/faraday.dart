library faraday;

import 'package:faraday/src/utils/log.dart';
import 'package:faraday/src/utils/version.g.dart';
import 'package:logging/logging.dart';

import 'src/runner/command_runner.dart';

const commonAnnotation = ['common'];
const routeAnnotation = ['entry'];

final log = Logger('faraday');

const versions = ['--version', 'version', '-v'];

void main(List<String> arguments) {
  final verbose = arguments.contains('--verbose');

  // append logger
  Logger.root.onRecord.listen(recordAnsiLog);
  Logger.root.level = verbose ? Level.ALL : Level.CONFIG;

  if (arguments.length == 1 &&
      versions.contains(arguments.first.toLowerCase())) {
    final welcome = '''
   ___                   _             
  / __\\_ _ _ __ __ _  __| | __ _ _   _ 
 / _\\/ _` | '__/ _` |/ _` |/ _` | | | |
/ / | (_| | | | (_| | (_| | (_| | |_| |
\\/   \\__,_|_|  \\__,_|\\__,_|\\__,_|\\__, |
                                 |___/       
    ''';
    log.info(welcome);
    print(version);
    return;
  }
  FaradayCommandRunner().run(arguments).then((v) {
    if (v != null && v is String && v.isNotEmpty) {
      print(v);
    }
  });
}
