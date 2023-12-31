# 弹窗 Dialog

## 简介

弹窗是一种模态窗口，出现在应用程序内容的最高层级，用于提供重要信息或决策。弹窗出现时禁用所有应用程序功能，并一直显示在屏幕上，直到用户进行确认，关闭等操作为止。

组件不仅实现了系统弹窗，再此基础上提供了样式更加丰富的功能。如：UI 属性定制、内容区域定制，交互按钮布局多样等功能。提供多种 API 接口使用户开发更加方便，能够快速掉用相关 API 构建所需弹窗样式。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignDialog'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignDialog
```

## 基础弹窗

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "228"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/dialog/ud_dialog_demo.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/dialog/ud_dialog_demo_dm.png"
/>

```swift
var dialog = UDDialog()
dialog.setTitle(text: "我是标题")
dialog.setContent(text: "我是纯文本内容")
dialog.addSecondaryButton(text: 次要操作")
dialog.addPrimaryButton(text: "主要操作")
self.present(dialog, animated: true)
```

:::

## 含有警告操作的弹窗

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "300"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDialog/dialog-tri-l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDDialog/dialog-tri-d.png"
/>

```swift
var dialog = UDDialog()
dialog.setTitle(text: "我是标题")
dialog.setContent(text: "我是纯文本内容")
dialog.addSecondaryButton(text: "取消")
dialog.addDestructiveButton(text: "警告")
dialog.addPrimaryButton(text: "确认")
self.present(dialog, animated: true)
```

:::

## 自定义内容的弹窗

1. 组件提供了[`UDDialogUIConfig`](#uddialoguiconfig)类型，作为`UDDialog`抽离的 UI 配置项。可以对包括圆角、标题相关属性、交互按钮布局样式，内容内边距，分割线颜色以及`UDDialog`背景色等属性进行配置。
2. 组件提供了[`setContent`](#setcontent)方法，可将自定义的 view 作为参数传入，实现弹窗内容自定义。

下面将创建一个自定义的弹窗，包含以下内容

- 弹窗将包含两个按钮，分别为取消、确认
- 弹窗将包含一个输入框，背景色为[`UDColor.N300`](../../UniverseDesignColor/docs/README.md)
- 弹窗圆角为 32
- 弹窗标题颜色为[`UDColor.P300`](../../UniverseDesignColor/docs/README.md)
- 弹窗按钮为纵向排列
- 弹窗背景颜色为[`UDColor.R300`](../../UniverseDesignColor/docs/README.md)


```swift
let content = UIView()
let inputView = UITextField()
inputView.backgroundColor = UIColor.ud.N300
inputView.layer.cornerRadius = 8
content.addSubview(inputView)
inputView.snp.makeConstraints { make in
    make.edges.equalToSuperview()
    make.height.equalTo(44)
}

let config = UDDialogUIConfig(cornerRadius: 32,
                              titleColor: UIColor.ud.P300,
                              style: .vertical,
                              backgroundColor: UIColor.ud.R200)
let dialog = UDDialog(config: config)
dialog.setTitle(text: "我是标题")
dialog.setContent(view: content)
dialog.addSecondaryButton(text: "取消")
dialog.addPrimaryButton(text: "确认")
self.present(dialog, animated: true)
```

## API 及配置列表

### UDDialogUIConfig

组件提供了[`UDDialogUIConfig`](#uddialoguiconfig)作为弹窗的 UI 配置项，其主要包括圆角、标题相关属性、交互按钮布局样式，内容内边距，分割线颜色以及`UDDialog`背景色。

弹窗会根据 config 中的配置进行布局展示相关元素。（按钮的颜色等样式在 API 中单独配置，因为每个按钮不一样）

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
cornerRadius| 弹窗圆角 |UDStyle|largeRadius
titleFont| 标题字体 |UDFont|title3
titleColor| 标题颜色 |UDColor|dialogTextColor
titleAlignment| 标题格式 |NSTextAlignment|center
titleNumberOfLines|Int|1| 标题默认行数
style| 按钮布局规范 |UDDialogButtonLayoutStyle|normal
contentMargin| 内容区域边距 |UIEdgeInsets|(16,20,18,20)
splitLineColor| 分割线颜色 |UDColor|dialogBorderColor
backgroundColor| 弹窗背景色 |UDColor|dialogBgColor

考虑到`UDDialog`的特殊情况，config 只能在`init`方法中传入，无法更改，为了保证从始至终的一致性。所有配置及 UI 应在`ViewDidLoad`之前准备完毕。

### UDDialogButtonLayoutStyle

弹窗的按钮布局类型。

<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
normal| 普通样式布局
horizontal| 横式布局，超过两个按钮自动切换为竖式布局
vertical| 竖式布局

### UDDialog 接口

#### setTitle

设置弹窗标题，如不设置 title 则不展示对应的标题。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - |UDDialog 标题

#### setContent

设置弹窗文本或弹窗自定义视图

1. 设定文本。
  
<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
view<SiteTableRequired />| - | 自定义 view

2. 设定富文本。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
attributedText<SiteTableRequired />| - | 富文本内容
numberOfLines|0| 最多展示行数

3. 设定自定义视图。

自定义视图会重做之前的约束，所以不能设置完成之后再次给视图设置外部约束，需要在 config 中设置对应的`contentMargin`。视图内部需要通过自己的的`subviews`撑开，否则无法展示。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - | 内容文本
color|UDColor.textTitle| 文本颜色
font|UDfont.body0| 文本字体
alignment|.center| 文本对齐方式 (默认局中，超过两行时居左)
numberOfLines|0| 最多展示行数

#### addButton

添加颜色为蓝色（可自定义颜色）的默认样式按钮。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - | 按钮文本
color|UDColor.primaryPri500| 按钮文本颜色
font|UDfont.body0| 按钮文本字体
numberOfLines|0| 最多展示行数
dismissCheck|true| 模态框关闭之前执行的闭包，返回值代表是否可以关闭
dismissCompletion|nil| 模态框关闭之后执行的闭包，如果`dismissCheck`返回`false`则不会执行此闭包

#### addSecondaryButton

添加颜色为灰色的次要操作按钮。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - | 按钮文本
numberOfLines|0| 最多展示行数
dismissCheck|true| 模态框关闭之前执行的闭包，返回值代表是否可以关闭
dismissCompletion|nil| 模态框关闭之后执行的闭包，如果`dismissCheck`返回`false`则不会执行此闭包

#### addDestructiveButton

添加颜色为红色的警告级别按钮。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - | 按钮文本
numberOfLines|0| 最多展示行数
dismissCheck|true| 模态框关闭之前执行的闭包，返回值代表是否可以关闭
dismissCompletion|nil| 模态框关闭之后执行的闭包，如果`dismissCheck`返回`false`则不会执行此闭包
