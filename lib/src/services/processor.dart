import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:faraday/src/services/dart_generator.dart';
import 'package:g_json/g_json.dart';
import 'package:recase/recase.dart';

import '../utils/exception.dart';
import 'kotlin_generator.dart';
import 'parse_string.dart';
import 'swift_generator.dart';

void process(String sourceCode, String projectRoot, String identifier,
    Map<String, String> outputs) {
  void _flushSwift(String clazz,
      {List<JSON> commonMethods, List<JSON> routeMethods}) {
    final swiftCommonFile = outputs['ios-common'];
    if (swiftCommonFile != null && commonMethods != null) {
      // protocol
      final protocols = generateSwift(
          commonMethods ?? [], SwiftCodeType.protocol,
          identifier: clazz);
      flush(protocols, 'protocol', clazz, swiftCommonFile);

      // impl
      final impls = generateSwift(commonMethods ?? [], SwiftCodeType.impl,
          identifier: clazz);
      flush(impls, 'impl', clazz, swiftCommonFile, indentation: '        ');
    }

    final swiftRouteFile = outputs['ios-route'];
    if (swiftRouteFile != null) {
      // enum
      final enums = generateSwift(routeMethods ?? [], SwiftCodeType.enmu);
      flush(enums, 'enum', clazz, swiftRouteFile);

      final enumPages =
          generateSwift(routeMethods ?? [], SwiftCodeType.enumPage);
      flush(enumPages, 'enum_page', clazz, swiftRouteFile,
          indentation: '            ');
    }
  }

  void _flushKotlin(String clazz,
      {List<JSON> commonMethods, List<JSON> routeMethods}) {
    final kotlinCommonFile = outputs['android-common'];
    if (kotlinCommonFile != null) {
      final interface = generateKotlin(
          commonMethods ?? [], KotlinCodeType.interface,
          identifier: clazz);
      flush(interface, 'interface', clazz, kotlinCommonFile);

      final impls = generateKotlin(commonMethods ?? [], KotlinCodeType.impl,
          identifier: clazz);
      flush(impls, 'impl', clazz, kotlinCommonFile);
    }

    final kotlinRouteFile = outputs['android-route'];
    if (kotlinRouteFile != null) {
      // sealed class
      final sealeds = generateKotlin(routeMethods ?? [], KotlinCodeType.sealed,
          identifier: clazz);
      flush(sealeds, 'sealed', clazz, kotlinRouteFile, indentation: '');
    }
  }

  void _flushDart(List<ParseResult> results) {
    final dartRouteFile = outputs['dart-route'];
    if (dartRouteFile != null) {
      for (final r in results) {
        final contents = generateDart(
          r.entry is MethodDeclaration ? JSON(r.entry.info) : null,
          identifier: r.className,
          flutterOnly: !r.needGenerateNativeRoute,
        );
        flush(contents, 'route', r.className, dartRouteFile,
            indentation: '    ');
      }
    }
  }

  final prs = parse(sourceCode: sourceCode);

  final routes = prs.where((p) => p.entry != null);
  if (routes.length != Set.from(routes.map((r) => r.className)).length) {
    throwToolExit('不能注册名称相同的entry $routes');
  }

  // 先生成 dart 路由
  _flushDart(routes.toList(growable: false));

  // 处理 swift & kotlin
  for (final pr in prs) {
    final commons =
        pr.commons?.map((e) => JSON(e.info))?.toList(growable: false) ?? [];
    final routes = <JSON>[];
    if (pr.entry != null && pr.needGenerateNativeRoute) {
      final info = JSON(pr.entry.info);
      info['name'] = pr.className.camelCase;
      routes.add(info);
    }
    _flushSwift(pr.className,
        commonMethods: List.from(commons), routeMethods: routes);
    _flushKotlin(pr.className,
        commonMethods: List.from(commons), routeMethods: routes);
  }
}

void flush(
    List<String> contents, String prefix, String token, String outputFilePath,
    {String indentation = '    '}) {
  final file = File(outputFilePath);

  final lines = LineSplitter.split(file.readAsStringSync()).toList();

  final beginToken = '$indentation// ---> $prefix $token';
  final endToken = '$indentation// <--- $prefix $token';

  final begin = lines.indexWhere((l) => l.endsWith(beginToken));
  if (begin != -1) {
    final end = lines.indexWhere((l) => l.endsWith(endToken));
    if (end != -1 && end > begin) lines.removeRange(begin, end + 1);
  }

  if (contents.isNotEmpty) {
    final insert = lines.indexWhere((l) => l.endsWith(prefix));
    if (insert == -1) {
      throwToolExit('insert point not found [$prefix]');
    }
    contents.insert(0, beginToken);
    contents.add(endToken);
    lines.insertAll(insert + 1, contents);
  }

  file.writeAsStringSync(lines.join('\n'));
}
