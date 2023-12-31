# 动作面板 Action Panel

## 简介

动作面板是一种从底部划入的模态窗，分为活动面板和操作表两大类。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignActionPanel'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignActionPanel
```

## 普通操作表

操作表是当用户激发一个操作时出现的浮层。使用操作表让用户可以基于当前任务的明确性判断或者对破坏性操作（如：删除、退出登录等）进行二次确认。操作表为了保持和系统一直，必须传递对应的资源视图以用来适配 iPad。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "384"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/dialog/ud_action_sheet_demo.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/dialog/ud_action_sheet_demo_dm.png"
/>

```swift
/// 创建面板 ipad 时的 popover 物料
let source = UDActionSheetSource(sourceView: clickButton,
                                 sourceRect: clickButton.bounds,
                                 arrowDirection: .up)
///创建面板配置
let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)

/// 创建 actionsheet 实例
let actionsheet = UDActionSheet(config: config)
/// 为 actionsheet 添加操作项
actionsheet.setTitle("这里是对选项的描述")
/// 为 actionsheet 添加操作项
actionsheet.addDefaultItem(text: "选项一")
actionsheet.addDefaultItem(text: "选项二")
actionsheet.addDefaultItem(text: "选项三")
actionsheet.addDefaultItem(text: "选项四")
actionsheet.setCancelItem(text: "取消")

/// 弹出 actionSheet
vc.present(actionsheet, animated: true)
```

:::

## 设置操作表标题

本组件提供了两种方式启用操作表标题：

1. 初始化[`UDActionSheetUIConfig`](#udactionsheetuiconfig)时传入`isShowTitle = true`作为参数来启用标题
2. 通过设置`config.isShowTitle = true`来启用标题

随后，便可以通过[`UDActionSheet`](#udactionsheet)的[`setTitle()`](#settitle)方法来设置操作表标题。

```swift
///创建面板配置
let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
/// 创建 actionsheet 实例
let actionsheet = UDActionSheet(config: config)
/// 为 actionsheet 添加操作项
actionsheet.setTitle("操作表标题")
actionsheet.addDefaultItem(text: "选项一")
actionsheet.addDefaultItem(text: "选项二")
actionsheet.addDefaultItem(text: "选项三")
actionsheet.setCancelItem(text: "取消")

