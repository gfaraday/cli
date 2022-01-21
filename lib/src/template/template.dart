String _header = '''//  Created by faraday_cli on ${DateTime.now()}.
//
//    ___                   _
//   / __\\_ _ _ __ __ _  __| | __ _ _   _
//  / _\\/ _` | '__/ _` |/ _` |/ _` | | | |
// / / | (_| | | | (_| | (_| | (_| | |_| |
// \\/   \\__,_|_|  \\__,_|\\__,_|\\__,_|\\__, |
//                                  |___/
//
// GENERATED CODE BY FARADAY CLI - DO NOT MODIFY BY HAND
''';

// ignore: non_constant_identifier_names
String k_common = '''import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

$_header

@Suppress("UNCHECKED_CAST")
interface Common: MethodChannel.MethodCallHandler {
    // ---> interface

    fun defaultHandle(call: MethodCall, result: MethodChannel.Result): Boolean {
        val args: Map<*, *> = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
        // ---> impl

        return false
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (!defaultHandle(call, result)) {
            print("Faraday->Warning \${call.method} not handle. argument: \${call.arguments}")
        }
    }
}
''';

// ignore: non_constant_identifier_names
String k_route = '''import android.app.Activity
import com.yuxiaor.flutter.g_faraday.FaradayActivity

$_header

sealed class FlutterRoute(val routeName: String, val routeArguments: HashMap<String, Any?>? = null) {
// ---> sealed
}
''';

// String k_net = '''import io.flutter.plugin.common.MethodCall
// import io.flutter.plugin.common.MethodChannel
// import java.util.*

// $_header

// fun flutterNetBridge(call: MethodCall, result: MethodChannel.Result) {
//     val args: Map<*, *> = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
//     val method = call.method.toUpperCase(Locale.ROOT)

//     val query = args["query"] as? Map<*, *>
//     val body = args["body"] as? Map<*, *>
//     val additions = args["additions"]

//     result.notImplemented()
// }

// ''';

// ignore: non_constant_identifier_names
String s_route = '''import Foundation
import g_faraday

$_header

enum FaradayRoute {
    // ---> enum

    var page: (name: String, arguments: Any?) {
        switch self {
            // ---> enum_page
        }
    }

    func viewController(callback: @escaping (Any?) -> () = { r in debugPrint("result don't be used \\(String(describing: r))")}) -> FaradayFlutterViewController {
        return FaradayFlutterViewController(page.name, arguments: page.arguments, callback: callback)
    }
}

''';

// ignore: non_constant_identifier_names
String s_common = '''import Foundation

$_header

protocol FaradayCommonHandler {
    
    // ---> protocol
    
    func handle(_ name: String, _ arguments: Any?, _ completion: @escaping (_ result: Any?) -> Void) -> Void
}

extension FaradayCommonHandler {
    
    func handle(_ name: String, _ arguments: Any?, _ completion: @escaping (_ result: Any?) -> Void) -> Void {
        if (!defaultHandle(name,arguments,completion)) {
            debugPrint("Faraday->Warning \\(name) not handle. argument: \\(arguments ?? "")")
        }
    }
    
    func defaultHandle(_ name: String, _ arguments: Any?, _ completion: @escaping (_ result: Any?) -> Void) -> Bool {
        let args = arguments as? Dictionary<String, Any>
        // ---> impl
        return false
    }
    
}

''';

// String s_net = '''import Foundation
// import Flutter

// $_header

// func flutterNetBridge(_ name: String, _ arguments: Any?, _ completion: @escaping (_ result: Any?) -> Void) -> Void {

//     let args = arguments as? [String: Any]

//     let method = name.uppercased(); // REQUEST/GET/PUT/POST/DELETE
//     let query = args?["query"] as? [String: Any]
//     let body = args?["body"] as? [String: Any]
//     let additions = args?["additions"]

//     completion(FlutterMethodNotImplemented);
// }
// ''';

// ignore: non_constant_identifier_names
String d_debug([String message = 'faraday']) {
  return '''
$_header

const debugVersionMessage = '$message';
''';
}

// ignore: non_constant_identifier_names
String d_route() {
  return '''import 'package:flutter/cupertino.dart';
import 'package:g_faraday/g_faraday.dart';

Route<dynamic> routeFactory(RouteSettings settings) {
  final JSON args = settings.toJson;

  switch (settings.name) {
    // ---> route
    default:
      return null;
  }
}
  ''';
}
