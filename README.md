# Faraday_CLI

`faraday_cli`(以下简称`cli`)是配合[g_faraday](https://github.com/gfaraday/g_faraday)进行模块化混合应用开发的命令行程序,帮助我们减少部分重复性工作让开发更高效

## Features

- [x] Generate Common&Entry interface
- [x] AutoComplete Common&Entry method
- [x] Package iOS&Android framework/aar

### 桥接方法

进行混合应用开发通常会有以下需求。有一个功能在ios/android两端已经实现，在flutter层需要调用，这时候就需要在flutter层来定义接口，然后在两端分别实现。下面我们来看一段代码示例

``` dart

class EncryptUtils {

    // 加密
    static Future<String> encrypt(String content, Map<String, dynamic> options) {
        return FaradayCommon.invokeMethod('SomeFeature#encrypt', {'content': content, 'options': options});
    }

    // 解密
    static Future<String> decrypt(String encryptedContent, Map<String, dynamic> options) {
        return FaradayCommon.invokeMethod('SomeFeature#decrypt', {'encryptedContent': encryptedContent, 'options': options});
    }
}

```

以上，我们在flutter中定义了加密和解密2个方法，接下来我们需要分别在ios/android的`FaradayCommon`中来实现代码如下(仅swift，kotlin类似)

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

仔细看上述代码实现就会发现有很多重复代码片段，因此`cli`提供了对应的生成工具来实现代码生。(具体命令请见下述示例)

### 路由注册

### 打包集成

## 快速开始
