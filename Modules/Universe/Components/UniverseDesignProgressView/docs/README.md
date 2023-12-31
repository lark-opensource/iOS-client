# 进度条 Progress

## 简介

进度条组件为用户显示该操作的当前进度和状态，例如加载应用程序，提交表单或保存更新等。有线性和圆形两种类型。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignProgressView'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignProgressView
```

## 线性进度条

组件默认实现为线性进度条，可直接调用。

::: showcase collapse=false
<SiteImage
    width = "268"
    height = "18"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/progress/ud_progress_linear.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/progress/ud_progress_linear_dm.png"
/>

```swift
var procressView = UDProgressView()
```

:::

## 环形进度条

组件可通过配置[`UDProgressViewUIConfig`](#udprogressviewuiconfig)的`type`参数来控制显示的类型。

::: showcase collapse=false
<SiteImage
    width = "18"
    height = "18"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/progress/ud_progress_circular.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/progress/ud_progress_circular_dm.png"
/>

```swift
var config = UDProgressViewUIConfig(type: .circular)
var procressView = UDProgressView(config: config)
```

:::

## 更新进度条长度

组件提供[`setProgress`](#setprogress)方法来更新进度条长度，更新进度值 0 - 1。

```swift
var procressView = UDProgressView()
procressView.setProgress(0.5, animated: true)
```

## 监听进度条长度变化

组件提供[`observedProgress`](#observedprogress)监听进度。

## 加载失败状态

进度加载失败，用于显示失败时，指示器颜色。

```swift
procressView.setProgressLoadFailed()
```

## API 及配置列表

### UDProgressViewThemeColor

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
textColor| 进度值颜色 |UIColor| UDColor.N500
bgColor| 轨道颜色 |UIColor| UDColor.N300
indicatorColor| 进度值指示器颜色 |UIColor| UDColor.B500
successIndicatorColor| 进度加载成功颜色 |UIColor| UDColor.G500
errorIndicatorColor| 进度加载失败颜色 |UIColor| UDColor.R500

### UDProgressViewType

进度条类型枚举。

<SiteTableHighlight columns="2" type="3" />

枚举值 | 说明
---|---
linear| 线性进度条
circular| 环形进度条

### UDProgressViewLayoutDirection

进度条布局方向枚举。

<SiteTableHighlight columns="2" type="3" />

属性值 | 说明
---|---
horizontal| 水平布局
vertical| 垂直布局

#### UDProgressViewUIConfig

进度条外观 UI 配置。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
type|UDProgressViewType.linear| 线性还是环形
barMetrics|UDProgressViewBarMetrics.defult| 进度条粗细大小
layoutDirection|.horizontal| 布局方向
themeColor|ThemeColor()| 颜色配置
showValue|false| 是否显示进度值

### UDProgressView 接口

### setProgress

更新进度值。

<SiteTableHighlight columns="3" type="3" />

参数名 | 默认值 | 说明
---|---|---
progress<SiteTableRequired />| - | 将要设定的数值
animated<SiteTableRequired />| - | 是否展示动画

### observedProgress

监听进度值。

### setProgressLoadFailed

设置加载失败状态。