/// 弹出 actionSheet
vc.present(actionsheet, animated: true)
```

## 设置操作表在 iPad 上的样式

默认采取 popover 的样式。

同样，你可以通过初始化时设置 config 的 style 来实现不同样式的控制。

```swift
// iPhone、iPad 上样式一致
var normalConfig = UDActionSheetUIConfig(style: .normal)
// iPhone 默认样式、iPad 为 alert 弹窗样式
var alertConfig = UDActionSheetUIConfig(style: .autoAlert)
// iPhone 默认样式、iPad 为 popover 样式
var popoverConfig = UDActionSheetUIConfig(style: .autoPopover(popSource: source))
```

## 设置预设操作表选项样式

本组件共提供了 4 种预设操作选项样式，来实现不同业务场景的需求。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "384"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDActionPanel/ActionSheetsAllLight.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDActionPanel/ActionSheetsAllDark.png"
/>

```swift
actionsheet.addDefaultItem(text: "默认选项类型")
actionsheet.addDestructiveItem(text: "警告操作类型")
actionsheet.setRedCancelItem(text: "警告取消类型")
actionsheet.setCancelItem(text: "默认取消类型")
```

:::

## 设置自定义的操作表选项样式

本组件提供了自定义操作选项文字颜色等功能供使用方自行设计。

你可以在[`UDActionSheetItem`](#udactionsheetitem)初始化时传入`style`控制该选项的类型。

```swift
let customItem = UDActionSheetItem(title: "自定义选项", titleColor: .black, style: .default, isEnable: true, action: nil)
actionsheet.addItem(customItem)
```

## 活动视图

活动视图是承载当前场景下更多不同属性的操作项面板，内容选项超过半屏建议选用，且可以使用图标 + 文字的展现形式。图标要能表现出操作的意义，文案要尽量简短明确。活动视图作为容器，允许添加任意视图。

```swift
let vc = UIViewController()
let panel = UDActionPanel(customViewController: vc, config: UDActionPanelUIConfig())
```

## API 及配置列表

### UDActionSheetSource

操作表在 popover 下的弹出时所需的物料，在本组件中属于必传参数。

<SiteTableHighlight columns="3" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
sourceView<SiteTableRequired /> | 指向哪个视图 | UIView | -
sourceRect<SiteTableRequired /> | 箭头指向视图范围 | CGRect | -
preferredContentWidth| 宽度 | CGFloat | 180
arrowDirection | 箭头方向 | UIPopoverArrowDirection | .unknown

### UDActionSheetUIConfig

从坐标初始化时需要传入的参数，用于配置[`UDActionSheet`](#udactionsheet)的外观。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
style|ActionSheet 在 iPad 上的样式 | Style | .autoPopover
titleColor| 标题颜色 | UIColor |UDColor.textPlaceholder
isShowTitle| 是否显示标题 | Bool |false
backgroundColor| ActionSheet 背景颜色 | UIColor |UDColor.bgBody
popSource<SiteTableRequired />| ActionSheet 在 iPad 上 popover 的物料 | [UDActionSheetSource](#udaction) | -
cornerRadius| Actionsheet 圆角大小 | CGFloat | 12
dismissedByTapOutside| 点击外部关闭的回调函数 | (() -> Void) | nil

上述参数，在初始化完 config 后，仍可以属性的方式进行访问。

### UDActionSheetItem

操作表单个选项构造函数。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
title<SiteTableRequired />| 操作选项标题 | String | -
titleColor | 标题颜色 | UIColor | nil
style| 操作选项类型 | Style | .default
isEnable| 是否禁用 | Bool | true
action| 点击事件 | () -> Void) | nil

### UDActionSheet

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
config<SiteTableRequired />| ActionSheet 外观配置 | [UDActionSheetUIConfig](#udactionsheetuiconfig) | -

### UDActionSheet 接口

#### setTitle

当`isShowTitle==true`时，设置操作表标题文字。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
title<SiteTableRequired />| UDActionSheet 标题 | String | -

#### addItem

通用方法，为操作表添加选项。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
item<SiteTableRequired />| 一个 UDActionSheet 选项 | [UDActionSheetItem](#udactionsheetitem) | -

#### addDefaultItem

为操作表添加预设默认操作选项。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
item<SiteTableRequired />| 一个 UDActionSheet 选项 | [UDActionSheetItem](#udactionsheetitem) | -
action| 选项点击事件回调 | () -> Void) | nil

#### addDestructiveItem

为操作表添加预设警告操作选项。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
item<SiteTableRequired />| 一个 UDActionSheet 选项 | [UDActionSheetItem](#udactionsheetitem) | -
action| 选项点击事件回调 | () -> Void) | nil

#### setRedCancelItem

为操作表添加预设警告取消操作选项。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
item<SiteTableRequired />| 一个 UDActionSheet 选项 | [UDActionSheetItem](#udactionsheetitem) | -
action| 选项点击事件回调 | () -> Void) | nil

#### setCancelItem

为操作表添加预设默认取消操作选项。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
item<SiteTableRequired />| 一个 UDActionSheet 选项 | [UDActionSheetItem](#udactionsheetitem) | -
action| 选项点击事件回调 | () -> Void) | nil

#### removeAllItem

为操作表移除全部按钮。

### UDActionPanelUIConfig

活动面板初始化时需要传入的参数，用于配置[`UDActionPanel`](#udactionpanel)的外观。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
originY| 起始高度 |CGFloat|UIScreen.main.bounds.height * 0.4
useVelocity| 是否使用阻尼 |Bool|false
damp| 阻尼大小 |CGFloat|4
showMiddleState| 是否支持展示半屏（一半高度）|Bool|true
canBeDragged| 能否拖拽 |Bool|true
backgrounColor|ActionPanel 背景色 |UDActionPanelColorTheme|acPrimaryBgNormalColor
startDrag| 开始拖拽回调 |(() -> Void) |-
dismissByDrag| 拖拽`dismiss`的回调 |(() -> Void) |-
disablePanGestureViews| 点击视图无法触发点击手势 |(() -> [UIView]) |-

### UDActionPanel

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
customViewController<SiteTableRequired />| ActionPanel 内部自定义内容 | UIViewController | -
config<SiteTableRequired />| ActionPanel 外观配置 | [UDActionPanelUIConfig](#udactionpaneluiconfig) | -

### UDActionPanel 接口

#### resetPosition

重置位置。

#### resetMiddlePosition

重置至中间位置。

#### setTapSwitch

点击手势是否可被触发。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
isEnable<SiteTableRequired />| 是否可触发 | Bool | -

### UDActionPanelColor 主题化

<SiteTableHighlight columns="4" type="3" />

变量名 |Key| 默认值
---|---|---
acPrimaryBgNormalColor|ac-primary-bg-normal-color|UDColor.neutralColor1
acPrimaryIconNormalColor|ac-primary-icon-normal-color|UDColor.neutralColor5
acPrimaryMaskNormalColor|ac-primary-mask-normal-color|UDColor.neutralColor12.withAlphaComponent(0.4)
asPrimaryTitleNormalColor|as-primary-title-normal-color|UDColor.neutralColor7
asPrimaryBgNormalColor|as-primary-bg-normal-color|UDColor.neutralColor1
asPrimaryBtnNormalColor|as-primary-btn-normal-color|UDColor.neutralColor12
asPrimaryBtnErrorColor|as-primary-btn-error-colorr|UDColor.alertColor6
asPrimaryBtnCancleColor|as-primary-btn-cancle-color|UDColor.neutralColor12
asPrimaryLineNormalColor|as-primary-line-normal-color|UDColor.neutralColor12.withAlphaComponent(0.15)
