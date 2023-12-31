# Universe-UI iOS Theme README

## 简介
ES Design System 设计规范和技术上支持灵活的样式定制，以满足不同业务多样化的视觉需求，包括全局样式（色彩、字体、圆角、投影）和指定组件的视觉定制。

`UniverseDesignTheme` 提供了目前 ESUX 的主题解决方案，定了主题的 Protocol，颜色、字体等主题模块都依据该 Protocol 进行实现

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignTheme'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignTheme
```

## 使用

`UDResource` 定义了 UD 组件库主题所需提供的接口，根据了 Value 及 Key 的类型生成对应字典，并提供 current theme 保证相关资源的唯一性。

为了方便实现对应的 Theme，`UDResource` 做了基本的扩展，新的模块仅需提供对应的 Key 及 Value 类型即可。扩展对应的 Key 值，即可获取到对应字典的 Value。推荐使用与`Notification.Name` 类似的扩展方法。

```swift
/// UniverseDesign Theme
struct UDTestTheme: UDResource {

    public struct Name: UDKey {
        public let key: String

        public init(_ key: String) {
            self.key = key
        }
    }

    static var current: Self = Self()

    var store: [UDTestTheme.Name: Int] = [:]

    init(store: [UDTestTheme.Name: Int] = [:]) {
        self.store = store
    }
}

extension UDTestTheme.Name {
    static let test1Key = UDTestTheme.Name("test1Key")
    static let test2Key = UDTestTheme.Name("test2Key")
    static let test3Key = UDTestTheme.Name("test3Key")
}
```

## API 及配置列表

UDResource

<SiteTableHighlight type="1" />

接口 | 参数 | 返回值 | 说明
---|----|-----|---
init | store: [Key: Value] | --- | init
updateCurrent | theme: Self | --- | 更新主题
updateCurrent | store: [Key: Value] | --- | 更新 Store Map
getValueByKey | key: Key |  Value？| 通过 Key 获取对应的 Value
getCurrentStore | ---| [Key: Value] | 获取当前 Theme 的 Store Map
