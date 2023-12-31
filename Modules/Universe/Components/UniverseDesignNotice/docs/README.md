# 常驻提示 Notice

## 简介

常驻提示用于展示用户需关注的信息。提示会一直保留，直到被用户主动关闭或者解决了导致出现常驻提示的条件才会消失。

组件实现了文本与按钮的混排外，还支持多行文本的展示，文本内超链接。

默认提供四种通用样式，支持自动布局与手动布局，对外暴露接口可定制图标与背景色等。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignNotice'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignNotice
```

## 常规的常驻提示

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "44"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/notice/ud_notice_demo_single_line_icon_btn.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/notice/ud_notice_demo_single_line_icon_btn_dm.png"
/>

```swift
/// 创建 UDNotice 相关配置
var config = UDNoticeUIConfig(type: .info,attributedText: NSAttributedString(string:"这是一条常驻提示的文本信息"))
config.trailingButtonIcon = UDIcon.closeOutlined

/// 初始化 UDNotice
let udNoticeView = UDNotice(config: config)
```

:::

## 添加文本操作按钮

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "44"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/notice/ud_notice_demo_single_line_text_btn.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/notice/ud_notice_demo_single_line_text_btn_dm.png"
/>

```swift
/// 创建 UDNotice 相关配置
var config = UDNoticeUIConfig(type: .info,attributedText: NSAttributedString(string:"单行常驻提示的文本信息"))
config.leadingButtonText = "操作"

/// 初始化 UDNotice
let udNoticeView = UDNotice(config: config)
```

:::

## 成功、失败、警告常驻提示

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "224"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDNotice/notice_all_light.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDNotice/notice_all_dark.png"
/>

```swift
/// 创建 UDNotice 相关配置
let normalConfig = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string:"这是一条常驻提示的文本信息"))
let successConfig = UDNoticeUIConfig(type: .success, attributedText: NSAttributedString(string:"这是一条成功提示的文本信息"))
let warningConfig = UDNoticeUIConfig(type: .warning, attributedText: NSAttributedString(string:"这是一条警告提示的文本信息"))
let errorConfig = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string:"这是一条失败提示的文本信息"))
```

:::

## 触发操作按钮回调函数

组件提供了三种情况下的点击事件回调，包括右侧图标按钮，文字按钮以及超链接按钮。

在使用本组件时需遵循[`UDNoticeDelegate`](#udnoticedelegate)协议。

```swift
/// 右侧按钮回调
func handleLeadingButtonEvent(_ button: UIButton)
/// 文字按钮回调
func handleTrailingButtonEvent(_ button: UIButton)
/// 说明文字中的操作文字回调
func handleTextButtonEvent(URL: URL, characterRange: NSRange)
```
## 排版样式
组件提供了居中、居左两种样式

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "120"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/notice_light.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/notice_d.png"
/>



<!-- <SiteImage
    width = "375"
    height = "47"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDNotice/73792882-a4a4-4886-b13f-7920fbc3a642.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDNotice/notice_all_dark.png"
/> -->


```swift
lazy var configError: UDNoticeUIConfig = {
    var config = UDNoticeUIConfig(type: .error, attributedText: NSAttributedString(string: "网络连接失败，请重试"))
    config.trailingButtonIcon = UDIcon.getIconByKey(.closeOutlined)
    config.leadingButtonText = "设置"
    return config
}()
lazy var noticeError: UDNotice = UDNotice(config: configError)
//居中
configError.alignment = .center
//居左
configError.alignment = .left
```

:::



## API 及配置列表

### UDNoticeUIConfig

组件提供了[`UDNoticeUIConfig`](#udnoticeuiconfig)作为 UI 配置项，其主要包括左侧 icon、标题内容，右侧文本按钮，右侧图片按钮，以及标题内是否包含超链接等相关属性、以及 UDNotice 背景色。

#### 创建预设 Notice

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
type<SiteTableRequired />| Notice 类型 |UDNoticeType|.clear
attributedText<SiteTableRequired />|Notice 文本内容 |NSAttributedString|""

#### 创建自定义 Notice

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
backgroundColor<SiteTableRequired />| 背景色 |UIColor| -
attributedText<SiteTableRequired />|Notice 文本内容 |NSAttributedString| -

#### UDNoticeUIConfig 属性

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
backgroundColor| 背景色 |UIColor| -
attributedText|Notice 文本内容 |NSAttributedString| -
leadingButtonText| 左侧文字按钮文案 |String|nil
leadingIcon| 左侧图标 |UIImage|nil
trailingButtonIcon| 右侧按钮图标 |UIImage|nil
alignment| 内容对齐方式 |UDNoticeAlignment|.left

### UDNoticeType

<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
left| 居左：默认情况下，文本左对齐。
center| 居中：在横屏状态下，为了让视觉焦点集中在居中位置，或页面为居中排版时，notice 建议使用居中对齐的规则。
### UDNoticeAlignment

<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
info| 常规提示：建议用于提示背景条件、功能信息、规范要求、当前状态等客观内容或基础信息。
success| 成功提示：建议用于提示已完成操作的成功状态。
warning| 警示提示：建议用于提示内容不安全，或用户操作可能导致某种后果的警示场景。
error| 错误提示：建议用于展示网络错误、系统或信息的报错或严重故障。最好提供引导用户解决的操作。

### UDNoticeDelegate

<SiteTableHighlight columns="2" type="3" />

接口 | 说明
---|---
handleLeadingButtonEvent(_ button: UIButton)| 右侧文字按钮点击事件回调
handleTrailingButtonEvent(_ button: UIButton)| 右侧图标按钮点击事件回调
handleTextButtonEvent(URL: URL, characterRange: NSRange)| 文字按钮 / 文字链按钮点击事件回调

### UDNotice

实例化 UDNotice。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
config<SiteTableRequired />| 常驻提示外观配置 | [UDNoticeUIConfig](#udnoticeuiconfig) | -

### UDNotice 接口

#### update

主题修改后重刷组件 UI。

#### updateConfigAndRefreshUI

修改 config 并刷新 UI。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
config<SiteTableRequired />| [UDNoticeUIConfig](#udnoticeuiconfig) | 新配置

#### sizeThatFits

适配多国语言获取自适应大小后的组件尺寸大小。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
contentSize<SiteTableRequired />|CGSize| 新尺寸
