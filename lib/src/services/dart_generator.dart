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
  /// JSON ({"name":"isOpenXianyu","type":"bool","isRequired":false,"isSimple":false})
  /// 当参数是 {bool isOpen = false} 这种情况时， isRequired":false，但需要 booleanValue 因此用isRequired是不准确的。
  String arg() {
    // final t = this['type'].stringValue;
    // final isRequired = this['isRequired'].booleanValue;
    // final realType = t.startsWith('int')
    //     ? (isRequired ? 'integerValue' : 'integer')
    //     : t.startsWith('bool')
    //         ? (isRequired ? 'booleanValue' : 'boolean')
    //         : t.startsWith('double')
    //             ? (isRequired ? 'ddoubleValue' : 'ddouble')
    //             : t.startsWith('String')
    //                 ? (isRequired ? 'stringValue' : 'string')
    //                 : t.startsWith('num')
    //                     ? (isRequired ? 'numberValue' : 'number')
    //                     : 'unsupported $t';
    // return 'args["${this["name"].stringValue}"].$realType';

    final t = realType();
    final suffix = t.isEmpty ? '' : '.$t';
    return 'args["${this["name"].stringValue}"]$suffix';
  }

  String realType() {
    final t = this['type'].stringValue;

    switch (t) {
      case 'int':
        return 'integerValue';
      case 'int?':
        return 'integer';
      case 'bool':
        return 'booleanValue';
      case 'bool?':
        return 'boolean';
      case 'double':
        return 'ddoubleValue';
      case 'double?':
        return 'ddouble';
      case 'String':
        return 'stringValue';
      case 'String?':
        return 'string';
      case 'num':
        return 'numberValue';
      case 'num?':
        return 'number';
      case 'JSON':
      case 'JSON?':
        return '';
      case 'List<dynamic>':
        return 'listObject ?? []';
      case 'List<dynamic>?':
        return 'listObject';
      case 'List<String>':
        return 'listValue.map((e) => e.stringValue).toList()';
      case 'List<String>?':
        return 'list?.map((e) => e.stringValue).toList()';

      default:
        return 'unsupported $t';
    }
  }
}
