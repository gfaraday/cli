import 'package:g_json/g_json.dart';
import 'package:recase/recase.dart';

List<String> generateDart(JSON method,
    {String identifier, bool flutterOnly = true}) {
  final result = <String>[];
  if (!flutterOnly) {
    result.add('    /// no native routed generated');
  }
  result.add("    case '${identifier.snakeCase}':");
  if (method == null) {
    result.add('      return $identifier();');
  } else {
    final args = method['arguments'].listValue.map((e) =>
        e['isSimple'].booleanValue
            ? "args.${e['name'].stringValue}"
            : "${e['name'].stringValue}: args.${e['name'].stringValue}");
    final argsString = '.faraday(${args.join(', ')});';
    result.add('      return $identifier$argsString');
  }

  return result;
}
