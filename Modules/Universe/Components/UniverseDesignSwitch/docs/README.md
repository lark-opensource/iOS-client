# 开关 Switch

## 简介

开关组件是数字化开关。它们提示用户在两个相互排斥的选项之间进行选择，并且总是有一个是默认值。

## 安装

### 使用 CocoaPods 安装

添加至你的 `Podfile`:

```bash
pod 'UniverseDesignSwitch'
```

接着，执行以下命令：

```bash
pod install
```

### 引入组件

```swift
import UniverseDesignSwitch
```

## 普通的开关

::: showcase collapse=false
<SiteImage
    width = "336"
    height = "28"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDSwitch/switch_all_light.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDSwitch/switch_all_dark.png"
/>

```swift
var udSwitch = UDSwitch()
udSwitch.setOn(true, animated: true)  // 设置是否开启
udSwitch.isEnabled = false            // 设置是否可用
```

:::

## 加载态的开关

::: showcase collapse=false
<SiteImage
    width = "114"
    height = "28"
    src = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDSwitch/switch_loading.png"
    darkSrc = "https://lf3-static.bytednsdoc.com/obj/eden-cn/5161eh7pldnuvk/UDCResource/UDSwitch/switch_loading_dark.png"
/>

```swift
var udSwitch = UDSwitch()
udSwitch.setOn(true, animated: true)    // 设置是否开启
udSwitch.behaviourType = .waitCallback  // 设置当前行为为等待回调
```

:::

### 自定义开关

组件提供了[`UDSwitchConfig`](#udswitchuiconfig)作为 UI 配置项，其主要包括 Switch 在开、关状态以及正常、禁用、加载组合下，轨道、滑块的颜色属性。

组件会根据 config 中的配置进行布局展示相关元素。

```swift
let onNormalTheme = UDSwitchUIConfig.ThemeColor(tintColor: UIColor.green, thumbColor: UIColor.white)
let onDisableTheme = UDSwitchUIConfig.ThemeColor(tintColor: UIColor.ud.B200, thumbColor: UIColor.ud.N00)
let onLoadingTheme = UDSwitchUIConfig.ThemeColor(tintColor: UIColor.green, thumbColor: UIColor.ud.N00, loadingColor: UIColor.green)
let customUIConfig1 = UDSwitchUIConfig(onNormalTheme: onNormalTheme,
                                       onDisableTheme: onDisableTheme,
                                       onLoadingTheme: onLoadingTheme)
let udSwitch = UDSwitch(config: customUIConfig1)
```

## API 及配置列表

### UDSwitchUIConfig

参数名 | 说明 | 类型 | 默认值
---|---|---|---
onNormalTheme|Switch 打开正常状态 |ThemeColor|ThemeColor(tintColor: UIColor.ud.B500, thumbColor: UIColor.ud.N00, loadingColor: UIColor.ud.N00)
onDisableTheme|Switch 打开禁用状态 |ThemeColor|ThemeColor(tintColor: UIColor.ud.B200, thumbColor: UIColor.ud.N00, loadingColor: UIColor.ud.N00)
onLoadingTheme|Switch 打开加载状态 |ThemeColor|ThemeColor(tintColor: UIColor.ud.B200, thumbColor: UIColor.ud.N00, loadingColor: UIColor.ud.B200)
offNormalTheme|Switch 关闭正常状态 |ThemeColor|ThemeColor(tintColor: UIColor.ud.N400, thumbColor: UIColor.ud.N00, loadingColor: UIColor.ud.N00)
offDisableTheme|Switch 关闭正常状态 |ThemeColor|ThemeColor(tintColor: UIColor.ud.N300, thumbColor: UIColor.ud.N50, loadingColor: UIColor.ud.N50)
offLoadingTheme|Switch 关闭加载状态 |ThemeColor|ThemeColor(tintColor: UIColor.ud.N300, thumbColor: UIColor.ud.N50, loadingColor: UIColor.ud.N300)

### SwitchBehaviourType 枚举

<SiteTableHighlight columns="2" type="3" />

属性 | 说明
---|---
normal| 开关立即生效
waitCallback| 不立即生效，需在`valueWillChanged`执行操作后，再主动调用`setOn`改变开关状态

### SwitchState 枚举

<SiteTableHighlight columns="2" type="3" />

属性 | 说明
---|---
normal| 正常状态
disabled| 禁用状态
loading| 加载状态

### UDSwitch 接口

#### uiConfig

默认是 UDSwitchUIConfig.defaultConfig，初始化时可配置。

```swift
udSwitch.uiConfig = customUIConfig1
```

#### behaviourType

设置开关是否可用，默认是`normal`，初始化时可配置。

```swift
udSwitch.behaviourType = .waitCallback
```

#### isEnabled

设置开关是否可用，默认`true`。

```swift
udSwitch.isEnabled = false
```

#### valueWillChanged

监听开关状态即将改变。

```swift
udSwitch.valueWillChanged = { _ in
}
```

#### valueChanged

监听开关状态已改变。

```swift
udSwitch.valueChanged = { _ in
}
```
