# 颜色选择器 Color Picker

## 简介

颜色选择器是一个视图。 用于在多个备选颜色中选择、筛选一个合适的颜色。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignColorPicker'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignColorPicker
```

## 基础颜色选择器

选择基础颜色。应用场景如选择用户头像背景颜色。

使用时需构建对应颜色模型传入到 config 中，再将 config 传入`UDColorPickerPanel`进行初始化。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "170"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/baseColorPicker.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/baseColorPicker_dm.png"
    />

```swift
var baseModel = UDColorPickerConfig.defaultModel(category: .basic, title: "选择颜色")
var config = UDColorPickerConfig(models: [baseModel])
var colorPickerPanel = UDColorPickerPanel(config: config)
```

:::

## 字体颜色选择器

选择文本颜色。应用场景如是 Docs 中，设置文本颜色。

使用时需构建对应颜色模型传入到 config 中，再将 config 传入`UDColorPickerPanel`进行初始化。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "94"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/fontColorPicker.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/fontColorPicker_dm.png"
    />

```swift
var textModel = UDColorPickerConfig.defaultModel(category: .text, title: "选择颜色")
var config = UDColorPickerConfig(models: [textModel])
var colorPickerPanel = UDColorPickerPanel(config: config)
```

:::

## 文本背景颜色选择器

选择文本背景颜色。应用场景如是 Docs 中，设置文本背景颜色。

使用时需构建对应颜色模型传入到 config 中，再将 config 传入`UDColorPickerPanel`进行初始化。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "94"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/textColorPicker.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/textColorPicker_dm.png"
    />

```swift
var textBGModel = UDColorPickerConfig.defaultModel(category: .background, title: "选择颜色")
var config = UDColorPickerConfig(models: [textBGModel])
var colorPickerPanel = UDColorPickerPanel(config: config)
```

:::

## 组合颜色选择器

组件提供了不同颜色选择器的组合方式。方便快速进行组合。

使用时需构建对应颜色模型组合传入到 config 中，再将 config 传入`UDColorPickerPanel`进行初始化。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "268"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/groupColorPicker.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/groupColorPicker_dm.png"
    />

```swift
var textModel = UDColorPickerConfig.defaultModel(category: .text, title: "文本颜色")
var textBGModel = UDColorPickerConfig.defaultModel(category: .background, title: "文本背景颜色")
var config = UDColorPickerConfig(models: [textModel, textBGModel])
var colorPickerPanel = UDColorPickerPanel(config: config)
```

:::

## 自定义颜色选择器

组件支持你提供自己的自定义颜色：

1. 通过你自身的方式将你的颜色数据转换为[`UDPaletteModel`](#udpalettemodel)模型，如根据 json 数据映射模型、直接初始化[`UDPaletteModel`](#udpalettemodel)构建模型等。
2. 将颜色模型传入外观配置。
3. 将 config 传入，初始化`UDColorPickerPanel`。

下方构建了一个自定义的彩虹色，默认选择第 4 个的基础颜色选择器。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "170"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/customColorPicker.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDColorPicker/customColorPicker_dm.png"
    />

```swift
// 构建颜色模型
var model = UDPaletteModel(category: .basic,
                           title: "自定义颜色选择器",
                           items: [UDPaletteItem(color: .red),
                                   UDPaletteItem(color: .orange),
                                   UDPaletteItem(color: .yellow),
                                   UDPaletteItem(color: .green),
                                   UDPaletteItem(color: .cyan),
                                   UDPaletteItem(color: .blue),
                                   UDPaletteItem(color: .purple)],
                            selectedIndex: 3 )
// 将颜色模型传入 config 构建 UDColorPickerConfig
var config = UDColorPickerConfig(models: [model])
// 将 config 传入，构造 UDColorPickerPanel
var colorPickerPanel = UDColorPickerPanel(config: config)
```

:::

## 颜色选择器选中颜色回调

用于设置 UDColorPickerPanel 选中颜色代理。

```swift
self.delegate = delegate
```

## 更新外观配置

组件提供`update`方法，用于更新[`UDColorPickerConfig`](#udcolorpickerconfig)。

```swift
colorPickerPanel.update(config)
```

## API 及配置列表

### UDPaletteItem

单个色块的颜色。

<SiteTableHighlight columns="3" type="1" />

参数名 | 默认值 | 说明
---|---|---
color<SiteTableRequired />| - | 色块颜色

### UDPaletteModel

颜色模型。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
category<SiteTableRequired />|colorpicker 类型：basic、text 和 background| -
title<SiteTableRequired /> | 标题 |String| -
items<SiteTableRequired />| 色块组 |UDPaletteItem| -
selectedIndex|| 选中的色块的索引 | Int|0

### UDColorPickerConfig

UDColorPicker 配置信息。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
category<SiteTableRequired />|colorpicker 类型：basic、text 和 background| UDPaletteItemsCategory | -
title<SiteTableRequired />| 标题 |String| -
items<SiteTableRequired />| 色块组 |UDPaletteItem| -
selectedIndex| 选中的色块的索引 |Int|0
