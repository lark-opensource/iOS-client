# 标签 Tag

## 简介

标签是对事物进行标记和分类的组件。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignTag'
```

接着，执行以下命令：

```bash
pod install
```

### 引入

引入组件：

#### Swift

```swift
import UniverseDesignTag
```
## 样式配置
### 文本标签



::: showcase collapse=false
<SiteImage
    width = "56"
    height = "42"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tag/ud_tag_text.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tag/ud_tag_text_dm.png"
    />

```swift
var tag = UDTag(withText: "标签" )

tag.snp.makeConstraints { (make) in
  make.center.equalToSuperview()
}
```

:::

### 图片标签


::: showcase collapse=false
<SiteImage
    width = "42"
    height = "42"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tag/ud_tag_icon.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/tag/ud_tag_icon_dm.png"
    />

```swift
var tag = UDTag(withIcon: UDIcon.emojiFilled)

tag.snp.makeConstraints { (make) in
  make.center.equalToSuperview()
}
```


:::
### 图片 + 文本标签

::: showcase collapse=false
<SiteImage
    width = "42"
    height = "42"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_iconText_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_iconText_d.png"
    />

```swift
var tag = UDTag(withIcon: UDIcon.emojiFilled , text: "标签")

tag.snp.makeConstraints { (make) in
  make.center.equalToSuperview()
}
```
:::
## 颜色配置
默认根据色板提供 12 种标签配色。标签颜色所代表的具体含义由业务线拟定。
::: showcase collapse=false
<SiteImage
    width = "142"
    height = "80"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_color_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_color_d.png"
    />

```swift
var tag = UDTag(withIcon: UDIcon.emojiFilled , text: "标签")
tag.colorScheme = .red
```
:::
## 尺寸配置
属性标签默认提供四种尺寸。

超小尺寸：容器-18px，字体 -12px regular，icon 12px

小尺寸：容器-24px，字体 -14px regular，icon 14px

中尺寸：容器-28px，字体 -16px regular，icon 16px

大尺寸：容器-32px，字体 -17px regualr，icon 18px

::: showcase collapse=false
<SiteImage
    width = "142"
    height = "82"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_sizeClass_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_sizeClass_d.png"
    />
```swift
var tag = UDTag(withIcon: UDIcon.emojiFilled , text: "标签")
tag.sizeClass = .mini
tag.sizeClass = .small
tag.sizeClass = .medium
tag.sizeClass = .large
```
:::
## 透明度配置
每一种颜色可配置透明和不透明的标签底色。常规情况下使用带有透明度的底色。在背景为非常规界面的情况下（如非 bg，hover 等常规背景）可以使用不透明的标签底色。
::: showcase collapse=false
<SiteImage
    width = "142"
    height = "82"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_opacity_l.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/fvqeh7uhypfvbn/UDResource/UDTag/tag_opacity_d.png"
    />

```swift
var tag = UDTag(withIcon: UDIcon.emojiFilled , text: "标签")
tag.isOpaque = true
```
:::
## 更新标签文字 / 图标

组件根据内容类型，提供了`text`、`icon`两个属性供你使用，来进行标签内容的更新。

```swift
/// 初始化默认文本标签
let labelTag = UDTag(withText: "旧标签文字")
labelTag.text = "新标签文字"


/// 初始化默认 icon 标签
let iconTag = UDTag(withIcon: oldIcon)
iconTag.icon = newIcon
```

## 更新标签配置

组件提供[`updateConfiguration`](#updateconfiguration()) 方法来更改标签的 UI 属性。

```swift
tag.updateConfiguration(someConfig)

```

## API 及配置列表

### UDTag.Configuration
说明：以下属性均为 public internal(set)，只能用[`静态工厂方法`](#icon()) 初始化一个 Configuration。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
---|---|---|---
text | 设置标签文本 | String？ | nil
icon | 设置标签 icon | UIImage？|  nil
height | 标签高度 | Int | 18
fontSize | 标签字体大小 | CGFloat | 0
font | 标签字体 | UIFont | systemFont(ofSize: fontSize)
cornerRadius | 标签圆角 | CGFloat | UDStyle.smallRadius
textAlignment | 标签文本格式 | NSTextAlignment | center
textColor | 标题内容颜色 | UIColor | tagForegroundColor
backgroundColor | 标签背景颜色 | UIColor | tagBackgroundColor
iconColor | 图标颜色 | UIColor?| nil
iconSize | 图标大小 | CGSize| CGSize(width: 0, height: 0)
iconTextSpacing | 图标文本间距 | CGFloat| 0
horizontalMargin | 水平白边 | CGFloat| 0

### UDtag 属性

属性 | 类型 | 说明
---|---|---
text | String？ | 设置标签文本
icon | UIImage？ | 设置标签 icon
sizeClass|Size|设置标签大小
colorScheme|ColorScheme|设置标签颜色
isOpaque|Bool|设置标签透明度

### UDTag 接口

#### updateConfiguration()
接收传入的配置，并更新 UI。
参数名 | 类型 | 说明
---|---|---
Configuration|UDTag.Configuration|tag 配置

### UDTag.Configuration 接口
#### icon()
根据传入的参数生成一个 icon 类型的配置
参数名 | 类型 | 说明
---|---|---
icon|UIImage|设置标签 icon
tagSize|Size|设置标签大小
colorScheme|ColorScheme|设置标签颜色
isOpaque|Bool|设置标签透明度

#### text()
根据传入的参数生成一个 text 类型的配置
参数名 | 类型 | 说明
---|---|---
text|String|设置标签文本
tagSize|Size|设置标签大小
colorScheme|ColorScheme|设置标签颜色
isOpaque|Bool|设置标签透明度

#### iconText()
根据传入的参数生成一个 iconText 类型的配置
参数名 | 类型 | 说明
---|---|---
icon|UIImage|设置标签 icon
text|String|设置标签文本
tagSize|Size|设置标签大小
colorScheme|ColorScheme|设置标签颜色
isOpaque|Bool|设置标签透明度
