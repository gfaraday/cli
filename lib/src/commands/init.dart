import 'dart:io';

import 'package:g_json/g_json.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import '../commands/command.dart';
import '../template/template.dart' as t;
import '../utils/exception.dart';

class InitCommand extends FaradayCommand {
  InitCommand() : super() {
    argParser.addOption('project', abbr: 'p');
  }

  @override
  String get description => 'init faraday project';

  @override
  String get name => 'init';

  @override
  String run() {
    final welcome = '''
   ___                   _             
  / __\\_ _ _ __ __ _  __| | __ _ _   _ 
 / _\\/ _` | '__/ _` |/ _` |/ _` | | | |
/ / | (_| | | | (_| | (_| | (_| | |_| |
\\/   \\__,_|_|  \\__,_|\\__,_|\\__,_|\\__, |
                                 |___/       
    ''';
    log.info(welcome);

    Logger.root.level = Level.ALL;

    var projectPath = stringArg('project');
    if (projectPath == null || projectPath.isEmpty) {
      projectPath = path.current;
      // 确定当前目录是一个 flutter module 目录，否则报错
      final metadataFile = File(path.join(projectPath, '.metadata'));
      if (!metadataFile.existsSync() ||
          !metadataFile.readAsStringSync().contains('project_type: module')) {
        throwToolExit('Only support flutter module project.');
      }
    }

    log.fine('Init debug message to lib/src/debug/debug.dart');
    final debugFile = File(path.join(projectPath, 'lib/src/debug/debug.dart'))
      ..createSync(recursive: true);

    debugFile.writeAsStringSync(t.d_debug(), mode: FileMode.write);

    log.fine('Init route to lib/src/routes.dart');
    final routeFile = File(path.join(projectPath, 'lib/src/routes.dart'))
      ..createSync(recursive: true);
    routeFile.writeAsStringSync(t.d_route(), mode: FileMode.write);

    final configPath = path.join(projectPath, '.faraday.json');
    final config = JSON.parse(File(configPath).readAsStringSync());

    final ios_common = config['ios-common'].string;
    final ios_route = config['ios-route'].string;
    final android_common = config['android-common'].string;
    final android_route = config['android-route'].string;

    final outputs = <String, String>{
      if (ios_common != null) ios_common: t.s_common,
      if (ios_route != null) ios_route: t.s_route,
      if (android_common != null) android_common: t.k_common,
      if (android_route != null) android_route: t.k_route,
    };

    if (outputs.isNotEmpty) {
      outputs.forEach((fp, c) {
        // android 需要吧package 信息拿出来
        if (c.contains('fun ')) {
          final ktfile = File(fp).readAsStringSync().split('\n');
          if (ktfile.isEmpty || !ktfile.first.startsWith('package ')) {
            throwToolExit('Kotlin file must starts with `package `');
          }
          final package = ktfile.first;
          c = package + '\n\n' + c;
        }
        File(fp).writeAsStringSync(c, mode: FileMode.write);
      });
      return outputs.keys.join('\n');
    }

    return '';
  }
}
