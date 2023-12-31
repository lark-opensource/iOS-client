# 临时提示 Toast

## 简介

临时提示是一种轻量级的操作反馈或提示组件，用来展示不中断用户操作的信息内容。临时提示会显示在屏幕居中并自动消失，不中断用户体验。临时提示是一种非模态弹窗，是非模态反馈中的一种。它在很多场景，可取代恼人的模态对话框提示。

组件不仅实现了常用的 Toast 提示 API，例如普通文本信息，成功信息，失败信息和警告信息等，还实现了可操作临时提示 Toast API。这种类型的 Toast 可以响应用户的点击操作。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignToast'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignToast
```

## 常规 Toast

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_success.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_success_dm.png"
/>

```swift
UDToast.showTips(with: "临时提示", on: self.view)
```

:::

## 失败提示的常规 Toast

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_fail_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_fail_icon_dm.png"
/>

```swift
UDToast.showFailure(with: "失败提示", on: self.view)
```

:::

## 成功提示的常规 Toast

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_success_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_success_icon_dm.png"
/>

```swift
UDToast.showSuccess(with: "成功提示", on: self.view)
```

:::

## 警示提示的常规 Toast

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_warn_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_warn_icon_dm.png"
/>

```swift
UDToast.showWarning(with: "警示提示", on: self.view)
```

:::

## 加载提示的常规 Toast

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_loading_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_loading_icon_dm.png"
/>

```swift
UDToast.showLoading(with: "加载中", on: self.view)
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    UDToast.removeToast(on: self.view)
}
```

:::

## 可点击操作的 Toast

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "70"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_operate_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/Toast_operate_icon_dm.png"
/>

```swift
UDToast.showTips(with: "提示文本内容", operationText: "操作",on: self.view, operationCallBack: { (str) in
    print("点击了\(str)")
})
```

:::

## 位于屏幕中心的常规 Toast

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "812"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/simulator_screenshot_CC043EA8-FFC0-46BE-9664-E06562F0A4CA.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/simulator_screenshot_DAEEDD27-12F6-45EC-A5B6-29BC6668B08B.png"
/>

```swift
UDToast.showTipsOnScreenCenter(with: "屏幕中央提示", on: self.view)
```

:::

**成功、失败、警告、加载同理，均可传入`operationText`、`operationCallBack`两个参数实现对提示文字和点击回调的配制。**

## 自定义的 Toast

组件提供了[`UDToastConfig`](#udtoastconfig)作为 UI 配置项，其主要包括：

1. Toast 显示的提示内容 text。
2. 左侧显示图片的类型，可以是常规类型`info`，加载类型`loading`，成功类型`success`，错误类型`error`。
3. 如果要使用 Toast 右侧的操作按钮功能，则需要提供[`UDToastOperationConfig`](#udtoastoperationconfig)配置。可以在这个配置中，设置按钮的文字 text，以及显示方式[`UDOperationDisplayType`](#udoperationdisplaytype)，横排还是竖排显示。

组件会根据 config 中的配置进行布局展示相关元素。

下面展示了一个纵向排列、错误类型、持续 3s 的 Toast：

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "812"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/simulator_screenshot_A710CE85-68D8-40C9-BEF0-74160C00FF10.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/simulator_screenshot_94BD75BA-9519-4F29-94CC-064D1410B327.png"
/>

```swift
let operation = UDToastOperationConfig(text: "OK", displayType: .vertical)
let config = UDToastConfig(toastType: .error, text: "纵向排列的 Toast", operation: operation)
UDToast.showToast(with: config, on: self.view, delay: 3, operationCallBack: {
    print("click OK")
})
```

:::

配置 config 只能在`UDToast`的[`showToast`](#showtoast)方法中传入，无法更改。

## 设定 Toast 到底部的距离

本组件支持链式语法，可直接在弹出的函数后设置距离。

::: showcase collapse=false
<SiteImage
    width = "375"
    height = "812"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/simulator_screenshot_B102DACD-145D-40D5-A7BA-D65CF618F691.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDToast/simulator_screenshot_5B1D0CEF-A8F3-47B3-BC42-7C7BC39A5F87.png"
/>

```swift
UDToast.showTips(with: "很高的 Toast", on: self.view).setCustomBottomMargin(300)
```

:::

## API 及配置列表

### UDToastConfig

定制偏向自定义效果的 UDToast 所需要传入的配置。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
toastType<SiteTableRequired />| - |Toast 类型，可以是 info，loading，success，warning 或 error
text<SiteTableRequired />| - |Toast 提示文本
operation|nil|Toast 右侧操作按钮的配置
delay|3.0|Toast 持续时间

### UDToastOperationConfig

用于定制 UDToast 操作方面的布局、文本等。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
text<SiteTableRequired />| - | 操作按钮显示的文本
displayType|nil| 操作显示的类型

### UDOperationDisplayType

自定义 UDToast 样式时，操作项的布局枚举。

<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
horizontal| 横式布局
vertical| 竖式布局

### UDToast 接口

#### showToast

弹出通过 config 设置的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 配置 |UDToastConfig| -
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| -
delay|Toast 持续时间 |TimeInterval|3.0
disableUserInteraction|Toast 显示时，当前视图界面是否不再与用户交互 |Bool|false
operationCallBack|Toast 操作的回调 |(String?) -> Void)?|nil

#### showLoading

弹出加载类型的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 配置 |UDToastConfig| -
operationText|Toast 操作显示的文本 |String|nil
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| -
delay|Toast 持续时间 |TimeInterval|3.0
disableUserInteraction|Toast 显示时，当前视图界面是否不再与用户交互 |Bool|false
operationCallBack|Toast 操作的回调 |(String?) -> Void)?|nil

#### showTips

弹出常规类型的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 显示的文本 |String| -
operationText|Toast 操作显示的文本 |String|nil
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| -
delay|Toast 持续时间 |TimeInterval|3.0
operationCallBack|Toast 操作的回调 |(String?) -> Void)?|nil

#### showFailure

弹出失败类型的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 显示的文本 |String| - 
operationText|Toast 操作显示的文本 |String|nil
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| - 
delay|Toast 持续时间 |TimeInterval|3.0
operationCallBack|Toast 操作的回调 |(String?) -> Void)?|nil

#### showSuccess

弹出成功类型的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 显示的文本 |String| -
operationText|Toast 操作显示的文本 |String|nil
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| -
delay|Toast 持续时间 |TimeInterval|3.0
operationCallBack|Toast 操作的回调 |(String?) -> Void)?|nil

#### showWarning

弹出警告类型的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 显示的文本 |String| -
operationText|Toast 操作显示的文本 |String|nil
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| -
delay|TimeInterval|3.0|Toast 持续时间
operationCallBack|Toast 操作的回调 |(String?) -> Void)?|nil

### showTipsOnScreenCenter

弹出位于屏幕中间的 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
with<SiteTableRequired />|Toast 显示的文本 |String| -
on<SiteTableRequired />|Toast 将要显示在哪个视图上 |UIView| -
delay|Toast 持续时间 |TimeInterval|3.0

#### removeToast

从 view 中移除 Toast。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
view|Toast 所在的 view|UIView| -

#### setCustomBottomMargin

设置 Toast 到屏幕底部的距离。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
margin<SiteTableRequired /> | Toast 要显示在 view 上，横向居中显示，纵向的举例可以通过 margin 设置 | CGFloat | -
view|Toast 所在的 view|UIView|topView
