import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:faraday/src/commands/command.dart';
import 'package:faraday/src/services/parse_string.dart';
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

    final result = <String>[];

    r.forEach((clazz, info) {
      final common = info['common'];
      if (common != null && common.isNotEmpty) {
        result.addAll(common.map((m) =>
            "FaradayCommon.invokeMethod('$clazz#${m.name}', {${m.arguments.map((p) => p.dartStyle).join(', ')}})"));
      }
      final route = info['route'];
      if (route != null && route.isNotEmpty) {
        result.addAll(route.map((m) {
          final arguments = m.arguments.isNotEmpty
              ? ", arguments: {${m.arguments.map((p) => p.dartStyle).join(', ')}}"
              : null;
          return "Navigator.of(context).pushNamed('${m.name.name.snakeCase}'${arguments ?? ''})";
        }));
      }
    });
    if (result.isEmpty) return '';
    return result.first;
  }
}

extension ParameterDart on Parameter {
  String get dartStyle =>
      isRequired ? "'$name': $name" : "if ($name != null) '$name': $name";
}
