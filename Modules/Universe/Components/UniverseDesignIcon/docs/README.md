# 图标 Icon

## 简介

系统图标是指具有明确指代含义的图形符号，是常用操作、文件、设备、目录等功能的图形化表现形式，用于触发界面中的局部操作，是界面设计中的重要组成部分。

通用图标组件提供了目前 ESUX 的图标库，并且可根据自己需求改变图标大小。

## 安装

### 使用 CocoaPods 安装

添加至你的`Podfile`:

```bash
pod 'UniverseDesignIcon'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignIcon
```

## 获取图片

组件共提供了三种方式获取图片的方式：

::: showcase collapse=false
<SiteImage
    width = "40"
    height = "40"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDNotice/larkcommunityColorful.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDNotice/larkcommunityColorful.png"
/>

```swift
/// 通过静态方法直接访问获取
var icon1 = UDIcon.larkcommunityColorful
/// 通过 getIconByKey() 方法获取默认宽高 24 的图片
var icon2 = UDIcon.getIconByKey(.larkcommunityColorful)
/// 通过 getIconByKeyNoLimitSize() 方法获取原始大小图片
var icon3 = UDIcon.getIconByKeyNoLimitSize(.larkcommunityColorful)
```

:::

组件内置`getIconByKey()`方法可以设置获取 icon 的 size、color、renderingMode 属性。

组件内置`getIconByKeyNoLimitSize()`方法可以设置获取 icon 的 color、renderingMode 属性。

## 为非彩色图标染色

通过设定`getIconByKey()`、`getIconByKeyNoLimitSize()`的`iconColor`参数来为获取的图标进行染色。

下面展示了为图标使用 UDColor 染色为适应`DarkMode` / `LightMode`的图片：

::: showcase collapse=false
<SiteImage
    width = "40"
    height = "40"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDIcon/Union.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDIcon/Union_dm.png"
/>

```swift
var icon1 = UDIcon.getIconByKey(.imageOutlined, iconColor: UIColor.ud.iconN1)
var icon2 = UDIcon.getIconByKeyNoLimitSize(.larkcommunityColorful, iconColor: UIColor.ud.iconN1)
```

:::

## 获取 Context Menu 图标

由于`Context Menu`的图标大小比较特殊，`UDIcon`还提供了专为`Context Menu`适配大小的图标：

```swift
let contextMenuIcon = UDIcon.getContextMenuIconBy(key: .back)
```
