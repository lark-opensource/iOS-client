# 选择框 CheckBox

## 简介

选择框提拱了高度可配置的配置项，并且抽离相关 UI 配置，开发者可以快速调用修改相关状态。

单选框用于从一组直接展开的选项中选择单个选项，复选框用于从一组选项中选择一项或多项。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignCheckBox'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignCheckBox
```

## 单选样式

组件内置`.single`类型作为单选样式参数，默认为单选选择框。

::: showcase collapse=false
<SiteImage
    width = "50"
    height = "50"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/checkbox/ud_checkbox_demo_radio.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/checkbox/ud_checkbox_demo_radio_dm.png"
    />

```swift
let checkbox = UDCheckBox()
```

:::

## 多选样式

组件内置`.multiple`类型作为多选样式参数，`.mixed`类型作为部分选择样式参数。

::: showcase collapse=false
<SiteImage
    width = "50"
    height = "50"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/checkbox/ud_checkbox_demo_checkbox.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/checkbox/ud_checkbox_demo_checkbox_dm.png"
    />

```swift
let checkbox = UDCheckBox(boxType: .multiple)
let checkbox = UDCheckBox(boxType: .mixed)
```

:::

## 列表样式

组件内置`.list`类型作为列表样式参数。

::: showcase collapse=false
<SiteImage
    width = "50"
    height = "50"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/checkbox/ud_checkbox_demo_check_mark.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/checkbox/ud_checkbox_demo_check_mark_dm.png"
    />

```swift
let checkbox = UDCheckBox(boxType: .list)
```

:::

## 更改选择框可用状态

组件支持`isEnable`属性访问的方式，来获取、改变当前该选择框的可用状态。

```swift
checkBox.isEnabled = false
```

## 更改选择框选中状态

组件支持`isSelected`属性访问的方式，来获取、改变当前选择框的选中状态。

```swift
checkBox.isSelected = false
```

## 自定义选择框

组件提供了`boxType`用来控制对应的 CheckBox 的样式，

同时[`UDCheckBoxUIConfig`](#udcheckboxuiconfig)为开发者提供了可定制的选项。通过生成不同的的 config，开发者可以自定义各个状态下的 [CheckBox](#udcheckbox) 颜色及圆角等外形。

```swift
var checkBox = UDCheckBox(boxType: .single,
                          config: UDCheckBoxUIConfig(borderEnabledColor: .blue,
                                  borderDisabledColor: .gray,
                                  selectedBackgroundDisableColor: .green,
                                  unselectedBackgroundDisableColor: .red,
                                  selectedBackgroundEnabledColor: .purple,
                                  unselectedBackgroundEnabledColor: .clear,
                                  style: .square),
                          tapCallBack: nil)
```

## API 及配置列表

### UDCheckBoxUIConfig

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
borderEnabledColor | borderEnabledColor | 可点击状态下 border 的颜色
borderDisabledColor | borderDisabledColor | 不可点击状态下 border 的颜色
selectedBackgroundDisableColor | selectedBackgroundDisabledColor | 不可点击状态下已选中 checkbox 的背景色
unselectedBackgroundDisableColor | unselectedBackgroundDisableColor | 不可点击状态下未选中 checkbox 的背景色
selectedBackgroundEnabledColor | selectedBackgroundEnabledColor | 可点击状态下已选中 checkbox 的背景色
unselectedBackgroundEnabledColor | unselectedBackgroundEnabledColor | 可点击状态下未选中 checkbox 的背景色
style | circle | checkbox 圆角样式

### UDCheckBox

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
boxType|.single| 选择框类型
config|UDCheckBoxUIConfig()| 选择框 UI 配置
tapCallBack|nil| 选择框点击回调

### UDCheckBox 接口

#### updateUIConfig

更新当前选择框的外观配置。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
boxType<SiteTableRequired />| - | 选择框类型
config<SiteTableRequired />| - | 选择框 UI 配置

