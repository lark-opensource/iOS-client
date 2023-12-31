# 徽标 Badge

## 简介

徽标包含点状徽标、字符徽标、图标徽标都等，并且有灵活的配置能力，可广泛使用于各种常驻提示性场景中。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignBadge'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignBadge
```

## 点状徽标

::: showcase collapse=false
<SiteImage
    width = "72"
    height = "72"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/badge/ud_badge_dot.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/badge/ud_badge_dot_dm.png"
/>

```swift
let badge = UDBadge(config: .dot)
badge.config.dotSize = .small
```

```swift
let smallSize = UDBadgeDotSize.small.size
let offsetX = (smallSize.width / 2.0) + 2.0
let badge = myLabel.addBadge(.dot, anchor: .topRight, anchorType: .rectangle, offset: CGSize(width: offsetX, height: 0.0))
```

:::

## 字符徽标

::: showcase collapse=false
<SiteImage
    width = "72"
    height = "72"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/badge/ud_badge_text.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/badge/ud_badge_text_dm.png"
/>

```swift
let badge = UDBadge(config: .number)
badge.config.number = 99
badge.config.maxNumber = 999
```

```swift
let badge = view.addBadge(.number, anchor: .topRight, anchorType: .circle)
badge.style = .red
badge.anchorExtendType = .leading
badge.contentStyle = .white
```

:::

## 图标徽标

::: showcase collapse=false
<SiteImage
    width = "72"
    height = "72"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/badge/ud_badge_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/badge/ud_badge_icon_dm.png"
/>

```swift
let icon = UDIcon.getIconByKey(.alarmOutlined, iconColor: .white, size: CGSize(width: 10.0, height: 10.0)
let badge = avatar.addBadge(.icon, anchor: .bottomRight, anchorType: .circle)
badge.config.icon = icon
badge.config.style = .dotBGRed
badge.config.contentStyle = .white
```

:::

## 自定义配置

所有的预定义样式及自定义能力，均可以通过 config 配置，详见 [API 配置列表](#api-及配置列表)。

## API 及配置列表

### UDBadge

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
config| 徽标外观的配置项，自定义调整后影响 UI 显示 | [UDBadgeConfig](#udbadgeconfig) | -

### UDBadgeConfig

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
defaultMaxNumber| 默认的数字徽标全局最大值，数字徽标默认使用此变量，可自定义 |Int|99
type| 徽标类型，默认为点状徽标 |[UDBadgeType](#udbadgetype)|dot
style| 徽标颜色，默认为红色样式，支持默认样式切换，也支持自定义颜色 | [UDBadgeColorStyle](#udbadgecolorstyle)|red
border| 徽标描边，默认为 none，支持内描边与外描边 |[UDBadgeBorder](#udbadgeborder)|none
borderStyle| 描边颜色，默认为 clear|[UDBadgeColorStyle](#udbadgecolorstyle)|custom(.clear)
dotSize| 点状徽标尺寸 |[UDBadgeDotSize](#udbadgedotsize)|middle
anchor| 徽标中心在父视图的锚点 |[UDBadgeAnchor](#udbadgeanchor)|topRight
anchorType| 徽标锚点类型 |[UDBadgeAnchorType](#udbadgeanchortype)|none
anchorExtendType| 徽标锚点大尺寸下的扩展方向 |[UDBadgeAnchorExtendType](#udbadgeanchorextendtype)|leading
anchorOffset| 徽标锚点偏移量 |CGSize|zero
text| 字符徽标内容 |String|""
showEmpty| 字符徽标为空时，是否显示 |Bool|false
number| 数字徽标内容 |Int|0
showZero| 数字徽标为 0 时，是否显示 |Bool|false
maxNumber| 数字徽标最大显示数字 |Int|defaultMaxNumber
maxType| 数字徽标超出最大数字时显示类型 |UDBadgeMaxType|ellipsis
contentStyle| 徽标内容显示颜色样式 |[UDBadgeColorStyle](#udbadgecolorstyle)|white
icon| 图标徽标 icon 内容 |[ImageSource](#imagesource)|nil
dot| 默认的点状徽标样式 |[UDBadgeConfig](#udbadgeconfig)|[type: .dot, style: .dotBGRed, dotSize: .middle]
text| 默认的字符徽标 |[UDBadgeConfig](#udbadgeconfig)|[type: .text, style: .characterBGRed, text: "", showEmpty: false, contentStyle: .dotCharacterText]
number| 默认的数字徽标 |[UDBadgeConfig](#udbadgeconfig)|[type: .number, style: .characterBGRed, number: 0, showZero: false, maxNumber: Self.defaultMaxNumber, maxType: .ellipsis, contentStyle: .dotCharacterText]
icon| 默认的图标徽标 |[UDBadgeConfig](#udbadgeconfig)|[type: .icon, style: .dotBGRed, icon: nil]

### UDBadgeType

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
dot| 点状徽标
text| 字符徽标
number| 数字徽标
icon| 图标徽标

### UDBadgeDotSize

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
large| 大尺寸的点状徽标 (10 x 10)
middle| 中尺寸的点状徽标 (8 x 8)
small| 小尺寸的点状徽标 (6 x 6)

### UDBadgeColorStyle

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
dotBGRed|@badge-dot-bg-red-color: @alert-color-6
dotBGGrey|@badge-dot-bg-grey-color: @neutral-color-6
dotBGBlue|@badge-dot-bg-blue-color: @primary-color-4
dotBGGreen|@badge-dot-bg-green-color: @T600
characterBGRed|@badge-character-bg-red-color: @alert-color-6
characterBGGrey|@badge-character-bg-grey-color: @neutral-color-6
dotBorderWhite|@badge-dot-border-white-color: @neutral-color-1
dotCharacterText|@badge-dot-character-text-color: @neutral-color-1
dotCharacterLimitIcon|@badge-dot-characterlimit-icon-color: @neutral-color-1
dotBorderDarkgrey|@badge-dot-border-darkgrey-color: @neutral-color-8
custom(UIColor)| 自定义颜色

### UDBadgeBorder

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
none| 无描边
outer| 外描边 2 px
inner| 内描边 1 px

### UDBadgeAnchor

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
topLeft| 左上角锚点
topRight| 右上角锚点
bottomLeft| 左下角锚点
bottomRight| 右下角锚点

### UDBadgeAnchorType

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
none| 普通父视图，无锚点类型
circle| 圆形父视图锚点
rectangle| 矩形父视图锚点

### UDBadgeAnchorExtendType

<SiteTableHighlight columns="2" type="2" />

枚举值 | 说明
---|---
leading| 内容扩展方向为 leading
trailing| 内容扩展方向为 trailing

### ImageSource

<SiteTableHighlight columns="3" type="3" />

参数名 | 类型 | 说明
--- | --- | ---
placeHolderImage | UIImage | 图标徽标加载中的占位图
image | UIImage | 图标徽标显示图片
