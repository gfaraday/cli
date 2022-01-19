import 'package:g_json/g_json.dart';
import 'package:recase/recase.dart';

List<String> generateDart(JSON method,
    {String identifier, bool flutterOnly = true}) {
  final result = <String>[];
  if (flutterOnly) {
    result.add('    /// no native routed generated');
  }
  result.add("    case '${identifier.snakeCase}':");
  if (method == null) {
    result.add('      return $identifier();');
  } else {
    final args = method['arguments'].listValue.map((e) =>
        e['isSimple'].booleanValue
            ? e.arg()
            : "${e['name'].stringValue}: ${e.arg()}");

    final argsString = '.faraday(${args.join(', ')});';
    result.add('      return $identifier$argsString');
  }

  return result;
}

extension ArgumentsJSON on JSON {
  String arg() {
    final t = this['type'].stringValue;
    final isRequired = this['isRequired'].booleanValue;
    final realType = t == 'int'
        ? (isRequired ? 'integer' : 'integerValue')
        : t == 'bool'
            ? (isRequired ? 'boolean' : 'booleanValue')
            : t == 'double'
                ? (isRequired ? 'ddouble' : 'ddoubleValue')
                : t == 'string'
                    ? (isRequired ? 'string' : 'stringValue')
                    : 'unsupported $t';
    return 'arg["${this["name"].stringValue}"].$realType';
  }
}
