# 输入框 Input

## 简介

输入框引导用户输入信息和编辑文本，通常使用于表单和会话，是最基础的文本输入组件。

通用输入框组件提供了单行输入框及多行输入文本两种输入框可供开发者使用。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignInput'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignInput
```

## 单行输入框

一个普通的输入框，带自定义按钮圆角、边框宽度和边框颜色。

::: showcase collapse=false
<SiteImage
    width = "343"
    height = "48"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/input/ud_edittext_demo.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/input/ud_edittext_demo_dm.png"
    />

```swift
let textField = UDTextField()
textField.config.isShowBorder = true
textField.placeholder = "请输入"
```

:::

## 单行输入框显示标题及错误信息

在配置标题或错误信息时，需在[`UDTextFieldUIConfig`](#udtextfielduiconfig)中开启或设置对应的功能。

::: showcase collapse=false
<SiteImage
    width = "343"
    height = "102"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/input/ud_input_error_demo.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/input/ud_input_error_demo_dm.png"
    />

```swift
let textField = UDTextField()
textField.config.isShowBorder = true
// 设置标题
textField.config.isShowTitle = true
textField.title = "标题占位符文本"
// 设置错误提示
textField.config.errorMessege = "报错信息"
// 设置输入框为错误状态
textField.setStatus(.error)
```

:::

## 单行输入框输入时状态更新

本组件共提供四种输入框状态`normal`、`activated`、`disable`、`error`。

```swift
textField.setStatus(.normal)
textField.setStatus(.activated)
textField.setStatus(.disable)
textField.setStatus(.error)
```

## 自定义单行输入框

本组件提供了[`UDTextFieldConfig`](#udtextfielduiconfig)用来配置组件外观，可以通过设置对应属性、参数实现不同 UI 的定制效果。

组件可在左右侧自定义 view。实现左侧图标或右侧图案的更新。

属性名 | 类型 | 默认值 | 说明
:--:|:--:|:--:|:--:
isShowBorder|Bool|false| 是否展示边框
isShowTitle|Bool|false| 是否展示标题
clearButtonMode|UITextField.ViewMode|.never| 清除按钮类型
backgroundColor|UIColor|nil| 输入框背景色
borderColor|UDInputColorTheme|inputNormalBorderColor| 边框颜色
textColor|UDInputColorTheme|inputInputtingTextColor| 文本颜色
placeholderColor|UDInputColorTheme|inputNormalPlaceholderTextColor| 占位符颜色
font|UDFont|title4| 输入字体大小
textMargins|UIEdgeInsets|top: 13, left: 12, bottom: 13, right: 12| 文字边距
contentMargins|UIEdgeInsets|.zero| 全部内容边距
leftImageMargins|UIEdgeInsets|nil| 图片左边距
rightImageMargins|UIEdgeInsets|nil| 图片右边距
errorMessege|String？|nil| 错误信息
maximumTextLength|Int？|nil| 最大文本长度
textAlignment|NSTextAlignment|.left| 文本格式
minimumFontSize|CGFloat|16| 最小字体大小

## 多行输入框

多文本编辑可在需要输入大量文字时使用，如：邮件、评价、反馈、申请等情况下使用。

同时[`UDMultilineTextField`](#udmultilinetextfield)还支持统计字数，设置最大字数等。

::: showcase collapse=false
<SiteImage
    width = "180"
    height = "150"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDInput/input_multi_normal_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDInput/input_multi_normal_d.png"
    />

```swift
let textField = UDMultilineTextField()
textField.config.isShowBorder = true
textField.placeholder = "请输入"
```

:::

## 多行输入框显示统计字数

组件内提供了计数功能，可通过[`UDMultilineTextField`](#udmultilinetextfield)中的`isShowWordCount`开启。

::: showcase collapse=false
<SiteImage
    width = "200"
    height = "200"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDInput/input_multi_count_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDInput/input_multi_count_d.png"
    />

```swift
let textField = UDMultilineTextField()
textField.config.isShowBorder = true
textField.config.isShowWordCount = true
textField.placeholder = "请输入"
```

:::
若未出现统计字符，请尝试调整高度约束。

## API 及配置列表

### UDTextFieldUIConfig

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
isShowBorder|false| 是否展示边框
isShowTitle|false| 是否展示标题
clearButtonMode|never| 清除按钮类型
backgroundColor|nil| 输入框背景色
borderColor|inputNormalBorderColor| 边框颜色
textColor|inputInputtingTextColor| 文本颜色
placeholderColor|inputNormalPlaceholderTextColor| 占位符颜色
font|title4| 输入字体大小
textMargins|top: 13, left: 12, bottom: 13, right: 12| 文字边距
contentMargins|.zero| 全部内容边距
leftImageMargins|nil| 图片左边距
rightImageMargins|nil| 图片右边距
errorMessege| - | 错误信息
maximumTextLength| - | 最大文本长度
textAlignment|left| 文本格式
minimumFontSize|16| 最小字体大小

### UDTextField

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
config|UDTextFieldUIConfig()|UDTextField 输入框外观配置

### UDTextField 接口

#### setLeftView

设置左边自定义 view。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
view|UIView| 自定义视图

#### setRightView

设置右边自定义 view。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
view|UIView| 自定义视图

#### setStatus

设置输入框状态。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
status|UDInputStatus| 输入框状态

### UDMultilineTextFieldUIConfig

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
isShowBorder|false| 是否展示边框
isShowWordCount|false| 是否展示统计数字
clearButtonMode|never| 清除按钮类型
backgroundColor|nil| 输入框背景色
borderColor|inputNormalBorderColor| 边框颜色
textColor|inputInputtingTextColor| 文本颜色
placeholderColor|inputNormalPlaceholderTextColor| 占位符颜色
font|title4| 输入字体大小
textMargins|top: 13, left: 12, bottom: 13, right: 12| 文字边距
errorMessege| --- | 错误信息
textAlignment|left| 文本格式
minimumFontSize|16| 最小字体大小

### UDMultilineTextField

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
config|UDTextFieldUIConfig()|UDTextField 输入框外观配置

### UDMultilineTextField 接口

#### setStatus

设置输入框状态。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
status|UDInputStatus| 输入框状态
