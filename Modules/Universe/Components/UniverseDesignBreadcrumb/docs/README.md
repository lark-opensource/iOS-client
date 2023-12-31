# 面包屑 Breadcrumb

## 简介

面包屑是用户界面中的一种辅助导航，可以显示当前页面在层级架构中的位置，并能快速返回之前的页面。

组件提供了简单的方式快速生成面包屑视图，并且可配置化较高。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignBreadcrumb'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignBreadcrumb
```

## 面包屑

当页面层级很深，需要快速来回切换时使用，如用选人组件 / 查看组织架构。超出区域的会自动向左滚动，可滑动查查看超出屏幕区域部分。

::: showcase collapse=false
<SiteImage
    height = "40"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDBread/UDBread.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDBread/UDBread_dm.png"
    />

```swift
let breadcrumbView = UDBreadcrumb()
let titles = ["Home", "Project n-1", "Project n"]
breadcrumbView.setItems(titles)
/// 对应 Item 的点击事件
breadcrumbView.tapCallback = { [weak self] (index) in
    if index == 0 {
        self?.navigationController?.pushViewController(VC1(), animated: true)
    } else if index == 1 {
        self?.navigationController?.pushViewController(VC2(), animated: true)
    } else {
        self?.navigationController?.pushViewController(VC3(), animated: true)
    }    
}
```

:::

## 操作面包屑

组件提供了定制化较高的 Theme 方案及 config，用户可根据自身需求定制相应的字体、图标颜色等。同时也能灵活添加移除 Item。

```swift
breadcrumbView.addItems(["新 Item"])              // 添加新 Item
breadcrumbView.removeLast(count: 2)              // 移除最后两个 Item
breadcrumbView.setItems(["Home", "Project n-1", "Project n"])  // 重置面包屑选项
```

## 自定义面包屑

组件提供了界面可定制的部分，可以通过[`UDBreadcrumbUIConfig`](#udbreadcrumbuiconfig)相应属性的默认值，用户可根据自身需求定制对应的 config，设置相应的字体、图标颜色。

在组件初始化时传入相应的 config 即可生效。

```swift
let config = UDBreadcrumbUIConfig(navigationTextColor: UDColor.B700)
let breadcrumb = UDBreadcrumb(config: config)
```

## API 及配置列表

### UDBreadcrumbUIConfig

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
backgroundColor| 面包屑默认背景色 | UIColor | UIColor.clear
navigationTextColor | 前置导航文本颜色 | UIColor | breadcrumbNavigationTextColor
currentTextColor | 当前 item 颜色 | UIColor | breadcrumbCurrentTextColor
iconColor | icon 颜色 | UIColor | breadcrumbIconColor
textFont | 文本字体 | UIColor | body
itemCornerRadius | item 圆角 | CGFloat | smallRadius
itemBackgroundColor | item 默认背景色 | UIColor | clear
itemHightedBackgroundColor | item 高亮背景色 | UIColor | breadcrumbItemHightedBackgroundColor
showAddAnimated | 是否展示动画 | Bool | false

### UDBreadcrumb

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
config | 面包屑 UI 配置 | [UDBreadcrumbUIConfig](#udbreadcrumbuiconfig) | UDBreadcrumbUIConfig()

### UDBreadcrumb 接口

#### scrollToRight

滚动到最后，即最右侧。

#### didTapItem

点击相应的 item。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
index<SiteTableRequired />| 被点击的 item 索引 | Int | -

#### setItems

设置 items。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
items<SiteTableRequired /> | 设置的 items | [String] | -

#### addItems

设置 items。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
items<SiteTableRequired />| 添加的 items | [String] | -

#### removeLast

从后往前移除 n 个 item。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
count<SiteTableRequired />| 移除的个数 | Int | 1

#### removeTo

移除到第 i 个 item。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
index<SiteTableRequired />| 截止的 item 索引 | Int | -

#### removeItems

移除全部 item。

### UDBreadcrumbColor

<SiteTableHighlight columns="3" type="3" />

变量名 |Key| 默认值
:--|:--|:--
breadcrumbNavigationTextColor|breadcrumb-navigation-text-color|UDColor.N500
breadcrumbCurrentTextColor|breadcrumb-current-text-color|UDColor.B500
breadcrumbIconColor|breadcrumb-icon-color|UDColor.N500
breadcrumbItemHightedBackgroundColor|breadcrumb-item-backgroundColor-highted-color|UDColor.B500.withAlphaComponent(0.1)
