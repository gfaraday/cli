import 'package:g_json/g_json.dart';
import 'package:recase/recase.dart';

enum SwiftCodeType { protocol, enmu, impl, enumPage }

List<String> generateSwift(List<JSON> methods, SwiftCodeType type,
    {String? identifier}) {
  final result = <String>[];
  for (final method in methods) {
    final name = method['name'].stringValue;

    final args = method['arguments']
        .listValue
        .map((j) =>
            "_ ${j['name'].stringValue}: ${j['type'].stringValue.replaceDartTypeToSwift}${j['isRequired'].booleanValue ? '' : '?'}")
        .toList();

    switch (type) {
      case SwiftCodeType.protocol:
        final r = method['return'].stringValue;

        String returnType;

        if (r == 'null' || r == 'dynamic') {
          returnType = 'Any?';
        } else if (r == 'void') {
          returnType = '';
        } else if (r.startsWith('Future<') && r.endsWith('>')) {
          final realType = r.substring(7, r.length - 1);
          if (realType.startsWith('Map')) {
            returnType = '[String: Any]?';
          } else if (realType.startsWith('List')) {
            returnType = '[Any]?';
          } else {
            returnType = realType;
          }
        } else {
          returnType = '';
        }

        if (returnType.isNotEmpty) {
          args.add(
              '_ completion: @escaping (_ result: ${returnType.replaceDartTypeToSwift}) -> Void');
        }

        result.add('\n    ' +
            (method['comments'].string?.replaceAll('\n', '\n    ') ??
                '// NO COMMENTS') +
            '\n    func $name(${args.join(', ')})');
        break;
      case SwiftCodeType.enmu:
        var r = "    case $name${args.isEmpty ? '' : "(${args.join(', ')})"}";
        final comments =
            method['comments'].string?.replaceAll('\n', '\n    ') ?? '';
        if (comments.isNotEmpty) {
          r = '    $comments\n$r';
        }
        result.add(r);
        break;
      case SwiftCodeType.enumPage:
        final arguments = method['arguments'].listValue;
        if (arguments.isEmpty) {
          result.add('''            case .$name:
                return ("${name.snakeCase}", nil)''');
        } else {
          result.add(
              '''            case let .$name(${arguments.map((dynamic a) => a.name).join(', ')}):
                return ("${name.snakeCase}", [${arguments.map((dynamic a) => '"${a.name}": ${a.name}').join(', ')}])''');
        }
        break;
      case SwiftCodeType.impl:
        final lets =
            method['arguments'].listValue.map((j) => j.getter()).join('\n');

        final hasReturnType = method['return'].stringValue != 'void';

        final args = method['arguments'].listValue.map((j) => j.name).toList();

        if (hasReturnType) args.add('completion');

        final invokeStr = "$name(${args.join(', ')})";

        result.add('''        if (name == "$identifier#$name") {
$lets
            // invoke $name
            $invokeStr
            ${hasReturnType ? '' : 'completion(nil)'}
            return true
        }''');
        break;
    }
  }
  return result;
}

extension JSONArguments on JSON {
  String get name => this['name'].stringValue;
  String get argumentType => this['type'].stringValue.replaceDartTypeToSwift;
  bool get isRequired => this['isRequired'].booleanValue;

  String getter() {
    final let = 'let $name = args?["$name"] as? $argumentType';
    if (isRequired) {
      if (argumentType == 'dynamic') {
        return '''
            guard let $name = args?["$name"] else {
                fatalError("Invalid argument: $name")
            }''';
      }
      return '''
            guard $let else {
                fatalError("Invalid argument: $name")
            }''';
    }
    return '''
            $let ''';
  }
}

extension StringFaraday on String {
  String get replaceDartTypeToSwift => replaceAll('List', 'Array')
      .replaceAll('Map', 'Dictionary')
      .replaceAll('bool', 'Bool')
      .replaceAll('int', 'Int')
      .replaceAll('float', 'Float')
      .replaceAll('double', 'Double')
      .replaceAll('num', 'Double')
      .replaceAll('dynamic', 'Any')
      .replaceAll('null', 'Any?');
}
