# 消息卡片 Card Header

## 简介

消息卡片头提供了统一的 App 内消息卡片的头部样式。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignCardHeader'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignCardHeader
```

## 创建预设颜色组合的消息卡片

::: showcase collapse=false
<SiteImage
    width = "100"
    height = "60"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDCardHeader/cardheader_bg.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDCardHeader/cardHeader_bg_Dark.png"
    />

```swift
let cardHeader = UDCardHeader(colorHue: .blue)
```

:::

## 创建自定义颜色组合的消息卡片

```swift
let cardHeader = UDCardHeader(color: UIColor.red, textColor: UIColor.yellow)
```

## API 及配置列表

### UDCardHeader

消息卡片面板实例。

#### 预设初始化

<SiteTableHighlight columns="3" type="3" />

参数 | 类型 | 说明
---|---|---
colorHue | [UDCardHeaderHue](#udcardheaderhue) | 预设颜色主题
layoutType | UDCardLayoutType | 消息卡片布局

#### 自定义初始化

<SiteTableHighlight columns="3" type="3" />

参数 | 类型 | 说明
---|---|---
color | UIColor | 背景颜色
textColor| UIColor | 文本颜色
layoutType | UDCardLayoutType | 消息卡片布局

#### 属性

<SiteTableHighlight columns="3" type="3" />

属性名 | 类型 | 说明
---|---|---
colorHue | [UDCardHeaderHue](#udcardheaderhue) | 当前消息卡片颜色组合
colorHue.color | UIColor | 当前消息卡片背景颜色
colorHue.textColor | UIColor | 当前消息卡片文字颜色

### UDCardHeaderHue

组件内置颜色组合。

组件提供了如下预设值：

枚举值 | 背景颜色 | 文字图标颜色
---|---|---
.blue | B100 & B50 | B600 & B600
.wathet | W100 & W50 | W700 & W600
.turquoise | T100 & T50 | T700 & T600
.green | G100 & G50 | G700 & G600
.lime | L100 & L50 | L700 & L600
.yellow | Y100 & Y50 | Y700 & Y600
.orange | O100 & O50 | O600 & O600
.red | R100 & R50 | R600 & R600
.carmine | C100 & C50 | C600 & C600
.violet | V100 & V50 | V600 & V600
.purple | P100 & P50 | P600 & P600
.indigo | I100 & I50 | I600 & I600
.enural | N500 & N300 | N00 & N600
