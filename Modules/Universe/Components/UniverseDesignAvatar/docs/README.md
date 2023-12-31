# 头像 Avatar

## 简介

头像使用圆形或方形头像来代表个人、群体、公司及产品，支持以图片、图标或字符形式展示。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignAvatar'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignAvatar
```

## 圆形头像

::: showcase collapse=false
<SiteImage
    width = "50"
    height = "50"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/avatar/ud_avatar_round.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/avatar/ud_avatar_round_dm.png"
    />

```swift
let config = UDAvatarUIConfig(style: .circle)
let avatar = UDAvatar(config: config)
```

:::

## 矩形头像

::: showcase collapse=false
<SiteImage
    width = "48"
    height = "48"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/avatar/ud_avatar_rectangular.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/avatar/ud_avatar_rectangular_dm.png"
    />

```swift
let config = UDAvatarUIConfig(style: .square)
let avatar = UDAvatar(config: config)
```

:::

## 设置头像描边

因为`UDAvatar`继承自 UIImageView，使用 UIImageView 赋值边框的方法即可。

::: showcase collapse=false
<SiteImage
    width = "48"
    height = "48"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/avatar/ud_avatar_round_border.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/65eh7ulojvhonuhd/es-design/android/avatar/ud_avatar_round_border_dm.png"
    />

```swift
let config = UDAvatarUIConfig(style: .circle)
var config = UDAvatarUIConfig(style: .circle)
var avatar = UDAvatar(config: config)
avatar.layer.ud.setBorderColor(UIColor.ud.B100)
avatar.layer.borderWidth = 3
```

:::
你同样可以使用 [UDTheme](https://bits.bytedance.net/bytebus/components/components/detail/17124?returnUrl=https%3A%2F%2Fbits.bytedance.net%2Fbytebus%2Fcomponents%2Fcomponents%3Fcomponent_type_id%3D0%26displayType%3Dcard%26framework_id%3D1%26original_id%3D0%26page%3D1%26page_size%3D18%26search_text%3DuniversedesignTheme%26sort%3Dlike) 中提供的实现 CGColor 适配 DM 的方法`avatar.layer.ud.setBorderColor()`来实现边框颜色。

若你仍想让边框使用 CGColor，则使用正常的设置 UIView 的边框颜色方法`avatar.layer.borderColor = UIColor.blue.cgColor`即可。

## 更新头像

组件支持通过设置 image 或者使用[`updateAvatar`](#updateavatar)更新头像，如果没有头像则会使用 config 中的占位图。

```swift
let config = UDAvatarUIConfig(style = .square)

let avatar = UDAvatar(config: config)

avatar.updateAvatar(UIImage())
```

## 自定义头像效果

组件支持在初始化时，通过[`UDAvatarUIConfig`](#udavataruiconfig)传入占位图、背景颜色、圆角风格、ContentMode 等。同时，`UDAvatar`继承自`UIImageView`,`UIImageView`的相关配置属性也可调用。

```swift
var config = UDAvatarUIConfig(placeholder: UDIcon.imageOutlined,
                              backgroundColor: UIColor.red,
                              style: .square,
                              contentMode: .center)
var avatar = UDAvatar(config: config)
```

## API 及配置列表

### UDAvatarUIConfig

组件初始化时的必传参数，用来配置组件外观。

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
placeholder| 未设置头像时的占位图 | UIImage | nil
backgroundColor| 箭头像背景颜色 | UIColor | nil
style| 头像圆角风格 | UDAvatarUIConfig.Style | .circle
contentMode| contentMode | UIView.ContentMode | .scaleAspectFill

### UDAvatar

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
config| UDAvatar UI 配置 | [UDAvatarUIConfig](#udavataruiconfig) | UDAvatarUIConfig()

### UDAvatar 接口

#### updateAvatar

<SiteTableHighlight columns="4" type="1" />

参数名 | 说明 | 类型 | 默认值
--- | --- | --- | ---
image| 更新的图片 | UIImage | nil
