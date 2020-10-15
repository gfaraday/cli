import 'package:g_json/g_json.dart';
import 'package:recase/recase.dart';

enum KotlinCodeType { interface, sealed, impl }

List<String> generateKotlin(List<JSON> methods, KotlinCodeType type,
    {String identifier}) {
  final result = <String>[];
  for (final method in methods) {
    final name = method['name'].stringValue;
    final args = method['arguments'].listValue;

    switch (type) {
      case KotlinCodeType.interface:
        var comments =
            (method['comments'].string?.replaceAll('\n', '\n    ') ?? '');
        if (comments.isNotEmpty) comments = '    ' + comments + '\n';
        final parameters = args
            .map((dynamic j) =>
                '${j.name}: ${j['type'].stringValue}${j.isRequired ? '' : '?'}')
            .join(', ');
        final r = method['return'].stringValue;

        String returnType;

        if (r == 'null' || r == 'dynamic') {
          returnType = ': Any?';
        } else if (r == 'void') {
          returnType = '';
        } else if (r.startsWith('Future<') && r.endsWith('>')) {
          final realType = r.substring(7, r.length - 1);
          if (realType.startsWith('Map')) {
            returnType = ': Map<String, *>';
          } else if (realType.startsWith('List')) {
            returnType = ': List<*>';
          } else {
            returnType = ': $realType';
          }
        }

        result.add(comments +
            '    fun $name($parameters)$returnType'.replaceDartTypeToKotlin);
        break;
      case KotlinCodeType.sealed:
        final map =
            args.map((dynamic j) => '"${j.name}" to ${j.name}').join(', ');
        final properties = args
            .map((dynamic j) => 'val ${j.name}: ${j['type'].stringValue}')
            .join(', ');
        final parameters = map.isEmpty ? 'null' : 'hashMapOf($map)';
        var comments =
            (method['comments'].string?.replaceAll('\n', '\n    ') ?? '');
        if (comments.isNotEmpty) comments = '    ' + comments + '\n';
        if (properties.isEmpty) {
          result.add(comments +
              '    object ${name.pascalCase}: FlutterRoute("${name.snakeCase}")');
        } else {
          result.add(comments +
              '    data class ${name.pascalCase}($properties): FlutterRoute("${name.snakeCase}", $parameters)'
                  .replaceDartTypeToKotlin);
        }
        break;
      case KotlinCodeType.impl:
        final vals = method['arguments']
            .listValue
            .map((dynamic j) =>
                'val ${j.name} = args["${j.name}"] as? ${j["type"].stringValue}' +
                (j.isRequired
                    ? ' ?: throw IllegalArgumentException("Invalid argument: ${j.name}")'
                    : ''))
            .join('\n            ');

        final invokeStr =
            '$name(${method['arguments'].listValue.map((dynamic j) => j.name).join(', ')})';
        final r = method['return'].stringValue == 'void'
            ? 'result.success(rnrull)'
            : 'result.success($invokeStr)';
        result.add('''        if (call.method == "$identifier#$name") {
            $vals
            // invoke $name
            ${method['return'].stringValue == "void" ? invokeStr : '// retrunType: ${method['return']}'}
            $r
            return true
        }'''
            .replaceDartTypeToKotlin);
        break;
    }
  }
  return result;
}

extension StringFaraday on String {
  String get replaceDartTypeToKotlin => replaceAll('bool', 'Boolean')
      .replaceAll('int', 'Int')
      .replaceAll('float', 'Float')
      .replaceAll('double', 'Double')
      .replaceAll('num', 'Double')
      .replaceAll('dynamic', 'Any')
      .replaceAll('null', 'Any?')
      .replaceAll('rnrull', 'null');
}
