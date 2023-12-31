LKCommonsLogging
======

## 需求

随着业务的发展，会将越来越多的业务逻辑、组件拆分独立出来，成为单独的静态库或pods。 这些pods均依赖日志组件提供输出日志的功能。为了统一标准化各pods库的日志记录方式，并且为应用程序提供更多的日志输出控制权。参考 apache commons-logging 实现了一套简单的、基于swift的日志输出接口。

## 安装

本库在swift4下构建，同时支持 Cocoapods、Carthage、 Swift Package Manager

### cocoapods

Podfile

```ruby
pod 'LKCommonsLogging'
```

### Carthage
Cartfile

```ruby
git 'git@code.byted.org:ee/LKCommonsLogging-swift'
```

### Swift Package Manager
Package.swift

```swift
let package = Package(
    ...
    
    dependencies: [
        ...
        .package(url: "git@code.byted.org:ee/LKCommonsLogging-swift", from: "0.1.0"),
        ...
    ],
    
    ...
)

```

## 使用说明

### 日志记录方 （模块）

#### 创建日志对象

```swift
static let logger = Logger.log(JsSDK.self, category: "Module.JSSDK")
```

#### 记录日志

```swift
...
logger.error("未找到函数名，无法注册")
...

logger.trace("step 1")
```

### 日志提供方 （App或专属日志模块）

LKCommonsLogging 提供了一个简单的直接输出到控制台的实现，在未做配置时默认使用。不建议在生产环境中使用。

若要对接实际使用的日志系统，请参考如下：

#### 实现日志协议 & 日志工厂协议

```swift
import LKCommonsLogging

class LogImp:Log {
    ...
    func isDebug() -> Bool { ... }
    func isTrace() -> Bool { ... }
    func _log(
        time: TimeInterval,
        level: LogLevel,
        message: String,
        thread: String,
        file: String,
        function: String,
        line: Int,
        error: Error?,
        additionalData: [String:String]?) {
            ...
    }
    ...
}

class Logger:LogFactory {
...
    static func _log(_ type: Any, category: String) -> Log {
        ...
    }
...

}
```

#### 在初始化时配置日志工厂

```swift
import LKCommonsLogging

LKCommonsLogging.Logger.setup(Logger.self)
```

## TODO
1. 提供有实际使用意义的，可以用于简单生产环境的默认实现
2. 优化注册、发现日志工厂机制。
3. 支持注册多个日志工厂、按配置分配给某个模块。
