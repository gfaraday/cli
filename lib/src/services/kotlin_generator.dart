import 'package:g_json/g_json.dart';
import 'package:recase/recase.dart';

enum KotlinCodeType { interface, sealed, impl }

String replaceDartToKotlin(String source) {
  return source
    ..replaceAll('bool', 'Boolean')
        .replaceAll('int', 'Int')
        .replaceAll('float', 'Float')
        .replaceAll('double', 'Double')
        .replaceAll('num', 'Double')
        .replaceAll('dynamic', 'Any')
        .replaceAll('null', 'Any?');
}

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
                '${j.name}: ${replaceDartToKotlin(j['type'].stringValue)}${j.isRequired ? '' : '?'}')
            .toList();
        final r = method['return'].stringValue;

        String returnType;

        if (r == 'null' || r == 'dynamic') {
          returnType = 'Any?';
        } else if (r == 'void') {
          returnType = '';
        } else if (r.startsWith('Future<') && r.endsWith('>')) {
          final realType = r.substring(7, r.length - 1);
          if (realType.startsWith('Map')) {
            returnType = 'Map<String, *>';
          } else if (realType.startsWith('List')) {
            returnType = 'List<*>';
          } else {
            returnType = realType;
          }
        }

        if (returnType.isNotEmpty) {
          parameters
              .add('callback: (${replaceDartToKotlin(returnType)}) -> Unit');
        }

        result.add(comments + "    fun $name(${parameters.join(', ')})");
        break;
      case KotlinCodeType.sealed:
        final map =
            args.map((dynamic j) => '"${j.name}" to ${j.name}').join(', ');
        final properties = args
            .map((dynamic j) =>
                'val ${j.name}: ${replaceDartToKotlin(j['type'].stringValue)}')
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
              '    data class ${name.pascalCase}($properties): FlutterRoute("${name.snakeCase}", $parameters)');
        }
        break;
      case KotlinCodeType.impl:
        final vals = method['arguments']
            .listValue
            .map((dynamic j) =>
                'val ${j.name} = args["${j.name}"] as? ${replaceDartToKotlin(j["type"].stringValue)}' +
                (j.isRequired
                    ? ' ?: throw IllegalArgumentException("Invalid argument: ${j.name}")'
                    : ''))
            .join('\n            ');

        var invokeStr =
            '$name(${method['arguments'].listValue.map((dynamic j) => j.name).join(', ')})';
        final hasReturnType = method['return'].stringValue != 'void';
        if (hasReturnType) {
          if (vals.isEmpty) {
            invokeStr = invokeStr.replaceFirst('()', '');
          }
          invokeStr = '''$invokeStr {
               result.success(it)
            }''';
        } else {
          invokeStr += '\n            result.success(null)';
        }

        if (vals.isNotEmpty) {
          invokeStr = vals + '\n            $invokeStr';
        }

        result.add('''        if (call.method == "$identifier#$name") {
            $invokeStr
            return true
        }''');
        break;
    }
  }
  return result;
}
