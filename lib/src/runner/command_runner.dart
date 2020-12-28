import 'package:args/command_runner.dart';

import '../commands/completion.dart';
import '../commands/generate.dart';
import '../commands/init.dart';
import '../commands/upgrade.dart';

class FaradayCommandRunner extends CommandRunner {
  FaradayCommandRunner() : super('faraday', 'g_faraday_scaffold cli.') {
    argParser.addFlag('verbose', abbr: 'v', negatable: false);
    addCommand(GenerateCommand());
    addCommand(CompletionCommand());
    addCommand(UpgradeCommand());
    addCommand(InitCommand());
  }
}
