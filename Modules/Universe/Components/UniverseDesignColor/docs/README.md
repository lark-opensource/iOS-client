# 颜色 Color

## 简介

色彩系统是用于构建产品界面的色彩体系和使用规范，能够强化品牌风格，赋予产品活力、提供视觉识别延续性。可帮助用户区分信息层级，为操作提供视觉反馈和传达信息状态，是界面设计中基础元素。

通用颜色组件可用于统一 App 颜色系统，突出 App 主题内容。不仅包含了基础颜色色板，还有丰富的语义化颜色色板及主题色。

## 安装

### 使用 CocoaPods 安装

添加至你的`Podfile`:

```bash
pod 'UniverseDesignColor'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignColor
```

## 使用基础色板

[基础色板](https://www.figma.com/file/ZFLuZgDWJglc21SkXnZH3a/Color-System?node-id=0%3A1&viewport=508%2C525%2C0.22160664200782776)采用 HSL 色彩模型进行设计，在 HSL 模式下色环以 30 度为单位，将 360 度色环依色相变化分为 13 份。每个颜色根据 HSL 曲线递增或递减，可拓展出 9 个衍生色，共 130 色，以满足业务中各场景需求。

目前`UniverseDesignColor`已包含全部" R O Y S L G T W B I P V C N "的 0 - 1000 色号。使用对`UIColor`扩展属性`ud`的方法进行使用：

```swift
let blue = UIColor.ud.B500
let red = UDColor.R500
```

## 使用语义化颜色

[语义化色板](https://bytedance.feishu.cn/docs/doccn1sB93r5rLzTcd4aiGepP18#) 主要是对基础色板使用语义化的方式包装，以便外部理解使用。同样使用对`UIColor`扩展属性`ud`的方法进行使用：

```swift
/// 抽象语义化颜色
let backgroundColor = UIColor.ud.bgFloat
```

## 构建自己的语义化颜色

ColorTheme 主要是为了 Universe Design Component 颜色主题化而提供的相关数据结构。

推荐模块设置自己的单独 ColorTheme，并针对 UDColor 的 Name 进行扩展。

```swift
public extension UDColor.Name {
    static let bgBody = UDColor.Name("bg-body")
}

public struct UDDialogColorTheme {
    public static var bgBody: UIColor {
        return UDColor.getValueByKey(.bgBody) ?? UDColor.N00 & UDColor.N50
    }
}
```

ColorTheme 提供 Store 字典，支持用户根据对应颜色的 Key 设置全局该颜色的色值，如修改`neutralColor1`的全局 RGB 颜色。

```swift
let storeMap = UDColor.getCurrentStore()
storeMap[.neutralColor1] = UDColor.neutralColor2
```

如此修改则会将全局使用`neutralColor1`的 key 的色值修改为`neutralColor2`对应的 RGB 颜色。

## 自定义 RGBA 使用方法

组件支持多种`RGBA`形式转换`UIColor`, 如十六进制、UInt32、（r, g, b, a）等格式。

同样使用对`UIColor`扩展属性`ud`的方法进行使用：

```swift
/// 格式：red, green, blue, alpha
let color = UIColor.ud.color(255, 255, 255, 1)

/// 格式：AARRGGBB
let color1 = UIColor.ud.color("AARRGGBB")
```

## 自定义动态颜色

组件提供了`&`运算方法，来实现自定义的 DarkMode。

如下面实现了一个 LM 下为红色，DM 下为绿色的动态颜色：

::: showcase collapse=false
<SiteImage
    width = "70"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColor/color_red.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColor/color_green.png"
/>

```swift
let dynamicColor = UIColor.red & UIColor.green
```

:::

## 禁用当前颜色的 Light 或 Dark 值

如果不想在某些组件内实现动态颜色，则可以在调用颜色时使用`.alwaysLight`、`alwaysDark`使 UDColor 保持不变。

```swft
var color1 = UIColor.ud.B100.alwaysLight
var color2 = UIColor.ud.B100.alwaysDark
```
