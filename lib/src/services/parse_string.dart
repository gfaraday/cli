import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../../faraday.dart';
import '../utils/exception.dart';

// const supportedAnnotations = ['common', 'flutterEntry', 'entry'];

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
  MethodDeclaration? entry;
  List<MethodDeclaration>? commons;

  ParseResult(
    this.className, {
    this.needGenerateNativeRoute = false,
    this.commons,
    this.entry,
  });
}

List<ParseResult> parse({required String sourceCode, int? offset}) {
  final prs = <ParseResult>[];

  final unit = parseString(content: sourceCode).unit;

  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration) {
      final className = declaration.namePart.typeName.lexeme;
      final annotations = declaration.metadata.map((e) => e.name.name);

      final pr = ParseResult(className);

      for (final annotation in annotations) {
        switch (annotation) {
          case 'entry':
          case 'flutterEntry':
            final methods = declaration.body.members
                .whereType<MethodDeclaration>()
                .where((method) =>
                    method.isStatic &&
                    method.name.name == 'faraday' &&
                    method.returnType != null &&
                    method.returnType!.toSource().startsWith('Route'));
            pr.needGenerateNativeRoute = annotation == 'entry';
            if (methods.isEmpty) {
              throwToolExit('$className route function not found');
            }
            pr.entry = methods.first;

            break;
          case 'common':
            final commons = <MethodDeclaration>[];
            // 遍历处所有符合条件的method
            for (final method
                in declaration.body.members.whereType<MethodDeclaration>()) {
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
                final returnTypeSource = method.returnType?.toSource();
                if (returnTypeSource != null &&
                    !isSupportedType(returnTypeSource)) {
                  if (method.name.name != 'faraday') {
                    log.severe(
                        '${method.name} return type [$returnTypeSource] not support.');
                  }
                  continue;
                }

                // 必须是可以序列化成json的参数
                final parameters = method.arguments;

                if (parameters != null &&
                    parameters.any((p) => !isSupportedType(p.type))) {
                  log.severe(
                      '${method.name} parameter [$parameters] not support.');
                  continue;
                }

                final channelName = '${pr.className}#${method.name.toString()}';
                // analyzer 12+ 的 toSource() 不再包含注释，通道名通常写在注释里，
                // 因此用源码切片（保留注释）来判断。
                final bodySource =
                    sourceCode.substring(method.body.offset, method.body.end);
                if (!bodySource.contains(channelName)) {
                  log.severe('''
                  please fix this error: This method not contains channel name "$channelName", method:
                  ============>
                  ${method.toSource()}
                  <============\n
                  ''');
                } else {
                  // 如果这个method满足设定上述约定，那么认为他是一个`common`
                  commons.add(method);
                  _checkInvokeMethodArguments(method, channelName);
                }
                if (offset != null) break;
              }
            }

            pr.commons = commons;
            break;
          default:
            break;
        }
      }
      if (pr.entry != null || (pr.commons != null && pr.commons!.isNotEmpty)) {
        prs.add(pr);
      }
    }
  }
  return prs;
}

class Parameter {
  final bool isRequired;
  final String? name;
  final String type;
  final bool isSimple;

  const Parameter(this.name, this.type, this.isRequired, this.isSimple);

  factory Parameter.from(FormalParameter p, {bool isSimple = true}) {
    if (p is SimpleFormalParameter) {
      return Parameter(
          p.name?.name,
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
    throw 'Nonsupport parameter: $p';
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
  String? get comments =>
      documentationComment?.childEntities.map((s) => s.toString()).join('\n');
}

extension FaradayMethodDeclaration on MethodDeclaration {
  String get funcName => name.name;

  List<Parameter>? get arguments =>
      parameters?.parameters.map((p) => Parameter.from(p)).toList();

  Map<String, dynamic> get info => {
        'comments': comments,
        'name': funcName,
        'arguments': arguments?.map((arg) => arg.info).toList(),
        'return': returnType.toString()
      };
}

extension FaradayConstructorDeclaration on ConstructorDeclaration {
  String? get funcName => name?.name;

  List<Parameter> get arguments =>
      parameters.parameters.map((p) => Parameter.from(p)).toList();

  Map<String, dynamic> get info => {
        'comments': comments,
        'name': funcName,
        'arguments': arguments.map((arg) => arg.info).toList(),
      };
}

extension Value on Token {
  String get name => lexeme;
}

/// 校验 invokeMethod 实际传参与方法签名参数是否一致，不一致时打印 warning：
/// - map 传了、签名没声明 → 生成的原生代码不会接收该参数
/// - 签名声明了、map 没传 → 原生端按签名生成，运行时取不到该参数
void _checkInvokeMethodArguments(
    MethodDeclaration method, String channelName) {
  final visitor = _InvokeMethodVisitor(channelName);
  method.body.accept(visitor);
  final map = visitor.argumentsMap;
  // 传参不是 map 字面量（如先赋值给变量再传入），无法静态校验，跳过
  if (map == null) return;

  final paramNames = method.parameters?.parameters
          .map((p) => p.name?.lexeme)
          .whereType<String>()
          .toSet() ??
      <String>{};

  // 仅提取字符串字面量 key；if 条件项、...展开符等无法静态确定，跳过
  final mapKeys = map.elements
      .whereType<MapLiteralEntry>()
      .map((e) => e.key)
      .whereType<SimpleStringLiteral>()
      .map((k) => k.value)
      .toSet();

  for (final key in mapKeys.difference(paramNames)) {
    log.warning('$channelName: invokeMethod 传了 "$key"，但方法签名未声明该参数，'
        '生成的原生代码不会接收它，请移除该传参或将其加入方法签名。');
  }
  for (final name in paramNames.difference(mapKeys)) {
    log.warning('$channelName: 方法参数 "$name" 未在 invokeMethod 中传递，'
        '原生端会按签名生成并等待该参数，运行时将取不到值，请在 invokeMethod 中补充。');
  }
}

/// 在方法体中定位 `invokeMethod('xxx#yyy', {...})` 调用，取出第二个参数的 map 字面量
class _InvokeMethodVisitor extends RecursiveAstVisitor<void> {
  _InvokeMethodVisitor(this.channelName);

  final String channelName;

  SetOrMapLiteral? argumentsMap;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (node.methodName.name == 'invokeMethod' && args.length >= 2) {
      final channel = args.first;
      if (channel is SimpleStringLiteral && channel.value == channelName) {
        final arguments = args[1];
        if (arguments is SetOrMapLiteral) {
          argumentsMap = arguments;
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}
