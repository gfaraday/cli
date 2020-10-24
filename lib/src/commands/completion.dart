import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'command.dart';
import '../services/parse_string.dart';
import 'package:faraday/src/utils/exception.dart';
import 'package:recase/recase.dart';

class CompletionCommand extends FaradayCommand {
  CompletionCommand() : super() {
    argParser.addOption('offset', help: 'valid zero-based offset');
    argParser.addOption('source-code', abbr: 's', help: 'dart source code');
  }

  @override
  String get description => '自动为 @common 和 @entry 生成方法实现';

  @override
  String get name => 'completion';

  // 返回自动补全的字符串数组
  @override
  String run() {
    final offsetS = stringArg('offset');
    if (offsetS == null || offsetS.isEmpty) return '';

    final offset = num.parse(offsetS, (_) => -1).toInt();
    if (offset <= 0) return '';

    final sourceCode =
        Utf8Decoder().convert(base64Decode(stringArg('source-code')));
    if (sourceCode.isEmpty) return '';

    Map<String, Map<String, List<MethodDeclaration>>> parseCode() {
      final lineSplitter = LineSplitter();
      final lines = lineSplitter.convert(sourceCode);

      for (var i = 0; i < lines.length; i++) {
        // windows: \r\n other: \n
        final length =
            lines.sublist(0, i + 1).fold<int>(0, (r, l) => r + l.length) +
                i * (Platform.isWindows ? 2 : 1);
        if (length >= offset) {
          final line = lines.removeAt(i);
          log.info('remove line => ${i + 1}: "$line"');
          final lineOffset = line.length - (length - offset);
          return parse(
              sourceCode: lines.join('\n'),
              offset: offset - lineOffset - (Platform.isWindows ? i : 0));
        }
      }
      throw ToolExit(
          'Invlid source code with offset. $sourceCode \noffset:$offset');
    }

    final r = parseCode();

    if (r.isEmpty) return '';

    final clazz = r.keys.first;
    final common = r.values.first['common'];
    if (common != null && common.isNotEmpty) {
      final method = common.first;
      final arguments = method.arguments.isNotEmpty
          ? ", {${method.arguments.map((p) => p.dartStyle).join(', ')}}"
          : '';
      return "FaradayCommon.invokeMethod('$clazz#${method.name}'$arguments)";
    }

    final route = r.values.first['route'];
    if (route != null && route.isNotEmpty) {
      final method = route.first;
      final arguments = method.arguments.isNotEmpty
          ? ", arguments: {${method.arguments.map((p) => p.dartStyle).join(', ')}}"
          : null;
      return "Navigator.of(context).pushNamed('${method.name.name.snakeCase}'${arguments ?? ''})";
    }

    return '';
  }
}

extension ParameterDart on Parameter {
  String get dartStyle =>
      isRequired ? "'$name': $name" : "if ($name != null) '$name': $name";
}
