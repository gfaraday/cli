# Faraday_CLI

`faraday_cli`(以下简称`cli`)是配合[g_faraday](https://github.com/gfaraday/g_faraday)进行模块化混合应用开发的命令行程序。

## Features

- [x] Generate Common&Entry interface
- [x] Package iOS&Android framework/aar
- [x] AutoComplete Common&Entry method

### Generate

这里大家应该已经比较了解[模块化](https://github.com/gfaraday/g_faraday/blob/master/docs/feature.md)开发混合应用时`common`和`entry`的概念了，如果不清楚，建议大家看[这里](https://github.com/gfaraday/g_faraday/blob/master/docs/feature.md)。

#### common
我们先看一个典型需求，加入我们原生已经写好了加解密方法，flutter侧需要调用。我们用common来实现这个需求看一下


- 首先flutter层我们需要定义两个common方法

``` dart
class SomeFeature extends Feature {

    ...

    // 加密
    @common
    static Future<String> encrypt(String content, Map<String, dynamic> options) {
        return FaradayCommon.invokeMethod('SomeFeature#encrypt', {'content': content, 'options': options});
    }

    // 解密
    @common
    static Future<String> decrypt(String encryptedContent, Map<String, dynamic> options) {
        return FaradayCommon.invokeMethod('SomeFeature#decrypt', {'encryptedContent': encryptedContent, 'options': options});
    }
}
```

- 接下来我们来尝试在原生来实现这个两个方法看看

``` swift

func handle(_ name: String, _ arguments: Any?, _ completion: @escaping (_ result: Any?) -> Void) -> Void { 
    if (name == "SomeFeature#encrypt") {
        guard let content = args?["content"] as? String else {
                fatalError("Invalid argument: content")
        }
        let options = args?["options"] as? [String, Any]
        
        // 使用以上参数来调用原生加密方法
    } else if (name = "SomeFeature#decrypt") {
        guard let encryptedContent = args?["encryptedContent"] as? String else {
                fatalError("Invalid argument: encryptedContent")
        }
        let options = args?["options"] as? [String, Any]
        
        // 使用以上参数来调用原生解密方法
    }
    ...
}

```
仔细观察原生的实现方法就会发现有大量的重复代码， 随着`common`方法越来越多这里会重现海量的重复劳动。对于这种情况就可以使用`cli`命令的`generate`方法来生成这些对应的原生接口文件，我们只需要根据接口来添加相应的本地实现即可。

#### entry

flutter和原生的路由交互基本都是通过字符串来完成的，如果每次打开页面都需要原生的同学来手动输入路由的标示不仅麻烦而且很容易出错。所以`cli`也对此进行了支持。我们来看下面的例子

- 在flutter侧定义一个native入口路由

``` dart
class SomeFeature extends Feature {

    ...

    @entry
    static Future someFeatureHome(BuildContext context, int id) {
        return Navigator.of(context).push('someFeature_home', {'id': id});
    }
}
```

- 在原生我们生成一个对应的枚举

``` swift
enum FaradayRoute { 
    case someFeatureHome(_ id: int)

    func viewController(callback: @escaping (Any?) -> () = { r in debugPrint("result not be used \(String(describing: r))")}) -> FaradayFlutterViewController {
        return FaradayFlutterViewController(page.name, arguments: page.arguments, callback: callback)
    }
}

// 使用的时候就可以很容的创建这个路由

let vc = FaradayRoute.someFeatureHome(1234).viewController()

```

这里创建路由也是一个重复性的工作，可以用`cli` 来自动完成

### Package

这里涉及到`common`和`entry`我们分别来细说
<!-- 是什么 -->
<!-- 初始化 -->
<!-- 更新 -->