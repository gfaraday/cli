import 'dart:io';

import 'package:g_json/g_json.dart';
import 'package:path/path.dart' as path;

import '../commands/command.dart';
import '../services/processor.dart';
import '../utils/exception.dart';

class GenerateCommand extends FaradayCommand {
  GenerateCommand() : super() {
    argParser.addOption('file', abbr: 'f', help: '解析指定文件');
  }

  @override
  String get description => 'generate route&common method(s)';

  @override
  String get name => 'generate';

  @override
  String run() {
    String projectRoot;
    final filePath = stringArg('file');

    if (filePath != null && filePath.contains('lib/')) {
      projectRoot = filePath.split('lib/').first;

      log.info('project root ' + projectRoot);

      final sourceCode = File(filePath).readAsStringSync() ?? '';
      log.info('source code length: ${sourceCode.length}');

      process(sourceCode, projectRoot, filePath.split('lib/').last,
          outputs(projectRoot));

      return 'generated common(s)&route(s) for $filePath';
    }

    // 从当前目录开始查找 项目根目录
    //
    final pwd = path.current;
    if (File(path.join(pwd, 'pubspec.yaml')).existsSync()) {
      projectRoot = pwd;
    } else {
      if (pwd.contains('lib')) {
        final paths = filePath.split('lib');
        projectRoot = paths[paths.length - 2];
      } else {
        throwToolExit('必须在flutter module项目下执行，或者指定--file');
      }
    }

    log.info('project root' + projectRoot);

    final items =
        Directory(pwd.contains('lib') ? pwd : path.join(projectRoot, 'lib'))
            .listSync(followLinks: false, recursive: true)
            .where((f) => f is File && f.path.endsWith('.dart'))
            .map((e) => e as File);

    final files = items.toList(growable: false);
    files.sort((fl, fr) => fl.path.compareTo(fr.path));

    for (final item in files) {
      process(item.readAsStringSync(), projectRoot,
          item.path.split('lib/').last, outputs(projectRoot));
    }

    return 'generated common(s)&route(s) for $projectRoot';
  }

  Map<String, String> outputs(String root) {
    final configPath = path.join(root, '.faraday.json');
    final config = JSON.parse(File(configPath).readAsStringSync());

    final ios_common = config['ios-common'].string;
    final ios_route = config['ios-route'].string;
    final android_common = config['android-common'].string;
    final android_route = config['android-route'].string;

    return <String, String>{
      if (ios_common != null) 'ios-common': ios_common,
      if (ios_route != null) 'ios-route': ios_route,
      if (android_common != null) 'android-common': android_common,
      if (android_route != null) 'android-route': android_route,
      'dart-route': path.join(root, 'lib/src/routes.dart')
    };
  }
}
