import 'dart:convert';
import 'dart:io';

import 'package:faraday/src/utils/exception.dart';

import '../services/parse_string.dart';
import 'command.dart';

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

    final offset = int.tryParse(offsetS) ?? -1;
    if (offset <= 0) return '';

    final sc = stringArg('source-code');
    final sourceCode =
        sc != null ? Utf8Decoder().convert(base64Decode(sc)) : '';
    if (sourceCode.isEmpty) return '';

    List<ParseResult> parseCode() {
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
          'Invalid source code with offset. $sourceCode \noffset:$offset');
    }

    final r = parseCode();

    if (r.isEmpty) return '';

    final pr = r.first;
    if (pr.commons == null || pr.commons!.isEmpty) return '';

    final method = pr.commons!.first;
    final arguments = (method.arguments?.isNotEmpty ?? false)
        ? ", {${method.arguments!.map((p) => p.dartStyle).join(', ')}}"
        : '';
    final rt = method.returnType.toString();
    final arg = "('${pr.className}#${method.name}'$arguments)";

    if (rt.contains('List')) {
      return 'FaradayCommon.invokeListMethod$arg';
    } else if (rt.contains('Map')) {
      return 'FaradayCommon.invokeMapMethod$arg';
    }

    return 'FaradayCommon.invokeMethod$arg';
  }
}

extension ParameterDart on Parameter {
  String get dartStyle =>
      isRequired ? "'$name': $name" : "if ($name != null) '$name': $name";
}
