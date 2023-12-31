# 按钮 Button

## 简介

按钮用于执行用户在交互流程中触发指令、提交更改或完成的即时操作。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignButton'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignButton
```

## 普通按钮

::: showcase collapse=false
<SiteImage
    width = "164"
    height = "48"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_dm.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton.png"
    />

```swift
var config = UDButtonUIConifg.primaryBlue
var button = UDButton(config)
button.setTitle("按钮", for: .normal)
```

:::

## 加载态按钮

::: showcase collapse=false
<SiteImage
    width = "164"
    height = "48"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_Loading.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_Loading_dm.png"
    />

```swift
var config = UDButtonUIConifg.primaryBlue
config.type = .big
var button = UDButton(config)
button.setTitle("按钮", for: .normal)
button.showLoading()
button.hideLoading()
```

:::

## 带图标的按钮

::: showcase collapse=false
<SiteImage
    width = "164"
    height = "48"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_icon_dm.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_icon.png"
    />

```swift
var icon = UDIcon.getIconByKey(.imageOutlined, 
                               iconColor: self.iconColorType.getColor(), 
                               size: CGSize(width: 12, height: 12))
button.setImage(icon, for: .normal)
```

:::

## 不同类型的按钮

通过表意清晰的文本标签与按钮样式向用户准确传递按钮的功能目标与当前状态；
一个决策情境中最多只能出现一个主按钮，用于展示最为推荐、最具功能性的操作；
一个决策情境中显示的按钮不应超过 3 个，如需要更多操作选项，则考虑使用单选按钮或复选框；
次级按钮可以与主按钮搭配，来展示“不执行、取消”或单独使用，展示“关闭、知道了”等结束性的操作。

::: showcase collapse=false
<SiteImage
    width = "180"
    height = "448"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_all.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDButton/UDButton_all_dm.png"
    />

```swift
var config = UDButtonUIConifg.defaultConfig
var config = UDButtonUIConifg.primaryBlue
var config = UDButtonUIConifg.primaryRed
var config = UDButtonUIConifg.secondaryGray
var config = UDButtonUIConifg.secondaryBlue
var config = UDButtonUIConifg.secondaryRed
var config = UDButtonUIConifg.textGray
var config = UDButtonUIConifg.textBlue
var config = UDButtonUIConifg.textRed
```

:::

## 自定义外观按钮

组件继承自`UIButton`，提供了可定制的[`UDButtonUIConifg`](#udbuttonuiconifg)，用户根据自身需求可定制对应颜色。

```swift
var normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                              backgroundColor: UIColor.ud.B500,
                                              textColor: UIColor.ud.N00)
var pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                               backgroundColor: UIColor.ud.B600,
                                               textColor: UIColor.ud.N00)
var disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                               backgroundColor: UIColor.ud.N400,
                                               textColor: UIColor.ud.N00)
var config = UDButtonUIConifg(normalColor: normalColor,
                              pressedColor: pressedColor,
                              disableColor: disableColor)
var button = UDButton(config)
```

## 更新按钮外观

按钮配置的更新，可通过[`UDButton.config`](#udbuttonuiconifg)实现，同时，也可以通过访问 config 属性的方式对按钮的某项外观进行修改。

```swift
/// 旧 Button
var config = UDButtonUIConifg.defaultConfig
var button = UDButton(config)
button.config = UDButtonUIConifg.primaryRed
button.config.radiusStyle = .circle
```

## API 及配置列表

### UDButtonUIConifg ButtonType

<SiteTableHighlight columns="3" type="1" />

变量 | 字体 | 默认值 | 说明
---|---|---|---
small|14|CGSize(width: 60, height: 28)| 小尺寸
middle|14|CGSize(width: 76, height: 36)| 中尺寸
big|17|CGSize(width: 104, height: 48)| 大尺寸

### UDButtonUIConifg

组件提供了`UDButtonUIConifg`作为 UI 配置项，其初始化参数同样可以作为属性进行访问和修改。

<SiteTableHighlight columns="3" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
normalColor<SiteTableRequired /> 普通状态下 button 的颜色 | UIColor | -
pressedColor| 按压状态下 button 的颜色 | UIColor | nil
disableColor| 不可点击状态下 button 的颜色 | UIColor | nil
loadingColor| loading 状态下 button 的颜色 | UIColor | nil
loadingIconColor| loading icon 颜色 | UIColor | nil
type | button 类型，影响边距及大小 | [ButtonType](#udbuttonuiconifg-buttontype) | small
radiusStyle | button 圆角类型 | ButtonStyle | square

### UDButton

<SiteTableHighlight columns="3" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
config| `UDButton`的 UI 配置 | [UDButtonUIConifg](#udbuttonuiconifg) | UDButtonUIConifg.defaultConfig

### UDButton 属性

<SiteTableHighlight columns="3" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
config| `UDButton`的 UI 配置 | [UDButtonUIConifg](#udbuttonuiconifg) | UDButtonUIConifg.defaultConfig
isEnabled| 按钮是否可用 | Bool | true
isHighlighted ｜ 按钮点击是否高亮｜ Bool | false

### UDButton 接口

#### setImage

设置按钮图标。

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
image| nil | 图标图片
state<SiteTableRequired />| 按钮状态 | UIControl.State | -

#### showLoading

展示 loading 态，会有一个加载图标出现。

#### hideLoading

隐藏 loading，恢复正常。
