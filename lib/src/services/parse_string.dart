import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:faraday/src/utils/exception.dart';

const supportedAnnotations = ['common', 'flutterEntry', 'entry'];

const supportedDartType = [
  'String',
  'bool',
  'void',
  'num',
  'int',
  'double',
  'float',
];

bool isSupportedType(String type) {
  // 暂时支持参数重包含 dynamic类型， 请自行确保 dynamic 可以序列化为json
  return supportedDartType.any((t) =>
      type.contains(t) ||
      type.contains('Future<List') || // List<dynamic>
      type.contains('List<dynamic>') ||
      type.contains('Future<Map')); // Map<dynamic>
}

class ParseResult {
  final String className;
  bool needGenerateNativeRoute;
  MethodDeclaration entry;
  List<MethodDeclaration> commons;

  ParseResult(
    this.className, {
    this.needGenerateNativeRoute,
    this.commons,
  });
}

List<ParseResult> parse({String sourceCode, int offset}) {
  final prs = <ParseResult>[];

  final unit = parseString(content: sourceCode).unit;

  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      final clazzName = declaration.name.name;
      final annotations = declaration.metadata.map((e) => e.name.name);

      final pr = ParseResult(clazzName);

      for (final annotation in annotations) {
        switch (annotation) {
          case 'entry':
          case 'flutterEntry':
            final methods = declaration.members
                .whereType<MethodDeclaration>()
                .where((method) =>
                    method.isStatic &&
                    method.name.name == 'faraday' &&
                    method.returnType.toSource().startsWith('Route'));
            pr.needGenerateNativeRoute = annotation == 'entry';
            if (methods.isEmpty) {
              throwToolExit('$clazzName route function not found');
            }
            pr.entry = methods.first;

            break;
          case 'common':
            final commons = <MethodDeclaration>[];
            // 遍历处所有符合条件的method
            for (final method
                in declaration.members.whereType<MethodDeclaration>()) {
              // 如果是想自动完成，那么这里需要判断，以免不必要的运算
              if (offset != null &&
                  (offset < method.offset || offset > method.end)) {
                continue;
              }

              // 如果方法标记为 ignore 那直接跳过
              if (method.metadata
                  .any((element) => element.name.name == 'ignore')) {
                continue;
              }

              // 静态方法
              if (method.isStatic) {
                // 不能以下划线开头
                if (method.name.name.startsWith('_')) {
                  continue;
                }

                // 必须是可以序列化成json的返回值
                final returnTypeSource = method.returnType.toSource();
                if (!isSupportedType(returnTypeSource)) {
                  if (method.name.name != 'faraday') {
                    print(
                        '${method.name} return type [$returnTypeSource] not support.');
                  }
                  continue;
                }

                // 必须是可以序列化成json的参数
                final parameters = method.arguments;

                if (parameters.any((p) => !isSupportedType(p.type))) {
                  print('${method.name} parameter [$parameters] not support.');
                  continue;
                }

                // 如果这个method满足设定上述约定，那么认为他是一个`common`
                commons.add(method);
                if (offset != null) break;
              }
            }

            pr.commons = commons;
            break;
          default:
            break;
        }
      }
      if (pr.entry != null || (pr.commons != null && pr.commons.isNotEmpty)) {
        prs.add(pr);
      }
    }
  }
  return prs;
}

class Parameter {
  final bool isRequired;
  final String name;
  final String type;
  final bool isSimple;

  const Parameter(this.name, this.type, this.isRequired, this.isSimple);

  factory Parameter.from(FormalParameter p, {bool isSimple = true}) {
    if (p is SimpleFormalParameter) {
      return Parameter(
          p.identifier.name,
          p.type.toString(),
          p.isRequired ||
              p.metadata.indexWhere((a) => a.name.name == 'required') != -1,
          isSimple);
    }
    if (p is DefaultFormalParameter) {
      return Parameter.from(p.parameter, isSimple: false);
    }

    // 这种是构造方法中的参数
    // if (p is FieldFormalParameter) {
    //   // 需要拿到type
    //   final clazz = p.parent.parent.parent;
    //   if (clazz is ClassDeclaration) {
    //     // 读取所有参数
    //     final parameters = clazz.members
    //         .whereType<FieldDeclaration>()
    //         .map((e) => e.toSource());
    //     final name = p.identifier.name;
    //     final t = parameters
    //         .firstWhere((element) => element.endsWith('$name;'))
    //         .split(' ');
    //     final type = t.length > 1 ? t[t.length - 2] : 'dynamic';
    //     return Parameter(name, type, p.isRequired, iss);
    //   }
    // }
    throw 'Unsupport parameter: $p';
  }

  Map<String, dynamic> get info => {
        'name': name,
        'type': type,
        'isRequired': isRequired,
        'isSimple': isSimple
      };
  String get swift => '$name: $type${isRequired ? '' : '?'}';

  @override
  String toString() {
    return swift;
  }
}

extension FaradayAnnotatedNode on AnnotatedNode {
  String get comments =>
      documentationComment?.childEntities?.map((s) => s.toString())?.join('\n');
}

extension FaradayMethodDeclaration on MethodDeclaration {
  String get funcName => name.name;

  List<Parameter> get arguments =>
      parameters.parameters.map((p) => Parameter.from(p)).toList();

  Map<String, dynamic> get info => {
        'comments': comments,
        'name': funcName,
        'arguments': arguments.map((arg) => arg.info).toList(),
        'return': returnType.toString()
      };
}

extension FaradayConstructorDeclaration on ConstructorDeclaration {
  String get funcName => name?.name;

  List<Parameter> get arguments =>
      parameters.parameters.map((p) => Parameter.from(p)).toList();

  Map<String, dynamic> get info => {
        'comments': comments,
        'name': funcName,
        'arguments': arguments.map((arg) => arg.info).toList(),
      };
}
